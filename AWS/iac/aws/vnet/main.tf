


# AWS Provider
provider "aws" {
  region = "eu-central-2" # Switzerland (Zurich)
}

# VPC (equivalent to Virtual Network)
resource "aws_vpc" "gitops_terraform_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "gitops-terraform-vpc"
  }
}

# Public Subnet (equivalent to default_subnet in Azure)
resource "aws_subnet" "default_subnet" {
  vpc_id                  = aws_vpc.gitops_terraform_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "eu-central-2a" # Pick one AZ in region
  map_public_ip_on_launch = true

  tags = {
    Name = "default-subnet"
  }
}

# Bastion Subnet (equivalent to AzureBastionSubnet)
resource "aws_subnet" "bastion_subnet" {
  vpc_id                  = aws_vpc.gitops_terraform_vpc.id
  cidr_block              = "10.0.2.0/26"
  availability_zone       = "eu-central-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "bastion-subnet"
  }
}



