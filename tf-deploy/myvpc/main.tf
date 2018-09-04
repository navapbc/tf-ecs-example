# deploys the dev vpc infra resources of the generic service platform
# See README.md for details on how to fill in all the commented out values.

provider "aws" {
  #region = "us-east-1"
}

terraform {
  backend "s3" {
    #bucket         = "ecs-example-tfstate"
    #key            = "ecs-example-vpc/terraform/vpc/terraform.tfstate"
    #region         = "us-east-1"
    #dynamodb_table = "ecs-example-tflock"
  }

  required_version = "~> 0.11.7"
}

module "vpc" {
  source   = "../../templates/vpc"
  #vpc_name = "ecs-example-vpc"
  # create this key pair in the AWS console
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair
  #ec2_key_name = "your_aws_key_pair_name"
  asg_size = "2"
  # availabity zones for the instances
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"]
  region = "us-east-1"


  # These are the default CIDRs, if you want to peer multiple VPCs edit this and
  # change the CIDR blocks so they are not the same
  cidr = "10.0.0.0/20"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  database_subnets = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
}

output "alb_dns_name" {
  value = "${module.vpc.alb_dns_name}"
}

output "target_group_arn" {
  value = "${module.vpc.target_group_arn}"
}

output "rds_instance_name" {
  value = "${module.vpc.rds_instance_name}"
}
