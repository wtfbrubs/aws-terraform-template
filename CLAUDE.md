# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

AWS infrastructure template managed with Terraform, targeting production and sandbox environments in `sa-east-1`. Two CI/CD pipelines are available: GitLab CI (`.gitlab-ci.yml`) and GitHub Actions (`.github/workflows/terraform.yml`), both with Infracost cost estimation.

## Common commands

```bash
# Validate syntax without hitting AWS or the S3 backend
terraform init -backend=false
terraform validate

# Format check (run before committing)
terraform fmt -check -recursive
terraform fmt -recursive   # auto-fix

# Lint with tflint (requires tflint + AWS ruleset installed)
tflint --init --config "$(pwd)/.tflint.hcl"
tflint --recursive --config "$(pwd)/.tflint.hcl"

# Full workflow (requires AWS credentials and the S3 state bucket to exist)
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Cost estimation (requires INFRACOST_API_KEY)
terraform show -json tfplan > plan.json
infracost breakdown --path plan.json --format table

# Pre-commit hooks (one-time setup)
pip install pre-commit
pre-commit install
pre-commit run --all-files   # run manually on all files
```

## Architecture

The root module (`main.tf`) only passes variables into `./modules`. All resource orchestration lives in `modules/main.tf`, which instantiates each submodule. `modules/variables.tf` holds the shared globals (`alias`, `vpc_name`, `aws_region`, `domain`).

The `modules/` directory is a **single flat namespace** — the provider block and all submodule calls sit in `modules/main.tf`, not in the root. Each subdirectory under `modules/` is a self-contained submodule with its own `main.tf`, `variables.tf`, and `outputs.tf`.

Network topology: public subnets host EC2, ALB, and NAT Gateway; private subnets host ECS Fargate services and RDS. The VPC CIDR defaults to `100.121.0.0/16`.

EKS is present (`modules/eks/`) but **commented out** in `modules/main.tf` — uncomment to enable it.

## Customizing for a new environment

Before `terraform init`, update these files:

| File | What to change |
|---|---|
| `modules/variables.tf` | `alias`, `vpc_name` defaults |
| `backend.tf` | `bucket` name (must exist before `terraform init`) |
| `modules/cloudtrail/main.tf` | Replace `CLIENTE` in 3 places |
| `modules/main.tf` | Comment out modules not needed |

Copy `modules/terraform.tfvars.example` to `terraform.tfvars` (gitignored) and fill in `alias`, `aws_region`, `vpc_name`, `domain`, and `ec2_public_key`.

## Security invariants

- **Secrets**: never in `container_environment`. Use `container_secrets` with Secrets Manager ARNs — the ECS execution role already has `secretsmanager:GetSecretValue`, `ssm:GetParameters`, and `kms:Decrypt`.
- **RDS**: `deletion_protection = true` and `manage_master_user_password = true` — the password never appears in state or plan output. Disabling `deletion_protection` requires a targeted apply before destroy.
- **SSH keys**: passed via `ec2_public_key` variable from `terraform.tfvars` (gitignored), never hardcoded.
- **CloudTrail bucket**: no `force_destroy` — manual object removal required before `terraform destroy`.
- **KMS**: each major resource (EC2 volumes, RDS, S3, EFS) uses a dedicated KMS key.
- **IRSA**: EKS OIDC provider is configured automatically; use IAM Roles for Service Accounts instead of instance profiles in pods.

## State management

State is stored in S3 (`backend.tf`). DynamoDB locking is **not yet configured** — without it, concurrent applies can corrupt the state file. Add `dynamodb_table` to `backend.tf` before running this in a shared team environment.

The `.terraform.lock.hcl` is committed intentionally to pin provider versions across environments. Do not delete it.

## CI/CD pipeline flow

**GitHub Actions** (`.github/workflows/terraform.yml`):
1. `validate` — runs `terraform init -backend=false && validate` with no AWS credentials; fails fast on syntax errors.
2. `plan` — requires `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `INFRACOST_API_KEY` secrets; uploads `tfplan` as a 1-day artifact.
3. `apply` — only runs on `main`/`master`, requires a GitHub Environment named `production` with required reviewers.

**GitLab CI** (`.gitlab-ci.yml`): uses a private OCI image (`gru.ocir.io/...`) that bundles Terraform + AWS CLI + Infracost. The `apply` stage is `when: manual` on `master` only.

## Provider and Terraform version constraints

- Terraform `>= 1.9`
- AWS provider `~> 5.0`
- TLS provider `~> 4.0` (needed by the EKS OIDC thumbprint lookup)

All resources inherit `ManagedBy = "terraform"` and `Alias = var.alias` tags via `default_tags` on the provider in `modules/main.tf`.
