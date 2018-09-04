# We create an IAM instance profile for our cluster instances.
# If you have multiple clusters, you may choose to create
# additional instance profiles to restrict them.
resource "aws_iam_role" "generic_app" {
  name_prefix = "${var.vpc_name}-app-"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "template_file" "app_server_policy" {
  # Allow logs for cloudwatch
  # Allow ecs & ecr access as per https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
  # and https://docs.aws.amazon.com/AmazonECS/latest/developerguide/instance_IAM_role.html
  # Allow ec2 describe instances so that the instance can see its own metadata if needed
  # 
  # Allow containers to access the AWS SSM params scoped to this VPC
  # https://aws.amazon.com/blogs/mt/the-right-way-to-store-secrets-using-parameter-store/
  # TODO: kms access should be limited to the KMS key used for this VPC's parameter
  template = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
        "Resource": [
          "arn:aws:logs:*:*:*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe",
        "ec2:DescribeInstances",
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:StartTask",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": [
        "arn:aws:ssm:*:*:parameter/${var.vpc_name}/*"
      ]
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
         "kms:ListKeys",
         "kms:ListAliases",
         "kms:Describe*",
         "kms:Decrypt"
      ],
      "Resource": "*"
}
  ]
}
EOF
}

resource "aws_iam_role_policy" "generic_app" {
  name_prefix = "${var.vpc_name}-app-policy-"
  role        = "${aws_iam_role.generic_app.id}"
  policy      = "${data.template_file.app_server_policy.rendered}"
}

resource "aws_iam_instance_profile" "generic_app_profile" {
  name_prefix = "${var.vpc_name}-app-profile-"
  role        = "${aws_iam_role.generic_app.name}"
}
