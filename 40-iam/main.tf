resource "aws_iam_policy" "alb" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "ALB Controller permissions"
  policy      = file("${path.module}/iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "terraform_admin_eks_cluster" {  // IAM Role for Bastion/EKS Access
  role       = aws_iam_role.terraform_admin.name  # Adjust to your role resource name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
} 