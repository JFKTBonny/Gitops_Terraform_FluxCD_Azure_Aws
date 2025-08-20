



provider "aws" {
  region = "eu-central-2" # Switzerland (Zurich)
}

############################
# Networking (VPC + Subnets)
############################

resource "aws_vpc" "gitops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "gitops-${var.environment}-vpc"
  }
}

resource "aws_subnet" "default_subnet" {
  vpc_id                  = aws_vpc.gitops_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-central-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "default-subnet"
  }
}

resource "aws_subnet" "eks_subnet" {
  vpc_id                  = aws_vpc.gitops_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "gitops-${var.environment}-eks-subnet"
  }
}

resource "aws_internet_gateway" "gitops_igw" {
  vpc_id = aws_vpc.gitops_vpc.id

  tags = {
    Name = "gitops-${var.environment}-igw"
  }
}

resource "aws_route_table" "gitops_rt" {
  vpc_id = aws_vpc.gitops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gitops_igw.id
  }

  tags = {
    Name = "gitops-${var.environment}-rt"
  }
}

resource "aws_route_table_association" "default_assoc" {
  subnet_id      = aws_subnet.default_subnet.id
  route_table_id = aws_route_table.gitops_rt.id
}

resource "aws_route_table_association" "eks_assoc" {
  subnet_id      = aws_subnet.eks_subnet.id
  route_table_id = aws_route_table.gitops_rt.id
}

############################
# IAM Roles for EKS
############################

# Role for EKS control plane
resource "aws_iam_role" "gitops_eks_role" {
  name = "gitops-${var.environment}-eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "gitops_eks_cluster_policy" {
  role       = aws_iam_role.gitops_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "gitops_eks_vpc_policy" {
  role       = aws_iam_role.gitops_eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# Role for EKS worker nodes
resource "aws_iam_role" "gitops_node_role" {
  name = "gitops-${var.environment}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "gitops_node_policy" {
  role       = aws_iam_role.gitops_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "gitops_cni_policy" {
  role       = aws_iam_role.gitops_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "gitops_registry_policy" {
  role       = aws_iam_role.gitops_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

############################
# EKS Cluster + Node Group
############################

resource "aws_eks_cluster" "gitops_eks" {
  name     = "gitops-${var.environment}-eks"
  role_arn = aws_iam_role.gitops_eks_role.arn
  version  = "1.28"

  vpc_config {
    subnet_ids = [
      aws_subnet.default_subnet.id,
      aws_subnet.eks_subnet.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.gitops_eks_cluster_policy,
    aws_iam_role_policy_attachment.gitops_eks_vpc_policy
  ]
}

resource "aws_eks_node_group" "gitops_nodes" {
  cluster_name    = aws_eks_cluster.gitops_eks.name
  node_group_name = "default"
  node_role_arn   = aws_iam_role.gitops_node_role.arn
  subnet_ids      = [aws_subnet.eks_subnet.id]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.small"]
  disk_size      = 30

  depends_on = [
    aws_iam_role_policy_attachment.gitops_node_policy,
    aws_iam_role_policy_attachment.gitops_cni_policy,
    aws_iam_role_policy_attachment.gitops_registry_policy
  ]
}

############################
# ECR Repository
############################

resource "aws_ecr_repository" "gitops_ecr" {
  name = "gitops-${var.environment}-ecr"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
  }
}
