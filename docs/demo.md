## Demo Requirements

- AWS CLI (assumes you have AWS credentials set up as well: https://boto3.amazonaws.com/v1/documentation/api/latest/guide/configuration.html)
- Terraform
- Docker
- Python/Pip (> 3.6)
- pip install git+git://github.com/navapbc/ecs-utils#egg=ecs-utils

## Setup required resources in AWS

Before creating your VPC and your ECS service with terraform you may need to create a few resources. Note: we use us-east-1 for this demo. If you need to use a different region, you will need to find references to us-east-1 in the templates/ and tf-deploy/ and change them. One tricky us-east-1 requirement is the ECS AMI ID in templates/vpc/main.tf.

### Terraform S3 bucket

Optional; this will be used as the root location for tf state.
```
aws s3api create-bucket --bucket YOUR_BUCKET_NAME --region us-east-1
```

### AWS EC2 instance key pair

You may already have this, if not create a pair: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair

### AWS ECR repo

Our example app will live in an Elastic Container Registry repo.  Create one:
```
aws ecr create-repository --repository-name ecs-example-app --region us-east-1
```

## Create your VPC

The terraform configuration for your VPC can be found at: [tf-deploy/myvpc/main.tf](../tf-deploy/myvpc/main.tf)

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
# the tagged image url should be based on the repo url you created previously
YOUR_IMAGE=CHANGEME.dkr.ecr.us-east-1.amazonaws.com/ecs-example-app:latest
# build and tag (change the repo path based on what you created earlier)
docker build -t $YOUR_IMAGE .
# push
docker push $YOUR_IMAGE
```

## Set an AWS Parameter

If you look in [basic-app/Dockerfile](../basic-app/Dockerfile), you see that we have launched the nodejs application with something called parameter-store-exec. This is what makes AWS Parameters available to the application.

In [templates/vpc/iam.tf](../templates/vpc/iam.tf), you can see that the cluster instances will have access to a parameter namespace, named after your vpc: e.g /ecs-example-vpc/*.

And in [templates/basic-app/ecs-tasks/app.json](../templates/basic-app/ecs-tasks/app.json) you can see that we set the env var PARAMETER_STORE_EXEC_PATH, which is what parameter-store-exec will use to load AWS parameters.

Set a parameter value using ecs-utils **param** script:
```
param --region us-east-1 put /ecs-example-vpc/basic-app/FOO foo123
```

Let's demonstrate setting an encrypted value as well (using ecs-utils)

Create a key with ecs-utils **kms-create** script:
```
kms-create --region us-east-1 --alias ecs-example
```

Set an encrypted value:
```
param --region us-east-1 --kms-key-alias ecs-example put /ecs-example-vpc/basic-app/BAR foo123456
```

This will be encrypted. [templates/vpc/iam.tf](../templates/vpc/iam.tf) rules allow the cluster instance access to the KMS key it is encrypted with.

You can browse your parameters in the SSM console:
https://console.aws.amazon.com/systems-manager/parameters?region=us-east-1

## Create your Service
The configuration for your ECS service is here: [tf-deploy/myapp/main.tf](../tf-deploy/myapp/main.tf)

Use the same bucket you did for your vpc and also change the "target_group_arn" value you captured earlier.

Deploy using the tagged image URL you set earlier:

```
cd tf-deploy/myapp
terraform init # checks that everything is in order
terraform plan --var docker_image=$YOUR_IMAGE
terraform apply --var docker_image=$YOUR_IMAGE
```

terraform apply should be very quick: ECS is eventually consistent: you need to check that your app deployed in the AWS ECS console, or using the handy ecs-utils **service-check**
```
service-check --cluster-name ecs-example-vpc-cluster-a --region us-east-1 ecs-example-vpc-basic-app
```

## Test the service e2e

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

This demonstrates that the application was able to access our environment variables (without exposing their values publicly!) This is obviously a very trivial application. A real application would want/need paramters like a database hostname and password.

To review how all this works, the docker container is using the parameter-store-exec tool to pull AWS Parameter store params into the unix environment.
https://github.com/navapbc/tf-ecs-example/blob/master/basic-app/Dockerfile#L21

The AWS Parameter store path it uses is defined here:
https://github.com/navapbc/tf-ecs-example/blob/master/templates/basic-app/ecs-tasks/app.json#L16

You can see where the nodejs code is accessing the unix environment here: https://github.com/navapbc/tf-ecs-example/blob/master/basic-app/server.js#L19

## Bonus: rolling EC2 instance update

If you are running your own EC2 instances you will need to update them from time to time. AWS provides a pattern for updating your ECS cluster without downtime geared toward a Cloudformation environment:

https://aws.amazon.com/blogs/compute/how-to-automate-container-instance-draining-in-amazon-ecs/

We've provided an alternative pattern. When you want to update your EC2 AMI (say to the latest ECS enabled image), you update the image_id in the launch configuration terraform in [templates/vpc/main.tf](../templates/vpc/main.tf). Once you deploy that, AWS does not actually update running instances. An orchestration must occur. ecs-utils provides that orchestration with the **rolling-replace** script. Try it:

```
rolling-replace --cluster-name ecs-example-vpc-cluster-a --region us-east-1
```

Note: the above invocation does a rolling replacement of instances in the ASG. If you had actually updated the AMI, you would want to include the flag --ami-id so the script can check whether the instance has already been updated.

rolling-replace and all the other ecs-utils scripts are documented in detail here: https://github.com/navapbc/ecs-utils/blob/master/README.md
