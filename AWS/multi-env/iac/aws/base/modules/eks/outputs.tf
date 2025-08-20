
output "cluster_name" {
  value = aws_eks_cluster.public_endpoint_cluster.name
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.public_endpoint_cluster.vpc_config[0].cluster_security_group_id
}
output "cluster_object" {
  value = aws_eks_cluster.public_endpoint_cluster
}