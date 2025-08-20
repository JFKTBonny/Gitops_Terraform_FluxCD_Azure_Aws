
resource "aws_vpc" "cluster_vpc" {
  cidr_block = var.cidr_blocks["cluster-network"]
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "gitops-${var.environment}-vpc"
  }
}