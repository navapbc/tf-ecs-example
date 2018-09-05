# tf-ecs-example
An example implementation of an AWS ECS cluster managed with Terraform.

## Introduction

AWS provides lots of documentation and useful tools for ECS clusters deployed with Cloudformation. This repo lays out some patterns, examples and tools for implementing an ECS cluster using Terraform (for this Demo we are not using Fargate but, rather, are running our own EC2 instances).

If you currently have a service deployed with Terraform using an AWS Autoscaling group and Application Load Balancer, this repo should help you bridge the gap to using Docker to deploy your service.

If you want to jump right into deploying the demo, feel free to jump ahead: it's [here](docs/demo.md)

## The Ingredients

Let's assume you already run EC2 instances in Autoscaling groups with a load balancer. Let's review the components needed to be running an ECS cluster.

### ECS Agent

This Demo uses the Amazon Linux ECS enabled AMI, otherwise you need to provide a OS-compatible AMI that has had the ECS agent installed.

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-install.html

To turn your ASG into an ECS cluster involves [creating the cluster](templates/vpc/main.tf) and [enabling](templates/vpc/iam.tf) some new IAM instance role permissions.







