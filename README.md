# tf-ecs-example
An example implementation of an AWS ECS cluster managed with Terraform.

## Introduction

AWS provides documentation and useful tools for ECS clusters deployed with Cloudformation. This repo lays out some patterns, examples and tools for implementing an ECS cluster using Terraform (for this demo we are running our own EC2 instances, rather than using Fargate).

If you currently have a service deployed with Terraform using an AWS Autoscaling group and Application Load Balancer, this repo should help you bridge the gap to using Docker to deploy your service. The demo encapsulates some good practices for maintaining infrastructure: representing infrastructure as code, automation, rapid deployment and security. More details below.

If you want to get right into deploying the demo, feel free to jump ahead: it's [here](docs/demo.md) The useful python scripts are in a separate repo: [ecs-utils](https://github.com/navapbc/ecs-utils/blob/master/README.md)

## The Infrastructure

<img src="https://s3.amazonaws.com/nava-public-static/ecsdemo/ecs.png" width="500px">

The above image represents the basic components of the demo system (In a real  system you might have a database or additional services). One thing that stands out is the separation of the ECS service (the part which runs your application container) and the underlying infrastructure. The idea here is that we want to maintain all of our resources with checked in terraform configuration but that the maintenance of the service (e.g. updating a docker image) is something that is likely to happen at a different cadence and perhaps even by a different team. So, we separate these concerns to avoid having conflicting changes and to make clear the logical separation. 

A typical AWS service would consist of networking (a VPC), an Autoscaling group of EC2 instances and a load balancer. The demo uses terraform to represent [all those details](templates/vpc). Let's review the components you need to transform that into an ECS cluster.

### ECS Agent/AMI

This demo uses the Amazon Linux ECS enabled AMI.

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html

Otherwise you need to provide a OS-compatible AMI that has had the ECS agent installed.

https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-agent-install.html

### The cluster
Adding an ECS cluster involves:
- [creating the cluster](templates/vpc/main.tf)
- [enabling](templates/vpc/iam.tf) some new IAM instance role permissions.
- EC2 instances need to be told what cluster they belong to. This is done at startup through a simple [userdata](templates/vpc/user_data.tpl) addition.

## The ECS service
It's a good practice to separate your underlying infrastructure from your service. This allows service changes (e.g. updating a docker image) to be handled through its own process, separate from underlying infrastructure changes. We have implemented the ECS service and task definition in a separate terraform configuration with its own terraform state.

### Service Terraform

The terraform template for our service is [here](templates/basic-app). In the demo, you will be deploying from a config file using that template. The service takes the target group arn and cluster name as input. This is how AWS knows where your containers should run and which load balancer they should attach to.

### Example Docker App

We've provided a simple example app [here](basic-app/). The primary purpose of the application is to showcase the use of AWS Parameter store. Being able to provide your running application with config parameters and secrets is an essential pattern that we cover in the demo.

### The demo

We've included a demo tutorial which allows you to create a fully functional ECS cluster and service: [docs/demo.md](docs/demo.md)
