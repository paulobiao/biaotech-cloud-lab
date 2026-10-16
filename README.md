# BiaoTech Cloud Lab

**Infrastructure as Code & Cloud Operations**

**Status: `AWS DESIGN — NOT DEPLOYED ($0 SPEND)`**

A real, reproducible AWS infrastructure lab built incrementally: a small containerized API designed to run on ECS Fargate behind an Application Load Balancer, defined entirely in Terraform and delivered by GitHub Actions using OIDC instead of stored AWS keys.

> **Nothing has been deployed to AWS.** The full AWS architecture exists as validated Terraform code that has never been applied, and `terraform plan`/`apply` are blocked by default by a zero-spend gate. See [docs/aws-zero-spend-guardrails.md](docs/aws-zero-spend-guardrails.md) and [docs/roadmap.md](docs/roadmap.md).

## Objective

Demonstrate, with working code rather than slides:

- Infrastructure as Code (Terraform)
- Containerization (multi-stage, non-root Docker image)
- CI/CD with GitHub Actions
- Keyless GitHub → AWS authentication (OIDC)
- Container deployment on ECS Fargate behind an ALB
- Centralized logs, metrics, alarms (CloudWatch)
- Cost-conscious design: deploy, validate, document, destroy

## Architecture overview

```
GitHub ──► GitHub Actions ──► OIDC / IAM ──► AWS (ECR, ECS)

Internet ──► Application Load Balancer ──► ECS Fargate ──► Containerized API
                                                │
                                         CloudWatch Logs / Metrics / Alarms
```

Full diagram and rationale: [docs/architecture.md](docs/architecture.md).

## Technology stack

| Layer | Choice |
|---|---|
| Application | Node.js + TypeScript, `node:http` only (no runtime dependencies) |
| Tests | Node built-in test runner (`node:test`) |
| Container | Docker, `node:24-alpine`, multi-stage |
| Infrastructure | Terraform `>= 1.9`, AWS provider `~> 6.0` |
| CI/CD | GitHub Actions |
| AWS (planned) | VPC, ALB, ECS Fargate, ECR, IAM, GitHub OIDC, CloudWatch |

## Repository structure

```
.
├── .github/workflows/ci.yml   CI: typecheck, test, build, Docker, terraform fmt/validate
├── app/
│   ├── src/app.ts             HTTP handler (/, /health, /ready)
│   ├── src/index.ts           Server entrypoint, graceful shutdown
│   ├── test/app.test.ts       Endpoint tests
│   ├── Dockerfile
│   └── package.json
├── infra/terraform/           Terraform root module (designed, validated, NEVER applied)
│   ├── versions.tf  providers.tf  variables.tf  main.tf  outputs.tf
│   ├── network.tf  ecr.tf  iam.tf  github_oidc.tf  ecs.tf  alb.tf  cloudwatch.tf
│   └── terraform.tfvars.example
└── docs/
    ├── architecture.md  security.md  cost-strategy.md  roadmap.md
    ├── aws-zero-spend-guardrails.md  portfolio-evidence.md
```

## Local development

Requires Node.js 22+.

```bash
cd app
npm ci
npm run typecheck
npm test          # builds, then runs node:test
npm start         # http://localhost:3000
```

```bash
curl localhost:3000/
curl localhost:3000/health
curl localhost:3000/ready
```

Environment variables: `PORT` (default `3000`), `APP_ENV` (default `local`), `APP_VERSION` (default `0.0.0-dev`).

Example response:

```json
{"service":"biaotech-cloud-lab","status":"healthy","environment":"local","version":"0.0.0-dev","timestamp":"…","uptimeSeconds":5}
```

## Docker usage

```bash
cd app
docker build --build-arg APP_VERSION=0.1.0 -t biaotech-cloud-lab-api:local .
docker run --rm -p 3000:3000 -e APP_ENV=docker-local biaotech-cloud-lab-api:local
docker ps          # STATUS shows (healthy) once the HEALTHCHECK passes
```

## Terraform validation

No AWS credentials are needed and nothing is applied.

```bash
cd infra/terraform
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

`terraform plan` and `terraform apply` deliberately fail unless `-var acknowledge_aws_charges=true` is passed. **Do not do that** while the zero-spend policy is in force: the configuration creates resources that bill hourly (ALB, Fargate, public IPv4, CloudWatch alarms).

## Security principles

- No long-lived AWS access keys; CI will use GitHub OIDC with a repo-scoped role.
- Least-privilege IAM: separate execution, task and deploy roles.
- No secrets, account IDs or credentials in the repository; state and `*.tfvars` are git-ignored.
- Non-root container with no runtime npm dependencies.

Details: [docs/security.md](docs/security.md). Cost analysis: [docs/cost-strategy.md](docs/cost-strategy.md).

## Roadmap

1. Local foundation ✅
2. Terraform AWS foundation ✅ design only, not applied ← **current**
3. ECR + container publishing
4. ECS Fargate deployment
5. GitHub OIDC + CI/CD
6. Observability
7. Resilience / security validation
8. Portfolio evidence

## Current status

- ✅ API, tests, Docker image (non-root, read-only-compatible) verified locally.
- ✅ GitHub Actions CI green.
- ✅ AWS architecture (VPC, ECR, IAM, GitHub OIDC, ECS Fargate, ALB, CloudWatch) written in Terraform and validated.
- ❌ No AWS resources exist. No deployment has occurred. AWS spend: $0.

Verified vs planned evidence: [docs/portfolio-evidence.md](docs/portfolio-evidence.md).
