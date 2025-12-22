#### Terraform AWS EKS Infrastructure
This repository contains Terraform configurations to provision an AWS infrastructure for an Amazon EKS (Elastic Kubernetes Service) cluster. The setup is organized into numbered directories, each representing a sequential step in the infrastructure creation process. Each directory acts as a separate Terraform root module, and you must apply them in order (e.g., using terraform init, terraform apply in each directory sequentially).
The configurations use AWS SSM Parameter Store to store and retrieve resource IDs (e.g., VPC ID, subnet IDs, security group IDs) for dependencies between modules. Outputs from earlier modules are typically stored in SSM, and later modules fetch them using data sources.
Prerequisites

Terraform installed (version ~> 1.0 or later).
AWS CLI configured with appropriate credentials and permissions.
A Route53 hosted zone (referenced via var.zone_name and var.zone_id in relevant modules).
An SSH public key at ~/.ssh/eks.pub for EKS node access (if using key pairs).
Update variables in variables.tf or provide via terraform.tfvars in each directory as needed (e.g., project_name, environment, subnet CIDRs).

#### Sequence of Creation
Follow this order to apply the Terraform configurations, as later modules depend on resources from earlier ones:

    00-vpc: VPC and networking.
    10-sg: Security groups and rules.
    20-bastion: Bastion host.
    30-db: RDS database.
    40-eks: EKS cluster and node groups.
    50-acm: ACM certificate.
    60-ingress-alb: Ingress ALB.
    70-ecr: ECR repositories.

Optional components (not included in this repo): VPN, CDN.
Resources Created and Dependencies
Below is a breakdown of resources created in each directory, along with their dependencies. Dependencies are handled via data sources fetching values from SSM Parameter Store or locals derived from previous outputs.

## 00-vpc

Resources Created:
Uses a custom VPC module (terraform-aws-vpc) to create:
VPC.
Public, private, and database subnets.
Internet Gateway, NAT Gateways.
Route tables and associations.
Optional VPC peering.


Dependencies:
None (first module).
Outputs (e.g., VPC ID, subnet IDs) are stored in SSM for later modules.


## 10-sg

Resources Created:
Security groups (using custom modules):
DB SG (for MySQL instances).
Ingress SG (for ALB).
Cluster SG (for EKS control plane).
Node SG (for EKS nodes).
Bastion SG.
VPN SG.

Security group rules:
Bastion public ingress (SSH from anywhere).
Cluster from bastion (HTTPS).
Cluster from nodes (all traffic).
Node from cluster (all traffic).
Node from VPC CIDR (all traffic).
DB from bastion and nodes (MySQL).
Ingress from public (HTTP/HTTPS).
Node from ingress (port range 30000-32768).


Dependencies:
VPC ID fetched from SSM (data.aws_ssm_parameter.vpc_id).


## 20-bastion

Resources Created:
EC2 instance (bastion host) using terraform-aws-modules/ec2-instance/aws:
t3.micro instance.
AMI from data source.
User data script (bastion.sh).


Dependencies:
Bastion SG ID from SSM.
Public subnet ID from locals (likely from SSM).
AMI info from data source.


## 30-db

Resources Created:
RDS instance using terraform-aws-modules/rds/aws:
MySQL 8.0 on db.t3.micro.
Database name "transactions".
Parameter and option groups.

Route53 CNAME record for RDS endpoint.

Dependencies:
DB SG ID from SSM.
DB subnet group name from SSM.


## 40-eks

Resources Created:
SSH key pair (aws_key_pair).
EKS cluster using terraform-aws-modules/eks/aws:
Cluster with version 1.30.
Managed node group (SPOT capacity, 2-10 nodes).
Addons: CoreDNS, EKS Pod Identity, Kube Proxy, VPC CNI.
Additional IAM policies for EBS CSI, EFS, ELB.


Dependencies:
VPC ID, private subnet IDs from locals/SSM.
Cluster and node SG IDs from locals/SSM.


## 50-acm

Resources Created:
ACM certificate (aws_acm_certificate) for *.daws78s.online.
Route53 records for certificate validation.
ACM certificate validation.

Dependencies:
Route53 hosted zone ID (variable).


## 60-ingress-alb

Resources Created:
Application Load Balancer (aws_lb): Public ALB.
LB listeners: HTTP (80) and HTTPS (443) with fixed responses.
LB target group for frontend (IP type, port 8080).
LB listener rule for host-based routing to frontend.
Route53 A record alias to ALB.

Dependencies:
Ingress SG ID from SSM.
Public subnet IDs from SSM.
ACM certificate ARN from SSM.
VPC ID from SSM.


## 70-ecr

Resources Created:
ECR repositories:
Backend repo.
Frontend repo.

Image scanning on push enabled, immutable tags.

Dependencies:
None explicit.


Manual Infrastructure Creation
All core infrastructure resources are created via Terraform. However, some post-creation setup steps require manual execution using the AWS CLI or eksctl (not from the AWS console directly, but you can use the console for equivalent actions if preferred). These are primarily for configuring the AWS Load Balancer Controller on the EKS cluster:

SSH to the bastion host and run:
aws configure to set credentials.
aws eks update-kubeconfig --region us-east-1 --name <YOUR-CLUSTER-NAME> to access the cluster.
kubectl get nodes to verify.

For RDS: Connect via bastion and run SQL scripts (from backend.sql) to create tables, users, etc.
For AWS Load Balancer Controller (Ingress):
Create IAM OIDC provider: eksctl utils associate-iam-oidc-provider --region us-east-1 --cluster <cluster-name> --approve.
Download and create IAM policy: Use curl and aws iam create-policy.
Create IAM role and ServiceAccount: Use eksctl create iamserviceaccount.
Install Helm chart: Add EKS repo and helm install.


These steps are run from the bastion host or your local machine with AWS CLI/eksctl/Helm installed. No additional infrastructure needs to be created manually in the AWS console; these are configuration/setup tasks.
Usage

Clone the repo.
Navigate to each directory in sequence.
Update variables as needed.
Run terraform init, terraform plan, terraform apply.
Perform the admin activities as outlined.

Diagram
Refer to eks-infra.svg in the root for a visual overview of the infrastructure.
Notes

This setup assumes a specific domain (daws78s.online); update for your domain.
Costs: Be aware of AWS resource costs (EKS, RDS, ALB, etc.).
Destruction: Run terraform destroy in reverse order to clean up.
Expert113 sources

