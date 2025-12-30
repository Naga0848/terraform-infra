# 20-bastion/main.tf

# IAM Role for the bastion host
resource "aws_iam_role" "bastion_role" {
  name = "TerraformAdmin"  # Keeps the same role name you were using

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-bastion-role"
    }
  )
}

# Attach the AWS-managed policy for SSM Session Manager access
# This enables secure, audit-ready access without SSH keys or open ports
resource "aws_iam_role_policy_attachment" "bastion_ssm_core" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create the required IAM Instance Profile
# This fixes the "Invalid IAM Instance Profile name" error
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "TerraformAdmin-Profile"  # Unique name; can be different from role
  role = aws_iam_role.bastion_role.name

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-bastion-profile"
    }
  )
}

# Your bastion EC2 instance
resource "aws_instance" "bastion" {
  ami                    = local.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [local.bastion_sg_id]
  subnet_id              = local.public_subnet_id

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  user_data = file("bastion.sh")

  # Now correctly references the instance profile name
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-bastion"
    }
  )
}

# For control plane operations (describe, list, update-kubeconfig, etc.)
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.terraform_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# For worker node / general EKS operations from tools like kubectl
resource "aws_iam_role_policy_attachment" "eks_worker_policy" {
  role       = aws_iam_role.terraform_admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}