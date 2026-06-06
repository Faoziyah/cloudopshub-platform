# eks.tf — EKS Kubernetes Cluster (AWS Managed)

# IAM Role for EKS Control Plane
resource "aws_iam_role" "eks_role" {
  name = "cloudopshub-eks-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow",
      Principal = { Service = "eks.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role for Worker Nodes
resource "aws_iam_role" "node_role" {
  name = "cloudopshub-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" } }]
  })
}
resource "aws_iam_role_policy_attachment" "node_policy"  { role = aws_iam_role.node_role.name, policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy" }
resource "aws_iam_role_policy_attachment" "cni_policy"   { role = aws_iam_role.node_role.name, policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy" }
resource "aws_iam_role_policy_attachment" "ecr_policy"   { role = aws_iam_role.node_role.name, policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" }

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "cloudopshub-prod"
  role_arn = aws_iam_role.eks_role.arn
  vpc_config {
    subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  }
  tags = { Name = "cloudopshub-prod" }
}

# Worker Nodes (t2.micro = free tier eligible)
resource "aws_eks_node_group" "workers" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "cloudopshub-workers"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  instance_types  = ["t2.micro"]   # Free tier eligible
  scaling_config  { desired_size = 2, max_size = 3, min_size = 1 }
}

output "cluster_endpoint"   { value = aws_eks_cluster.main.endpoint }
output "cluster_name"       { value = aws_eks_cluster.main.name }