resource "aws_iam_policy" "alb" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "ALB Controller permissions"
  policy      = file("${path.module}/iam-policy.json")
}
# This must exist
resource "aws_iam_role" "terraform_admin" {
  name = "TerraformAdmin"

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
}

# Add this new attachment
resource "aws_iam_role_policy_attachment" "terraform_admin_eks_cluster" { // IAM Role for Bastion/EKS Access
  role       = aws_iam_role.terraform_admin.name   # This refers to the role above
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}