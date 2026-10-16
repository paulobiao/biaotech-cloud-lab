# Cost Strategy

> No exact prices are quoted here: AWS pricing varies by region and changes over time. Check the [AWS Pricing Calculator](https://calculator.aws/) for the chosen region before deploying.

## Principle

This is a lab, not a service. It exists to be **deployed, validated, documented, and destroyed**. The biggest saving is simply not leaving it running.

## Recurring cost drivers

| Resource | How it bills | Risk | Mitigation |
|---|---|---|---|
| **Application Load Balancer** | Per hour it exists **plus** load-balancer capacity units, even with zero traffic. | **Highest fixed cost.** Billed from creation to deletion regardless of use. | Destroy when not actively testing. One ALB only. |
| **ECS Fargate** | Per second of vCPU and memory while tasks run. | Scales with task size × count × hours. | Smallest viable size (0.25 vCPU / 0.5 GB), `desired_count = 1`, scale to 0 or destroy between sessions. Consider ARM64 (Graviton) tasks, which are priced lower. |
| **NAT Gateway** | Per hour **plus** per GB processed. | Would rival or exceed the ALB as a fixed cost. | **Not used.** Tasks run in public subnets with inbound restricted to the ALB (see [security.md](security.md)). |
| **Public IPv4 addresses** | AWS bills per hour for each public IPv4 address. | ALB nodes and each task with a public IP count. | Small number of addresses; destroyed with the lab. |
| **CloudWatch Logs** | Per GB ingested and per GB stored. | Unbounded if retention is "never expire". | Short retention (e.g. 7 days) set in Terraform; one compact JSON line per request. |
| **CloudWatch Alarms / Metrics** | Per alarm per month; custom metrics billed separately. | Low, but alarms persist if forgotten. | A handful of alarms on built-in ALB/ECS metrics; no custom metrics. |
| **ECR** | Per GB-month stored, data transfer out of region. | Grows with every pushed image. | Lifecycle policy keeping only the last few images. |
| **S3 (Terraform state)** | Per GB-month, requests. | Negligible (KB of state). | Kept between lab sessions; only bootstrap resource that persists. |
| **Data transfer** | Outbound to the internet. | Negligible for a test API. | — |

Not used, deliberately: EKS (control-plane fee), RDS, NAT gateway, VPC interface endpoints (hourly per AZ), Route 53 hosted zone (until HTTPS is added).

## Lab lifecycle

```bash
cd infra/terraform
terraform plan -out=lab.tfplan     # review what will be created
terraform apply lab.tfplan         # deploy
# ... validate endpoints, capture evidence, run alarm/failure tests ...
terraform destroy                  # remove everything billable
```

Rules for every session:

1. Decide what will be validated **before** applying.
2. Capture real evidence (CLI output, console screenshots, CloudWatch graphs) during the session.
3. Run `terraform destroy` at the end of the session — not "later".
4. Confirm in the console (EC2 → Load Balancers, ECS → Clusters, VPC → NAT Gateways) that nothing is left.

## Guardrails to set before the first apply (Phase 2)

- **AWS Budgets** alert at a low monthly threshold with email notification.
- **Cost allocation tags**: every resource gets `Project`, `Environment`, `ManagedBy` via provider `default_tags` (already configured), so lab spend is filterable in Cost Explorer.
- Optional: a scheduled reminder to check for leftover resources.
