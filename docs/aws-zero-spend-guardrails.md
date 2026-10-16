# AWS Zero-Spend Guardrails

> **Policy in force: AWS spend must remain $0.** No AWS resource exists for this project. `terraform apply` is prohibited at the current stage.

## 1. Why `terraform apply` is prohibited now

The Terraform code in `infra/terraform/` is a complete **design** of the future deployment: VPC, ECR, IAM/OIDC, ECS Fargate, ALB and CloudWatch. Applying it as-is would immediately create resources that bill per hour (ALB, a running Fargate task, public IPv4 addresses, CloudWatch alarms). The current phase is design and validation only, so there is no reason to spend anything.

### Enforced in code, not just in docs

`variables.tf` declares:

```hcl
variable "acknowledge_aws_charges" {
  type    = bool
  default = false
  validation {
    condition     = var.acknowledge_aws_charges
    error_message = "Blocked by zero-spend policy: ..."
  }
}
```

Effect:

| Command | Result |
|---|---|
| `terraform fmt`, `terraform init -backend=false`, `terraform validate` | Work normally (used by CI). |
| `terraform plan` / `terraform apply` with defaults | **Fail** with "Blocked by zero-spend policy" before any resource is planned. |
| `terraform plan -var acknowledge_aws_charges=true` | Proceeds. This is a deliberate, visible, per-command decision. |

The value is intentionally **not** placed in `terraform.tfvars.example`, so it cannot be enabled by copying a file.

This gate was verified in an isolated scratch configuration (no AWS provider): `validate` passed, `plan` with the default failed with the validation error, `plan` with `=true` proceeded. `terraform plan` has **not** been run against the real configuration, because that would contact AWS using local credentials.

## 2. Resources that may incur charges

Full classification: [cost-strategy.md](cost-strategy.md). Summary of what bills as soon as it exists:

- Application Load Balancer (hourly + capacity units)
- ECS Fargate tasks (per-second vCPU + memory while running)
- Public IPv4 addresses (ALB nodes and tasks)
- CloudWatch metric alarms (per alarm per month)

Usage-dependent: ECR storage, CloudWatch Logs ingestion/storage, data transfer out.

## 3. Free Tier is not assumed

No part of this design relies on Free Tier. Eligibility depends on the specific account and current AWS terms, and must be verified independently in the Billing console before any deployment. Resources are never created "because they might be free".

## 4. Budgets and alerts do not guarantee zero spend

AWS Budgets and billing alarms are **notifications, not limits**:

- Billing data is delayed, often by hours, so an alert arrives after charges have accrued.
- A budget alert does not stop, scale down or delete anything.
- Thresholds are evaluated against estimated charges and can be crossed between evaluations.

They are useful as a safety net for a future deployment, but the only way to guarantee $0 is to **not create billable resources**, which is the current policy. (Budgets themselves are not created in this phase either.)

## 5. Inspecting `terraform plan` before any future deployment

Only after deployment is explicitly approved:

```bash
cd infra/terraform
terraform init                                     # with the agreed remote backend
terraform plan -var acknowledge_aws_charges=true -out=lab.tfplan
terraform show -no-color lab.tfplan > lab-plan.txt # human review
terraform show -json lab.tfplan | jq -r '.resource_changes[] | "\(.change.actions|join(",")) \(.type) \(.name)"'
```

Checklist before `apply`:

- [ ] Only `create` actions on a fresh account; no unexpected `delete`/`replace`.
- [ ] **No `aws_nat_gateway`** anywhere in the plan.
- [ ] Exactly one `aws_lb`, one `aws_ecs_service` with the expected `desired_count`.
- [ ] Task size is `256` CPU / `512` MiB unless deliberately changed.
- [ ] Log group retention is set (not "never expire").
- [ ] OIDC trust `sub` is exactly `repo:paulobiao/biaotech-cloud-lab:ref:refs/heads/main`.
- [ ] No IAM policy grants `*` actions; `Resource: "*"` appears only for actions that cannot be scoped (`ecr:GetAuthorizationToken`, `ecs:RegisterTaskDefinition`, `ecs:DescribeTaskDefinition`).
- [ ] Region is the intended one.
- [ ] A time is set for `terraform destroy`.

Plan files (`*.tfplan`) are git-ignored: they can contain sensitive values.

## 6. Destroying lab resources after validation

```bash
cd infra/terraform
terraform destroy -var acknowledge_aws_charges=true
```

Then verify in the AWS console or with **read-only** CLI calls, in the deployment region:

```bash
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerName'
aws ecs list-clusters
aws ec2 describe-nat-gateways --filter Name=state,Values=available --query 'NatGateways[].NatGatewayId'
aws ec2 describe-addresses
aws ecr describe-repositories --query 'repositories[].repositoryName'
aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName'
aws logs describe-log-groups --log-group-name-prefix /ecs/biaotech
```

All should return empty for this project. Check Cost Explorer filtered by tag `Project = biaotech-cloud-lab` over the following days.

`force_delete = true` on ECR ensures the repository is removed even if it still contains images.

## 7. No NAT Gateway policy

NAT gateways bill hourly plus per GB processed and are **forbidden** in this project. The design instead places Fargate tasks in public subnets with a public IP for outbound access (ECR, CloudWatch Logs), while their security group accepts inbound traffic **only from the ALB security group**. Any plan containing `aws_nat_gateway` must be rejected.

## 8. No long-lived credentials policy

- No AWS access keys or secret keys are created for this project, for CI or for humans.
- GitHub Actions authenticates via **OIDC**: a short-lived token is exchanged for temporary STS credentials of a role whose trust is restricted to `paulobiao/biaotech-cloud-lab` on `main`.
- No AWS credentials are stored in GitHub secrets, repository files, `.env` files or Terraform variables.
- Humans should use **IAM Identity Center (SSO)** sessions. Any existing static access key in a local `~/.aws/credentials` file should be considered for replacement with SSO and, at minimum, never be used for this project's CI.
