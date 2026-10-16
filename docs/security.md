# Security

> **Status:** design principles and Phase 1 controls. AWS-side controls are planned, not yet implemented or validated.

## 1. No long-lived AWS credentials

- No AWS access keys are created for this project — not for CI, not for humans.
- Humans authenticate locally through the standard AWS credential chain, preferably **IAM Identity Center (SSO)** profiles with short sessions.
- CI authenticates through **GitHub OIDC** (below).
- `providers.tf` contains no credentials; `.gitignore` excludes `.env*`, `.aws/`, `*.tfvars`, key files and Terraform state.

## 2. GitHub OIDC strategy (Phase 5)

1. Terraform creates an IAM OIDC identity provider for `token.actions.githubusercontent.com` (audience `sts.amazonaws.com`).
2. Terraform creates a deploy role whose trust policy only accepts tokens where:
   - `aud` = `sts.amazonaws.com`
   - `sub` matches this repository **and** a specific ref or GitHub environment, e.g. `repo:<owner>/biaotech-cloud-lab:ref:refs/heads/main` or `repo:<owner>/biaotech-cloud-lab:environment:lab`.
   Wildcards over the owner or repository are never used.
3. The workflow requests `id-token: write` only in the deploy job and uses `aws-actions/configure-aws-credentials` with `role-to-assume`; credentials last for the job only.
4. Pull requests from forks never get a role: CI on PRs stays credential-free.

The repository owner and name are Terraform variables, never hardcoded.

## 3. Least-privilege IAM

| Role | Assumed by | Allowed |
|---|---|---|
| Task execution role | ECS agent | Pull from *this* ECR repo, write to *this* log group. |
| Task role | The API process | Nothing (the API calls no AWS APIs). Created empty so permissions are explicit if ever needed. |
| Deploy role | GitHub Actions via OIDC | Push to this ECR repo, register task definitions, update this ECS service, `iam:PassRole` limited to the two task roles. |

Infrastructure changes (`terraform apply`) are run by a human with an SSO session during the lab; giving CI full infrastructure rights is a later, explicit decision.

## 4. Container security

- Multi-stage build: compilers and dev dependencies never reach the runtime image.
- Runtime image contains compiled JS only — the API has **zero runtime npm dependencies**.
- Runs as the unprivileged `node` user (UID 1000); app files are root-owned and not writable by it.
- `npm ci` against a committed lockfile for deterministic installs.
- ECR scan-on-push (Phase 3) for OS/package CVEs.
- Planned hardening: pin the base image by digest, `readonlyRootFilesystem` in the task definition, drop Linux capabilities.

## 5. Terraform state

State can contain resource attributes and occasionally sensitive values, so:

- State is **never committed** (`*.tfstate*` ignored) and plan files (`*.tfplan`) are ignored too.
- Phase 2 moves state to an **S3 bucket** with versioning, encryption, public access blocked, and S3 native state locking. That bucket is the one bootstrap resource and is created separately from the lab so destroying the lab does not destroy its state history.
- `.terraform.lock.hcl` **is** committed so provider versions and checksums are pinned.

## 6. Secrets strategy

- The API needs no secrets today; none are introduced.
- If one is needed later: store it in **SSM Parameter Store (SecureString)** or Secrets Manager and inject it through the task definition `secrets` block — never baked into the image, environment files in git, or Terraform variables with plaintext defaults.
- GitHub repository secrets are not needed for AWS access because OIDC replaces them.

## 7. Public / private exposure

| Resource | Exposure | Control |
|---|---|---|
| ALB | Public, HTTP :80 | Security group allows 80 from the internet; only the ALB is meant to be public. |
| Fargate tasks | Public IP (for egress, no NAT) | Security group allows the container port **only from the ALB security group**; no other inbound. |
| ECR | Private | IAM-only access. |
| CloudWatch | Private | IAM-only access. |

**Trade-off:** tasks with public IPs are a cost decision. Inbound is closed by the security group, but the stricter design is private subnets + NAT gateway or VPC endpoints (ECR API, ECR DKR, S3, CloudWatch Logs), which costs more. This is documented rather than hidden.

**HTTPS:** the lab starts on HTTP because it has no domain. Adding a Route 53 domain + ACM certificate + HTTPS listener (with HTTP→HTTPS redirect) is the upgrade path and is required before handling anything sensitive.
