# AWS EKS Terraform Platform

[![CI](https://github.com/elmersantiago/aws-eks-terraform-platform/actions/workflows/ci.yml/badge.svg)](https://github.com/elmersantiago/aws-eks-terraform-platform/actions/workflows/ci.yml)

A secure, repeatable Amazon EKS platform built with Terraform, deployed through GitHub Actions with OIDC (no stored AWS keys), and running a sample service packaged as a Helm chart.

## Problem

Teams that stand up Kubernetes on AWS by hand end up with clusters that drift, public worker nodes, long-lived CI credentials, and no audit trail. Every rebuild is slightly different, and nobody can say for sure what is running.

## Approach

- **Network as a reusable module.** A custom VPC module creates public subnets for load balancers, private subnets for nodes, NAT for outbound traffic, a locked-down default security group, and VPC flow logs to CloudWatch.
- **Hardened EKS.** Worker nodes run only in private subnets. The public API endpoint accepts only an allow-listed CIDR. Kubernetes secrets are encrypted with KMS, control-plane audit logs go to CloudWatch, nodes require IMDSv2, and access is managed with EKS access entries instead of the legacy `aws-auth` ConfigMap.
- **Pipeline with no stored secrets.** GitHub Actions assumes an IAM role through OIDC. The trust policy only accepts this repository's `main` branch and its `aws` environment.
- **Quality gates on every pull request.** `terraform fmt`, `terraform validate`, TFLint, a Checkov security scan (results go to the GitHub Security tab), and `helm lint`.
- **Remote state.** Terraform state is stored in a versioned, encrypted, TLS-only S3 bucket with native S3 state locking.
- **Application delivery.** A Helm chart deploys a sample service with rolling updates, readiness and liveness probes, CPU autoscaling, a PodDisruptionBudget, spread across availability zones, running as non-root on a read-only filesystem.

## Result

One workflow run creates the network, cluster, and application from code and runs a health-check smoke test. A second run tears it all down. Every change is reviewed in a pull request and validated before it is applied.

## Architecture

```
GitHub Actions ──OIDC──> IAM role ──> Terraform ──> S3 remote state
                                         │
                ┌────────────────────────┴──────────────────────────┐
                │ VPC 10.20.0.0/16 (2 AZs, flow logs)               │
                │  Public subnets:  NAT gateway, load balancers     │
                │  Private subnets: EKS managed node group (AL2023) │
                │    └─ web-app (Helm chart), metrics-server        │
                └───────────────────────────────────────────────────┘
EKS control plane: KMS secrets encryption, audit logs, CIDR-restricted API
```

## Repository layout

| Path | Purpose |
|---|---|
| `bootstrap/` | One-time setup: state bucket and GitHub OIDC deploy role |
| `infra/` | Root module: VPC module plus EKS cluster and node group |
| `infra/modules/vpc/` | Reusable VPC module |
| `charts/web-app/` | Helm chart for the sample service |
| `.github/workflows/ci.yml` | Pull request checks: fmt, validate, TFLint, Checkov, Helm lint |
| `.github/workflows/deploy.yml` | Manual plan, apply (infra and app), or destroy |

## Cost warning

This creates billable AWS resources: the EKS control plane, a NAT gateway, and two Spot nodes come to roughly $4–5 per day in us-east-1. **Run destroy when you are done.** Set an AWS Budget alert before you start.

## Deploy it

Prerequisites: an AWS account, the AWS CLI, Terraform 1.10 or later, kubectl, and Helm.

**1. Bootstrap** (once, from your computer with your own AWS credentials):

```bash
cd bootstrap
terraform init
terraform apply
```

Note the `state_bucket` and `github_deploy_role_arn` outputs.

**2. Configure the repository.** Under Settings > Environments, create an environment named `aws`. Under Settings > Secrets and variables > Actions > Variables, add:

| Variable | Value |
|---|---|
| `AWS_ROLE_ARN` | `github_deploy_role_arn` output |
| `TF_STATE_BUCKET` | `state_bucket` output |
| `API_ALLOWED_CIDR` | your public IP as /32 (`curl -s https://checkip.amazonaws.com`) |
| `ADMIN_PRINCIPAL_ARNS` | optional, for example `["arn:aws:iam::123456789012:user/you"]` |

**3. Deploy.** Under Actions > Deploy > Run workflow, choose `plan` to preview, then `apply`.

**4. Connect from your computer:**

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-platform-dev
kubectl -n web get pods,svc,hpa
kubectl -n web port-forward svc/web-app 8080:80
curl http://localhost:8080
```

**5. Tear down.** Run the Deploy workflow with `destroy`. To remove the bootstrap resources too, empty the state bucket and run `terraform destroy` in `bootstrap/`.

## Lab trade-offs (and what production would change)

| Lab choice | Production approach |
|---|---|
| Deploy role uses `AdministratorAccess` | Scoped IAM policy plus a permissions boundary |
| Public API endpoint, CIDR-restricted; the hosted runner's IP is added for each run | Private-only endpoint, self-hosted runners inside the VPC |
| One NAT gateway | One NAT gateway per AZ |
| Spot nodes | On-Demand or mixed capacity for critical workloads |
| Helm deploy from the pipeline | GitOps with Argo CD watching the chart |
| ClusterIP service | AWS Load Balancer Controller with an ALB and TLS from ACM |

## Tools

Terraform, AWS (VPC, EKS, IAM, KMS, S3, CloudWatch), Kubernetes, Helm, GitHub Actions, OIDC, TFLint, Checkov.
