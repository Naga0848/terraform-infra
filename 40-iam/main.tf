
# Optional: Policy for AWS Load Balancer Controller (keep if using ALB Ingress)
resource "aws_iam_policy" "alb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Permissions required by AWS Load Balancer Controller"
  policy      = file("${path.module}/iam-policy.json")
}

# IAM Role that the bastion host will assume
resource "aws_iam_role" "terraform_admin" {
  name = "TerraformAdmin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "TerraformAdmin"
  }
}

# SSM access - enables secure login via AWS Session Manager (no SSH keys or open ports needed)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EKS Cluster access - required for 'aws eks update-kubeconfig', describe, list, etc.
resource "aws_iam_role_policy_attachment" "eks_cluster" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# EKS Worker/Node access - required for full kubectl functionality
resource "aws_iam_role_policy_attachment" "eks_worker" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Instance Profile - this is attached to the bastion EC2 instance
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion-profile"
  role = aws_iam_role.terraform_admin.name
}