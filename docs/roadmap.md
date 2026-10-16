# Roadmap

Each phase ends with something verifiable. A phase is marked done only when its exit criteria have actually been checked.

| Phase | Status |
|---|---|
| 1 — Local foundation | ✅ Done (local only) |
| 2 — Terraform AWS foundation | Not started |
| 3 — ECR + container publishing | Not started |
| 4 — ECS Fargate deployment | Not started |
| 5 — GitHub OIDC + CI/CD | Not started |
| 6 — Observability | Not started |
| 7 — Resilience / security validation | Not started |
| 8 — Portfolio evidence | Not started |

## Phase 1 — Local foundation

- TypeScript API with `/`, `/health`, `/ready`, structured JSON logs, graceful shutdown.
- Unit tests with the Node built-in test runner.
- Multi-stage, non-root Dockerfile with `HEALTHCHECK`.
- Terraform root module skeleton (versions, provider, variables, outputs).
- CI: typecheck, test, build, Docker build + smoke test, `terraform fmt/validate`. No AWS credentials.

**Exit:** all of the above pass locally and in CI.

## Phase 2 — Terraform AWS foundation

- Bootstrap remote state (S3, versioned, encrypted, native locking).
- AWS Budgets alert.
- `network.tf`: VPC, two public subnets in two AZs, internet gateway, route table, ALB and task security groups. No NAT gateway.

**Exit:** `terraform plan` is clean and reviewed; `apply` + `destroy` cycle succeeds.

## Phase 3 — ECR + container publishing

- `ecr.tf`: repository with scan-on-push, immutable tags, lifecycle policy.
- Push the image manually once (human SSO session) to prove the path.

**Exit:** image in ECR, scan results reviewed.

## Phase 4 — ECS Fargate deployment

- `iam.tf`: task execution role and (empty) task role.
- `ecs.tf`: cluster, task definition (0.25 vCPU / 0.5 GB, `awslogs`, container health check on `/health`), service with `desired_count = 1`.
- `alb.tf`: ALB, target group health-checking `/ready`, HTTP listener.

**Exit:** `curl http://<alb-dns>/` returns the service JSON; a redeploy completes with no failed requests.

## Phase 5 — GitHub OIDC + CI/CD

- `github_oidc.tf`: OIDC provider and deploy role scoped to this repo + `main` (or a GitHub environment).
- Deploy workflow: build → push to ECR (tagged with commit SHA) → render task definition → update service → wait for stability.

**Exit:** a merge to `main` deploys with no AWS keys stored anywhere in GitHub.

## Phase 6 — Observability

- Log group with retention; CloudWatch Logs Insights queries for request rate, errors, latency.
- Alarms: ALB 5xx, unhealthy host count, ECS CPU/memory high; SNS email notification.
- Optional small dashboard.

**Exit:** alarms observed transitioning to `ALARM` and back under induced conditions.

## Phase 7 — Resilience / security validation

- Kill a task and observe ECS replacing it with no manual action.
- Deploy a broken image and observe the deployment circuit breaker roll back.
- Review IAM policies against least privilege; confirm tasks are unreachable except via the ALB.
- Optional: HTTPS with ACM + Route 53.

**Exit:** each scenario documented with real output.

## Phase 8 — Portfolio evidence

- Case study: problem, architecture, decisions and trade-offs, cost notes, what failed and how it was fixed.
- Evidence captured during real sessions only (CLI output, screenshots, graphs) — nothing fabricated.
- Final `terraform destroy` confirmed.
