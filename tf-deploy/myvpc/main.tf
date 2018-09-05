# deploys the dev vpc infra resources of the generic service platform
# See README.md for details on how to fill in all the commented out values.

provider "aws" {
  region = "us-east-1"
}

// Note: as a best practice, we recommend using dynamodb for state locking but
// for simplicity we skip that here.
terraform {
  backend "s3" {
    #bucket         = "CHANGEME"
    key            = "ecs-example-vpc/terraform/vpc/terraform.tfstate"
    region         = "us-east-1"
  }

  required_version = "~> 0.11.7"
}

module "vpc" {
  source   = "../../templates/vpc"
  vpc_name = "ecs-example-vpc"
  # create this key pair in the AWS console
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair
  #ec2_key_name = "CHANGEME"
  asg_size = "2"
  azs = ["us-east-1a", "us-east-1b", "us-east-1c"] # for the instances
  region = "us-east-1"
  cidr = "10.0.0.0/20"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  database_subnets = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
  # if you want to access the bastion public IP change this.
  bastion_cidr_blocks = ["10.0.1.1/32"] 
}

output "alb_dns_name" {
  value = "${module.vpc.alb_dns_name}"
}

output "target_group_arn" {
  value = "${module.vpc.target_group_arn}"
}
