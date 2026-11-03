# Interview Notes: AWS EKS Terraform Platform

Personal lab project. Describe it as something you built on your own to show the full workflow end to end, not as Publix work.

## 30-second version

"I built a lab platform that creates a hardened Amazon EKS cluster from Terraform and deploys a sample service with Helm. It runs through GitHub Actions using OIDC, so there are no stored AWS keys. Every pull request is checked by terraform validate, TFLint, Checkov, and helm lint. One workflow run builds everything and runs a health check; another tears it down."

## Questions you are likely to get

**Why OIDC instead of access keys?**
Access keys are long-lived and can leak from CI. With OIDC, GitHub issues a short-lived token per run and AWS exchanges it for temporary credentials. The trust policy only accepts this repo's main branch and the `aws` environment.

**How is the cluster secured?**
Nodes are in private subnets. The public API endpoint only accepts an allow-listed CIDR. Secrets are encrypted with KMS. Audit and authenticator logs go to CloudWatch. Nodes require IMDSv2 with a hop limit of 1 so pods can't steal node credentials. Access uses EKS access entries, not the aws-auth ConfigMap. Pods run as non-root on a read-only filesystem with all Linux capabilities dropped.

**How do you handle Terraform state?**
S3 bucket that is versioned, encrypted, blocks public access, and denies non-TLS requests. Terraform 1.10's native S3 locking prevents two runs from changing state at once, and the workflow also has a concurrency group.

**Why did you write your own VPC module but use the community EKS module?**
The VPC module shows I understand the networking: subnet carving with cidrsubnet, route tables, NAT, discovery tags for load balancers, flow logs. The EKS module is widely used and well maintained, so rebuilding it would add risk without adding value.

**What was hard?**
The hosted GitHub runner needs to reach the EKS API, but the endpoint is restricted to my IP. The runner's IP changes every run, so the workflow adds it to the allow-list for that run. In production I'd make the endpoint private and run self-hosted runners inside the VPC.

**What would you change for production?**
Scoped IAM instead of AdministratorAccess, one NAT per AZ, private-only endpoint, Argo CD for GitOps, AWS Load Balancer Controller with TLS, and separate state and accounts per environment.

**How does autoscaling work?**
The HPA scales pods on CPU using metrics-server. The managed node group scales between 1 and 3 nodes. A PodDisruptionBudget keeps at least one pod running during node upgrades, and topology spread constraints place replicas in different AZs.

## Before the interview

Build it and destroy it yourself at least once, and read every file. Be ready to open the repo and walk through `infra/main.tf`, `infra/modules/vpc/main.tf`, and `.github/workflows/deploy.yml`.
