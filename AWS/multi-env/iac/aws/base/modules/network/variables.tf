variable "cidr_blocks" {
  description = "cidr blocks"
  type        = map(any)
  default = {
    private-subnet-1 = "10.0.3.0/24"
    private-subnet-2 = "10.0.4.0/24"
    public-subnet-1 = "10.0.5.0/24"
    public-subnet-2 = "10.0.6.0/24"
    cluster-network  = "10.0.0.0/16"
    internet = "0.0.0.0/0"
  }
}

variable "vpc_tag" {
    default = "public-endpoint-cluster-vpc"
}

variable "cluster_security_group_id" {
}

variable "environment" {
  
}