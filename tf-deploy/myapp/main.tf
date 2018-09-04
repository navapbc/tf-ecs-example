# Example ECS service terraform config file.
# See README.md for details on how to fill in all the commented out values.

module "service" {
  source           = "../../templates/basic-app"
  desired_count    = "2"
  #vpc_name         = "ecs-example-vpc"
  region           = "us-east-1"
  #target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456:targetgroup/ecs-example-vpc-basic-app/123456"
  #cluster          = "ecs-example-vpc-cluster-a"
  docker_image     = "${var.docker_image}"
  app_name         = "basic-app"
}

provider "aws" {
  #region = "us-east-1"
}

terraform {
  backend "s3" {
    #bucket         = "ecs-example-tfstate"
    #key            = "ecs-example-vpc/terraform/basic-app/terraform.tfstate"
    #region         = "us-east-1"
    #dynamodb_table = "ecs-example-tflock"
  }

  required_version = "~> 0.11.7"
}
