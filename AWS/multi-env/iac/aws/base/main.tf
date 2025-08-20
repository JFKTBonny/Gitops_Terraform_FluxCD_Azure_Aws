


# AWS Provider
provider "aws" {
  region = "eu-central-2" # Switzerland (Zurich)
}

# VPC (equivalent to Azure Virtual Network)
resource "aws_vpc" "gitops_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "gitops-${var.environment}-vpc"
  }
}

# Default Subnet
resource "aws_subnet" "default_subnet" {
  vpc_id                  = aws_vpc.gitops_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-central-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "default-subnet"
  }
}

# EKS Subnet (equivalent to AKS subnet)
resource "aws_subnet" "eks_subnet" {
  vpc_id                  = aws_vpc.gitops_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "gitops-${var.environment}-eks-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gitops_igw" {
  vpc_id = aws_vpc.gitops_vpc.id

  tags = {
    Name = "gitops-${var.environment}-igw"
  }
}

# Route Table
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

# Route Table Associations
resource "aws_route_table_association" "default_assoc" {
  subnet_id      = aws_subnet.default_subnet.id
  route_table_id = aws_route_table.gitops_rt.id
}

resource "aws_route_table_association" "eks_assoc" {
  subnet_id      = aws_subnet.eks_subnet.id
  route_table_id = aws_route_table.gitops_rt.id
}

# EKS Cluster
resource "aws_eks_cluster" "gitops_eks" {
  name     = "gitops-${var.environment}-eks"
  role_arn = aws_iam_role.gitops_eks_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.default_subnet.id,
      aws_subnet.eks_subnet.id,
    ]
  }

  version = "1.28"

  depends_on = [
    aws_iam_role_policy_attachment.gitops_eks_policy,
    aws_iam_role_policy_attachment.gitops_eks_vpc_policy
  ]
}

# EKS Node Group (equivalent to AKS node pool)
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
    aws_iam_role_policy_attachment.gitops_cni_policy
  ]
}

# IAM Role for EKS Cluster
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

resource "aws_iam_role_policy_attachment" "gitops_eks_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.gitops_eks_role.name
}

resource "aws_iam_role_policy_attachment" "gitops_eks_vpc_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.gitops_eks_role.name
}

# IAM Role for EKS Nodes
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
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.gitops_node_role.name
}

resource "aws_iam_role_policy_attachment" "gitops_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.gitops_node_role.name
}

resource "aws_iam_role_policy_attachment" "gitops_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.gitops_node_role.name
}

# ECR (equivalent to Azure Container Registry)
resource "aws_ecr_repository" "gitops_ecr" {
  name = "gitops-${var.environment}-ecr"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
  }
}
