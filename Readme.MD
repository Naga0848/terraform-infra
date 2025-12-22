## Terraform AWS EKS Infrastructure

    Here the resources depends on eachother while they are getting created.

    Here, 
        SG is dependent on VPC
        ALB is dependent on SG and 
        Bastion, EKS and ACM are independent, so then can be created parllelly.

    This dependency is maintained while we are creating the infra using the Jenkins pipelines.
    Even if we are creating manually via terraform, make sure VPC is created first and then proceed with the other services.

    Look at the below image, to understand about upstream-downstream

![alt text](images/upstream-downstream.png)


## Commands to install the resources

    For creating the resources, we need to manually go in to all the folders (00-vpc 10-sg 20-bastion 30-ecr 60-acm 70-frontend 80-eks) and perform the necessary commands like terraform init, terraform plan, terraform apply -auto-approve

    But, while deleting, we delete them in a single go by using the below command

    for i in 00-vpc 10-sg 20-bastion 30-ecr 60-acm 70-frontend-alb 80-eks; do
        cd $i
        terraform destroy -auto-approve
        cd ..
    done

    But make sure, every resource is deleted properly. Check in the AWS console.
    
    
    This repository provisions a complete AWS infrastructure using modular Terraform components. It is designed for scalability, reusability, and clarity, following best practices for infrastructure-as-code. Each module represents a distinct component of the architecture and can be applied independently or orchestrated via CI/CD pipelines.

![alt text](images/module-overview.png)

![alt text](images/readme.png)

Below are the total no of resources going to be created from this repo for 00-vpc
![alt text](images/00-vpc-resources.png)

Below are the total no of resources going to be created from this repo for 10-sg
![alt text](images/10-SG-services.png)


Below are the total no of resources going to be created from this repo for 70-frontend-alb
![alt text](images/70-frontend-alb.png)




## Steps to be followed after creating these INFRA

    On Jenkins-Agent
        backend repo -> CI 
        backend deploy -> CD
    1. create infra
    2. EKS setup
            allow jenkins agent sg in eks control plane (Manually go to EKS security groups > edit > inbound > https > no pasthe the SG of Jenkins Agent(EC2) and save it.)
            create namespace (kubectl create ns roboshop)
            create DB pods
	        mongodb redis mysql rabbitmq
    3. we can deploy applications


    aws configure
    provide the accesskey and secretkey
    aws eks update-kubeconfig --region us-east-1 --name roboshop-dev
    kubectl get nodes




========================

This is the readme.md from grok

# AWS Infrastructure Setup with Terraform

This project sets up a secure AWS environment for running web apps on Kubernetes (EKS). It's 
like building a cloud house: network, security, servers, and app managers.

## Prerequisites (Do These Manually First)
Before running anything, set up these in the AWS Console or your computer. Think of them as 
gathering ingredients.

1. **AWS Account and CLI**:
   - Sign up for AWS if you haven't.
   - Install AWS CLI and Terraform on your computer.
   - Run `aws configure` to add your access keys.

2. **Route53 Hosted Zone**:
   - Go to AWS Console > Route53 > Hosted Zones > Create Hosted Zone.
   - Enter your domain (e.g., daws84s.site).
   - Copy the "Hosted Zone ID" and add to `terraform.tfvars` as `zone_id = "YOUR_ID"`.

3. **IAM Role for Bastion**:
   - AWS Console > IAM > Roles > Create Role.
   - Trust entity: EC2.
   - Attach policies: AdministratorAccess (or what you need).
   - Name: "TerraformAdmin".

4. **AMI ID**:
   - AWS Console > EC2 > AMIs > Search for "Amazon Linux 2023".
   - Copy an AMI ID (e.g., ami-12345678) and add to locals or variables.

5. **Files**:
   - Create `bastion.sh`: A simple script like `#!/bin/bash echo "Setting up bastion"`.
   - Create `iam-policy.json`: Copy ALB controller policy from AWS docs (search 
"AWSLoadBalancerControllerIAMPolicy").

6. **Variables File**:
   - Create `terraform.tfvars` in each folder (or root).
   - Example:

    project = "roboshop"
    environment = "dev"
    zone_name = "daws84s.site"
    zone_id = "YOUR_ZONE_ID"
    public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
    private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
    database_subnet_cidrs = ["10.0.5.0/24", "10.0.6.0/24"]
    images = ["frontend", "backend"]  # For ECR
    bastion_sg_name = "bastion"
    bastion_sg_description = "For bastion host"


## Steps to Create Resources
Run these in order, one folder at a time. Each folder is like a chapter. In each folder, open
terminal and run:

1. `terraform init` (Downloads helpers).
2. `terraform validate` (Checks for errors).
3. `terraform plan` (Shows what will be built – review it!).
4. `terraform apply` (Builds it – type "yes" to confirm).

**Order of Folders**:
1. **vpc**: Builds the network base.
2. **10-sg**: Adds security rules.
3. **20-bastion**: Launches the jump server.
4. **30-ecr**: Sets up image storage.
5. **40-iam**: Adds permissions.
6. **60-acm**: Gets HTTPS certificates (wait 5-10 mins for validation).
7. **70-frontend-alb**: Sets up web traffic handler.
8. **80-eks**: Builds the app cluster (this takes longest, 10-15 mins).

## Cleanup
If you want to delete everything: In each folder (reverse order), run `terraform destroy` (ty
"yes").

## Tips
- If something fails, check error messages – often missing variables or manual setups.
- Costs: This creates real AWS stuff, so watch your bill! Free tier might cover basics.
- Questions? Search "Terraform AWS [error]" on Google.

Happy building!