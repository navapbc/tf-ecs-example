
variable "ec2_key_name" {
  description = "ssh key pair"
}

variable "bastion_cidr_blocks" {
  description = "List of cidr IP's that can access the public bastion IP"
  type        = "list"
}

variable "vpc_name" {
  description = "name for the vpc and prefix for other resources"
}

# for demo purposes the load balancer is open on :80
variable "alb_cidr_blocks" {
  description = "List of cidr IP's that can access the alb"
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable "asg_size" {
  description = "number of instances in asg"
  default     = "2"
}

# this is the official aws ami for ecs:
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html
variable "ami_id" {
  default = "ami-00129b193dc81bc31"
}

variable "app_instance_size" {
  default = "t2.small"
}

variable "azs" {
  description = "List of 3 AWS AZ's"
  type        = "list"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "cidr" {
  description = "VPC cidr block"
  default     = "10.0.0.0/20"
}

variable "database_subnets" {
  description = "Allocation of 3 subnets from your CIDR block for databases"
  type        = "list"
  default     = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
}

variable "private_subnets" {
  description = "Allocation of 3 subnets from your CIDR block for the cluster instances"
  type        = "list"
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "Allocation of 3 subnets from your CIDR block for the bastion and LB"
  type        = "list"
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "region" {
  default = "us-east-1"
}
