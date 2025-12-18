## Terraform AWS EKS Infrastructure

    This repository provisions a complete AWS infrastructure using modular Terraform components. It is designed for scalability, reusability, and clarity, following best practices for infrastructure-as-code. Each module represents a distinct component of the architecture and can be applied independently or orchestrated via CI/CD pipelines.

![alt text](images/module-overview.png)

![alt text](images/Readme.png)

![alt text](images/Readme1.png)


## In this repo, we create the complete INFRA using the terraform and Jenkins files for varios components

    First Install the terraform on the Jenkins agent machine

    Install yum-config-manager to manage your repositories.

    $ sudo yum install -y yum-utils

    Use yum-config-manager to add the official HashiCorp RHEL repository.

    $ sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

    Install Terraform from the new repository.

    $ sudo yum -y install terraform


## Commands to install these resources all at a time

    1) To initialize the terraform
    for i in 80-eks 70-frontend-alb 60-acm 30-ecr 20-bastion 10-sg 00-vpc; do
        cd $i
        terraform init
        cd ..
    done

    2) To terraform plan
    for i in 80-eks 70-frontend-alb 60-acm 30-ecr 20-bastion 10-sg 00-vpc; do
        cd $i
        terraform plan
        cd ..
    done

    3) To terraform apply -auto-approve
    for i in 80-eks 70-frontend-alb 60-acm 30-ecr 20-bastion 10-sg 00-vpc; do
        cd $i
        terraform apply -auto-approve
        cd ..
    done

## Understanding Upstream and Downstream

    From the below image, we can understand that Security Group is dependent on VPC and Bastion depends on Security Group. And the ALB is dependent on ACM

    ACM, EKS and Bastion are not dependent on each other, so these pipelines can be executed parallelly

![alt text](images/upstream&downstream.png)

    Below is the infra which comes when we create using a Jenkins Pipeline

![alt text](images/infra.png)

    We need to check for these ssm parameters, if we stuck with errors while creating it via pipelines

![alt text](images/ssm-parameter-error.png)

    Statefile is removed from the shiva's repo as we are creating it manually from our Git Console

![alt text](images/statefile-removal.png)

    VPC Approval when we are creating the infra via Jenkins pipeline

![alt text](images/vpc-approval.png)

    Jenkins error while creating infra using the Jenkins pipelines

![alt text](images/jenkins-error.png)
