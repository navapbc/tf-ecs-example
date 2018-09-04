variable "vpc_name" {
  description = "name for the vpc and prefix for other resources"
}

variable "region" {
  description = "AWS region"
}

variable "docker_image" {
  description = "url for the docker image to use"
}

variable "cluster" {
  description = "ecs cluster for your service"
}

variable "desired_count" {
  description = "desired number of tasks to run"
  default     = "1"
}

variable "target_group_arn" {
  description = "load balancing target for your service"
}

variable "container_port" {
  description = "Port that this container listens on. If you change this from default, you must supply a new healthcheck"
  default = "3000"
}

variable "health_check" {
  description = "Health check to determine if a spawned task is operational."
  default = "wget --quiet http://localhost:3000 || exit 1"
}

variable "app_name" {
  description = "Name of this application, this must be unique within a platform"
  default = "basic-app"
}
