resource "aws_eks_cluster" "public_endpoint_cluster" {
  name     = "gitops-${var.environment}-eks"
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster_role.arn
  #configure data plane subnets and eni
  vpc_config {
    subnet_ids = concat(
      var.private_subnet_ids
    )
    endpoint_public_access  = "true"
    # public_access_cidrs = ["<public ip range"] ip range allowed to access the cluster...
  }
  depends_on = [ aws_iam_role.cluster_role ]
}