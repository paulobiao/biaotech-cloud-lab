# Cost Strategy

> **Current policy: AWS spend must remain $0.** No AWS resource has been created. The Terraform code describes a future deployment and is blocked from planning/applying by default (see [aws-zero-spend-guardrails.md](aws-zero-spend-guardrails.md)).
>
> No prices are quoted here. AWS pricing varies by region and changes over time; use the [AWS Pricing Calculator](https://calculator.aws/) and the official pricing pages for the chosen region at the time of any deployment.

## Free Tier is not assumed

This project does **not** assume any AWS Free Tier eligibility. Free Tier terms differ by account age, account type and service, have changed over time, and may not apply to this account at all. Any future deployment must be costed as if every resource is billed at the standard rate, and Free Tier eligibility, if relevant, must be **verified independently** in the AWS Billing console for this specific account before deploying. Nothing in this repository is designed around "it should be free".

## Classification of planned resources

Categories:

- **No direct service charge** — AWS does not bill for the resource object itself. It can still enable or be attached to billable things.
- **Potentially billable** — may or may not bill depending on account status, configuration or thresholds; treat as billable.
- **Recurring cost risk** — bills per hour (or month) for as long as it exists, **even with zero traffic**.
- **Usage-dependent cost** — bills proportionally to running time, data volume, storage or requests.

| Terraform resource (file) | Category | Notes |
|---|---|---|
| VPC, subnets, route tables, route table associations (`network.tf`) | No direct service charge | Containers for networking; no hourly fee for the objects themselves. |
| Internet gateway (`network.tf`) | No direct service charge | The gateway itself is not billed; **data transfer** through it is usage-dependent. |
| Security groups, default SG lockdown (`network.tf`) | No direct service charge | — |
| **Public IPv4 addresses** (ALB nodes, each Fargate task with `assign_public_ip`) | **Recurring cost risk** | AWS bills public IPv4 addresses per hour while allocated. Created implicitly by the ALB and tasks. |
| ECR repository + lifecycle policy (`ecr.tf`) | Usage-dependent cost | Billed for image storage (GB-month) and some data transfer. An empty repository stores nothing; lifecycle policy caps growth. Image scanning on push: verify current terms. |
| IAM roles, policies, OIDC provider (`iam.tf`, `github_oidc.tf`) | No direct service charge | IAM is not billed. Security impact, not cost impact. |
| ECS cluster (`ecs.tf`) | No direct service charge | The cluster object is free; Container Insights (extra metrics) is deliberately disabled. |
| ECS task definition (`ecs.tf`) | No direct service charge | A definition, not a running workload. |
| **ECS Fargate service** (`ecs.tf`) | **Recurring cost risk** + usage-dependent | Each running task bills per second for vCPU and memory. With `desired_count = 1` that is continuous, 24/7, until the service is scaled to 0 or destroyed. |
| **Application Load Balancer** (`alb.tf`) | **Recurring cost risk** + usage-dependent | Hourly charge from creation to deletion regardless of traffic, plus capacity units. **Largest fixed cost in the design.** |
| Target group, listener (`alb.tf`) | No direct service charge | Billed as part of the ALB. |
| CloudWatch log group (`cloudwatch.tf`) | Usage-dependent cost | Billed per GB ingested and per GB-month stored. Retention fixed at 7 days. |
| **CloudWatch metric alarms** ×4 (`cloudwatch.tf`) | **Recurring cost risk** (small) | Alarms are billed per alarm per month while they exist. Built-in metrics only; no custom metrics. |
| Data transfer out to the internet | Usage-dependent cost | Negligible for a test API, but not zero. |
| Terraform remote state (S3) — not yet designed into code | Potentially billable | Storage and requests for a few KB of state; verify before creating. |
| AWS Budgets | Potentially billable | Budgets may be free up to a limit; verify current terms before creating one. |

## Deliberately excluded from the design

| Component | Why excluded |
|---|---|
| **NAT Gateway** | Hourly charge plus per-GB processing. Would be one of the largest costs of the lab. Replaced by public-subnet tasks with ALB-only inbound (see [security.md](security.md)). |
| VPC interface endpoints | Hourly per endpoint per AZ. Only needed for private-subnet designs. |
| EKS | Control-plane fee per cluster; out of scope by design. |
| Container Insights | Publishes additional billable CloudWatch metrics. |
| VPC Flow Logs | Billable log ingestion. |
| Route 53 hosted zone, ACM + HTTPS | Hosted zone billed monthly; deferred until a domain is actually needed. |
| Custom CloudWatch metrics / dashboards | Billed per metric / dashboard. |
| Multiple tasks, autoscaling | Multiplies Fargate cost; one task is enough to demonstrate the architecture. |

## Components that must NOT be provisioned yet

At the current stage **nothing is provisioned**. Even when deployment is eventually approved, these are the components that start billing immediately and continuously, and therefore require a planned, time-boxed session:

1. **Application Load Balancer** — hourly from creation, traffic or not.
2. **ECS Fargate service with `desired_count >= 1`** — continuous compute charges.
3. **Public IPv4 addresses** — created by the two items above.
4. **CloudWatch alarms** — monthly per alarm while they exist.

Lower-risk, usage-dependent items (ECR with images, CloudWatch Logs ingestion) still cost money and are also not provisioned.

## Lab lifecycle (future, after explicit approval)

The intended operating model is **deploy → validate → capture evidence → destroy**, within a single session. The step-by-step procedure, plan review checklist and post-destroy verification are in [aws-zero-spend-guardrails.md](aws-zero-spend-guardrails.md).

Cost levers available in the code:

- `desired_count = 0` stops Fargate compute while keeping the service definition (the ALB still bills).
- `log_retention_days` is 7 by default.
- ECR lifecycle policy keeps at most 10 images and expires untagged images after 1 day.
- `force_delete = true` on ECR so `terraform destroy` does not leave a repository behind.
- Every resource carries `Project`, `Environment`, `ManagedBy` tags (provider `default_tags`) so any spend is attributable in Cost Explorer.
