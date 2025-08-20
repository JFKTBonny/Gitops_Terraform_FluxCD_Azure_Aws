provider "aws" {
  region  = var.region
  profile = "default"
}

#create eni in the dataplane (step x)
module "cluster" {
  source = "../base/modules/eks"
  #ENI subnet = private subnets
  private_subnet_ids = module.vpc.private_subnet_ids
  environment        = var.environment

}

module "vpc" {
  source                    = "../base/modules/network"
  cluster_security_group_id = module.cluster.cluster_security_group_id
  environment               = var.environment
}
module "nodes" {
  source       = "../base/modules/node-group"
  cluster_name = module.cluster.cluster_name
  subnet_ids   = module.vpc.private_subnet_ids
  environment  = var.environment

}