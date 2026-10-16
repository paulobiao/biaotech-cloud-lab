resource "aws_ecs_cluster" "main" {
  name = local.name_prefix

  # Container Insights publishes extra (billable) CloudWatch metrics; off for the lab.
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  # Must match the image architecture (CI builds amd64 on ubuntu-latest).
  # ARM64 is cheaper per vCPU-hour but needs a multi-arch build.
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${aws_ecr_repository.api.repository_url}:${var.image_tag}"
      essential = true

      portMappings = [{ containerPort = var.container_port, protocol = "tcp" }]

      # Non-secret configuration only. Secrets would use the `secrets` block + SSM/Secrets Manager.
      environment = [
        { name = "PORT", value = tostring(var.container_port) },
        { name = "APP_ENV", value = var.environment },
        { name = "APP_VERSION", value = var.image_tag },
      ]

      # ECS ignores the Dockerfile HEALTHCHECK; it must be declared here.
      healthCheck = {
        command     = ["CMD-SHELL", "wget -qO- http://127.0.0.1:${var.container_port}/health >/dev/null || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      # SIGTERM -> app reports not-ready and drains (forces exit after 10s); SIGKILL after 30s.
      stopTimeout = 30

      readonlyRootFilesystem = true
      linuxParameters        = { capabilities = { drop = ["ALL"] } }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "api"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "api" {
  name            = "${local.name_prefix}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 30

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = true # no NAT gateway; inbound still restricted to the ALB SG
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]

  # CI/CD (Phase 5) registers new task definition revisions; don't revert them on apply.
  lifecycle {
    ignore_changes = [task_definition]
  }
}
