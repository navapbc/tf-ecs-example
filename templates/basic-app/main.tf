locals {
  # this is the namespace for the ssm param system
  # used by the app to fetch params at startup, see scripts/param.py
  app_name = "${var.vpc_name}-${var.app_name}"
}

resource "aws_ecs_service" "service" {
  name                = "${local.app_name}"
  cluster             = "${var.cluster}"
  desired_count       = "${var.desired_count}"
  task_definition     = "${aws_ecs_task_definition.app.arn}"
  scheduling_strategy = "REPLICA"

  # 50 percent must be healthy during deploys
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = "${var.target_group_arn}"
    container_name   = "${local.app_name}"
    container_port   = "${var.container_port}"
  }
}

data "template_file" "task_definition" {
  template = "${file("${path.module}/ecs-tasks/app.json")}"

  vars {
    docker_image_url = "${var.docker_image}"
    container_name   = "${local.app_name}"
    aws_region       = "${var.region}"
    ssm_path         = "/${var.vpc_name}/${local.app_name}"
    container_port   = "${var.container_port}"
    health_check     = "${var.health_check}"
  }
}

resource "aws_ecs_task_definition" "app" {
  family                = "${local.app_name}"
  container_definitions = "${data.template_file.task_definition.rendered}"
}
