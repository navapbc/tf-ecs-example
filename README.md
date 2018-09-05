# tf-ecs-example
An example implementation of an AWS ECS cluster managed with Terraform

## Install requirements

- AWS CLI (assumes you have AWS credentials set up as well: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/configuration.html)
- Terraform
- Docker
- Python/Pip (> 3.6)
- pip install git+git://github.com/navapbc/ecs-utils#egg=ecs-utils

## Setup required resources in AWS

Before creating your VPC and your ECS service with terraform you will need to create a few resources. (Note: we use us-east-1 in our example configs; change as needed).

### Terraform S3 bucket

Optional; you can also use an existing bucket, used later as an root location for tf state.
```
aws s3api create-bucket --bucket $S3_BUCKET --region us-east-1
```

### AWS EC2 instance key pair

You may already have this, if not create a pair: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair

### AWS ECR repo

Our example app will live in an Elastic Container Registry repo.  Create one:
```
aws ecr create-repository --repository-name ecs-example-app --region us-east-1
```

## Create your VPC

The terraform configuration for your VPC can be found at: tf-deploy/myvpc/main.tf

Edit the "CHANGEME" values in that file

```
cd tf-deploy/myvpc
terraform init # checks that everything is in order
terraform plan # shows the proposed resources changes, review them
terraform apply # applies them, this could take a few minutes
```

Note: make note of the output, in particular "target_group_arn", you will need that later.

## Build your docker container

Login to ECR:
```
aws ecr get-login --no-include-email --region us-east-1
# copy paste the output of the above command to actually login
# should see: Login Succeeded
```

Build basic-app:
```
cd basic-app/
# build and tag (change the repo path based on what you created earlier)
YOUR_IMAGE=CHANGEME.dkr.ecr.us-east-1.amazonaws.com/ecs-example-app:latest
docker build -t $YOUR_IMAGE .
# push
docker push $YOUR_IMAGE
```

## Set an AWS Parameter

If you look in basic-app/Dockerfile, you see that we have launched the nodejs application with something called parameter-store-exec. This is what makes AWS Parameters available to the application.

In templates/vpc/iam.tf, you can see that the cluster instances will have access to a parameter namespace, named after your vpc: e.g /ecs-example-vpc/*.

And in templates/basic-app/ecs-tasks/app.json you can see that we set the env var PARAMETER_STORE_EXEC_PATH, which is what parameter-store-exec will use to load AWS parameters.

Set a parameter value using ecs-utils:
```
param --region us-east-1 put /ecs-example-vpc/basic-app/FOO foo123
```

Let's demonstrate setting an encrypted value as well (using ecs-utils)

Create a key:
```
kms-create --region us-east-1 --alias ecs-example
```

Set an encrypted value:
```
param --region us-east-1 --kms-key-alias ecs-example put /ecs-example-vpc/basic-app/BAR foo123456
```

This will be stored encrypted. templates/vpc/iam.tf rules allow the cluster instance access to the KMS key it is encrypted with.

You can find your parameters in the SSM console:
https://console.aws.amazon.com/systems-manager/parameters?region=us-east-1

## Create your Service
The configuration for your ECS service is at: tf-deploy/myapp/main.tf

Use the same bucket you did for your vpc and also change the "target_group_arn" value you captured earlier.


```
cd tf-deploy/myapp
terraform init # checks that everything is in order
terraform plan --var docker_image=$YOUR_IMAGE
terraform apply --var docker_image=$YOUR_IMAGE
```

## Test the service

If you used the default naming, you should see tasks running at:
https://console.aws.amazon.com/ecs/home?region=us-east-1#/clusters/ecs-example-vpc-cluster-a

You should see you load balancer at:
https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers:search=ecs-example-vpc-alb;sort=loadBalancerName

Click on your load balancer in the console and copy paste the DNS name. Load it in your browser, you should see:
```
Hello world
```

Add /env/FOO to the url, you should see:
```
FOO length is: 6
```

/env/BAR:
```
BAR length is: 9
```

This demonstrates that the application was able to access our environment variables (without exposing their values publicly!)
