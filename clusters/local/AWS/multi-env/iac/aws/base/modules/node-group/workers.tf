resource "aws_eks_node_group" "nodes" {
  cluster_name    = "gitops-${var.environment}-eks"
  node_group_name  = "gitops-${var.environment}-nodes"
  node_role_arn   =  aws_iam_role.worker_nodes_role.arn
  subnet_ids = var.subnet_ids
  capacity_type  = "ON_DEMAND" #or "SPOT"
  instance_types = var.instance_types
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 2
  }
  update_config {
    max_unavailable = 1
  }
  labels = {
    name = var.label
  }
  tags = {
    Name = "worker-node"
  }
  depends_on = [ aws_iam_role.worker_nodes_role ]
}
