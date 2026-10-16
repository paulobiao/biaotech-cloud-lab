# COST: an ALB bills for every hour it exists, even with zero traffic.
# It is intentionally NOT provisioned in the current phase.

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb.id]

  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "api" {
  name                 = "${local.name_prefix}-api"
  port                 = var.container_port
  protocol             = "HTTP"
  target_type          = "ip" # required for awsvpc / Fargate
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 30

  # Readiness, not liveness: a draining task returns 503 here and stops receiving traffic.
  health_check {
    path                = "/ready"
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# HTTP only: there is no domain/certificate yet. HTTPS (ACM + Route 53) is the upgrade path.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}
