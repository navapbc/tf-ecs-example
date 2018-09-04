# We have one ECS cluster that instances will register with
resource "aws_ecs_cluster" "cluster" {
  name = "${var.vpc_name}-cluster-a"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user_data.tpl")}"

  vars {
    cluster_name = "${aws_ecs_cluster.cluster.name}"
  }
}

resource "aws_security_group" "app_sg" {
  name_prefix = "${var.vpc_name}-app-sg-"

  description = "security group for the application boxes"

  vpc_id = "${module.aws_vpc.vpc_id}"

  # In order to allow flexible allocation of tasks to instances
  # ECS must be allowed to dynamically assign ports.
  # Static ports can be used for an ECS service but then
  # it is limited to one of its tasks on each instance.
  ingress {
    from_port       = 32768
    to_port         = 61000
    protocol        = "tcp"
    security_groups = ["${aws_security_group.alb_sg.id}"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${local.bastion_cidr_block}"]
  }

  # NOTE: if you choose to lock down outgoing, ensure that
  # any external dependencies including the ECS agent are
  # permitted.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "service" {
  lifecycle {
    create_before_destroy = true
  }

  desired_capacity     = "${var.asg_size}"
  launch_configuration = "${aws_launch_configuration.service.name}"
  health_check_type    = "EC2"
  max_size             = "${var.asg_size}"
  min_size             = "${var.asg_size}"
  name                 = "${var.vpc_name}-asg-a"
  vpc_zone_identifier  = ["${local.app_subnet_ids}"]

  tag {
    key                 = "Name"
    value               = "${var.vpc_name}-asg-a"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "service" {
  lifecycle {
    create_before_destroy = true
  }

  enable_monitoring    = false
  iam_instance_profile = "${aws_iam_instance_profile.generic_app_profile.id}"

  # this is the official aws provided ami for ecs
  # taken from https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_container_instance.html
  image_id = "ami-00129b193dc81bc31"

  instance_type = "t2.small"
  key_name      = "${var.ec2_key_name}"
  name_prefix   = "${var.vpc_name}-lc-a"

  user_data = "${data.template_file.user_data.rendered}"

  security_groups = ["${aws_security_group.app_sg.id}"]

  # IMPORTANT: updating this resource (with a new image_id) does not implement
  # the change, you must follow the update with an orchestration.
  # This could be a follow on step in your CI, or using local-exec here e.g.

  # provisioner "local-exec" {
  #   # see: github.com/navapbc/ecs-utils rolling-restart
  #   command = "rolling-restart --cluster-name ${aws_ecs_cluster.cluster.name} --region ${var.region} --ami-id ${aws_launch_configuration.service.image_id}"
  # }
}
