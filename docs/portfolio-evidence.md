# Portfolio Evidence

This page lists only what can be demonstrated **today**. Anything not yet executed is listed separately as planned. **No AWS deployment has occurred.**

## VERIFIED

| Evidence | Where to see it | How it was verified |
|---|---|---|
| TypeScript API (`/`, `/health`, `/ready`) | `app/src/app.ts`, `app/src/index.ts` | Run locally and in Docker; endpoints return structured JSON (`service`, `status`, `environment`, `version`, `timestamp`). |
| Health / readiness semantics | `app/src/app.ts`, `app/test/app.test.ts` | Tests assert `/ready` returns `503` when not ready; container shows `not ready → exit 0` on `SIGTERM`. |
| Automated tests | `app/test/app.test.ts` | `npm test`: 4 tests, all passing (Node built-in test runner). |
| Docker container | `app/Dockerfile` | Multi-stage build succeeds; Docker `HEALTHCHECK` reports `healthy`. |
| Non-root container runtime | `app/Dockerfile` | `docker exec … id` → `uid=1000(node)`. |
| Hardened runtime compatibility | — | Container runs healthy with `--read-only --cap-drop ALL` (matches the planned ECS task settings). |
| Graceful shutdown | `app/src/index.ts` | `docker stop` → logs `shutting down`, exit code `0`. |
| Terraform configuration | `infra/terraform/` | `terraform fmt -check`, `terraform init -backend=false`, `terraform validate` all pass. **Never applied.** |
| Zero-spend gate in Terraform | `infra/terraform/variables.tf` | Mechanism verified in an isolated scratch config: `validate` passes, `plan` blocked by default. |
| GitHub repository | `github.com/paulobiao/biaotech-cloud-lab` | Public source of record. |
| Successful GitHub Actions CI | `.github/workflows/ci.yml`, repository Actions tab | CI green: typecheck, tests, build, Docker build + container smoke test, Terraform fmt/validate — with no AWS credentials. |
| Cloud architecture design | `docs/architecture.md`, `infra/terraform/*.tf` | Full VPC / ECR / IAM / OIDC / ECS / ALB / CloudWatch design expressed as validated Terraform. |
| Cost-aware infrastructure design | `docs/cost-strategy.md`, `docs/aws-zero-spend-guardrails.md` | Every planned resource classified by cost behaviour; NAT gateway excluded; billable components identified and gated. |
| Security design | `docs/security.md`, `github_oidc.tf`, `iam.tf` | OIDC trust pinned to repo + branch; least-privilege roles; no stored keys. Design only, **not tested against AWS**. |

## PLANNED (no evidence yet)

| Claim | Requires | Phase |
|---|---|---|
| Infrastructure deployed to AWS | Approved, time-boxed `terraform apply` | 2–4 |
| Image published to ECR | ECR created + push | 3 |
| API reachable via ALB | ALB + ECS running | 4 |
| Keyless GitHub → AWS deploys via OIDC | OIDC provider + role created, deploy workflow run | 5 |
| CloudWatch logs and alarms working | Deployed workload, induced alarm | 6 |
| Self-healing, rollback, least-privilege verified | Resilience/security tests on deployed stack | 7 |
| Clean `terraform destroy` with no leftover resources | Deployed stack | 4–8 |

## Rules for adding evidence

- Only real output from real sessions: CLI output, console screenshots, CI run links.
- No mock screenshots, no edited output, no "should work" claims.
- Each item moves from PLANNED to VERIFIED only with a pointer to the artefact that proves it.
