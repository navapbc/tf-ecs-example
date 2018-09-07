# target group for our basic example app

locals {
  tg_name   = "${aws_alb_target_group.app.name}"
  tg_arn    = "${aws_alb_target_group.app.arn}"
  # Set to the port your docker container listens on.
  port      = 3000
  # url path your application health check listens on
  url_path  = "/"
}

resource "aws_alb_target_group" "app" {
  name                 = "${var.vpc_name}-basic-app"
  port                 = "${local.port}"
  protocol             = "HTTP"
  vpc_id               = "${module.aws_vpc.vpc_id}"
  deregistration_delay = 30        # 30s should be plenty of time to drain a task
  
  health_check {
    path     = "${local.url_path}"
    protocol = "HTTP"
  }
}

output "target_group_arn" {
  value = "${local.tg_arn}"
}

