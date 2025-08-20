output "vpc_id" {
  value = aws_vpc.cluster_vpc.id
}
output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}
output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "vpc_cidr" {
  value = aws_vpc.cluster_vpc.cidr_block
}