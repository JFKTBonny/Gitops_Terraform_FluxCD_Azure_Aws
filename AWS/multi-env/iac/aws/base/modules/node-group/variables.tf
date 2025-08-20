variable "cluster_name" {}
variable "label" {
  default = "nodes"
}
variable "subnet_ids" {}
variable "instance_types" {
  default  = ["t3.small"]
}
variable "node_name" {
    default = "private-node-group"
}

variable "environment" {
  
}