

provider "aws" {
  region = "us-east-1"
}

# VPC (equivalent to Azure Virtual Network)
resource "aws_vpc" "gitops_terraform_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "gitops-terraform-vpc"
    Environment = "gitops"
  }
}

# Default Subnet
resource "aws_subnet" "default_subnet" {
  vpc_id            = aws_vpc.gitops_terraform_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a" # adjust to your region/AZ

  tags = {
    Name = "bonny-subnet"
  }
}

# Bastion Subnet
resource "aws_subnet" "bastion_subnet" {
  vpc_id            = aws_vpc.gitops_terraform_vpc.id
  cidr_block        = "10.0.2.0/26"
  availability_zone = "us-east-1b" # use a different AZ if you want HA

  tags = {
    Name = "bonny-bastion-subnet"
  }
}
