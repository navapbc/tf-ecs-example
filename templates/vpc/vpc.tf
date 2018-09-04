# VPC, Load Balancer, Bastion host

# Create a VPC.
module "aws_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.vpc_name}"
  cidr = "${var.cidr}"

  azs              = "${var.azs}"
  private_subnets  = "${var.private_subnets}"
  public_subnets   = "${var.public_subnets}"
  database_subnets = "${var.database_subnets}"

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_vpn_gateway   = false
}

locals {
  bastion_cidr_block = "${module.aws_vpc.public_subnets_cidr_blocks[0]}"
  bastion_subnet_id  = "${module.aws_vpc.public_subnets[0]}"

  app_cidr_blocks = ["${module.aws_vpc.private_subnets_cidr_blocks[0]}",
    "${module.aws_vpc.private_subnets_cidr_blocks[1]}",
    "${module.aws_vpc.private_subnets_cidr_blocks[2]}",
  ]

  app_subnet_ids = ["${module.aws_vpc.private_subnets[0]}",
    "${module.aws_vpc.private_subnets[1]}",
    "${module.aws_vpc.private_subnets[2]}",
  ]
}

resource "aws_security_group" "bastion_sg" {
  name_prefix = "${var.vpc_name}-bastion-sg-"

  description = "security group for the bastion box"

  vpc_id = "${module.aws_vpc.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.bastion_cidr_blocks}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# TODO: to enable access using ssh-agent forwarding, add this to bastion
# userdata:
# sed -i 's/AllowAgentForwarding.*/AllowAgentForwarding yes/' /etc/ssh/sshd_config
# service sshd restart

# provision a bastion for the audit user
resource "aws_instance" "bastion" {
  # generic amazon linux instance
  ami                    = "ami-00129b193dc81bc31"
  iam_instance_profile   = "${aws_iam_instance_profile.generic_app_profile.id}"
  instance_type          = "t2.micro"
  subnet_id              = "${local.bastion_subnet_id}"
  key_name               = "${var.ec2_key_name}"
  # vpc_security_group_ids = ["1.2.3.4/32"]

  tags {
    Name = "${var.vpc_name}-bastion"
  }
}

resource "aws_eip" "bastion" {
  instance = "${aws_instance.bastion.id}"
  vpc      = true

  tags {
    Name = "${var.vpc_name}-bastion"
  }
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "${var.vpc_name}-alb-sg-"

  description = "security group for alb"

  vpc_id = "${module.aws_vpc.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.alb_cidr_blocks}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_alb" "alb" {
  lifecycle {
    # In a live production system, we would prevent this alb
    # from being destroyed since it causes changes for external
    # teams, however in the protoype we disabled this in order
    # to facilitate easier testing
    prevent_destroy = false
  }

  internal                         = false
  load_balancer_type               = "application"
  enable_cross_zone_load_balancing = true
  idle_timeout                     = "120"
  security_groups                  = ["${aws_security_group.alb_sg.id}"]

  name    = "${var.vpc_name}-alb"
  subnets = ["${module.aws_vpc.public_subnets}"]

  tags {
    Name = "${var.vpc_name}-alb"
  }
}

# for simplicity, just use HTTP
resource "aws_alb_listener" "web" {
  load_balancer_arn = "${aws_alb.alb.id}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.app.id}"
    type             = "forward"
  }
}
