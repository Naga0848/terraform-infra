## Terraform AWS EKS Infrastructure

## Commands to install the resources

    for i in 80-eks 70-frontend-alb 60-acm 20-bastion 30-ecr 10-sg 00-vpc; do
        cd $i
        terraform init
        cd ..
    done

    for i in 80-eks 70-frontend-alb 60-acm 20-bastion 30-ecr 10-sg 00-vpc; do
        cd $i
        terraform plan
        cd ..
    done

    for i in 80-eks 70-frontend-alb 60-acm 20-bastion 30-ecr 10-sg 00-vpc; do
        cd $i
        terraform apply -auto-approve
        cd ..
    done

    for i in 80-eks 70-frontend-alb 60-acm 20-bastion 30-ecr 10-sg 00-vpc; do
        cd $i
        terraform destroy -auto-approve
        cd ..
    done


    This repository provisions a complete AWS infrastructure using modular Terraform components. It is designed for scalability, reusability, and clarity, following best practices for infrastructure-as-code. Each module represents a distinct component of the architecture and can be applied independently or orchestrated via CI/CD pipelines.

![alt text](images/module-overview.png)

![alt text](images/readme.png)

Below are the total no of resources going to be created from this repo
![alt text](images/resources.png)


