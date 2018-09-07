variable "docker_image" {
  description = "docker image to deploy"
}

# save the docker iamge as an output too
output "docker_image" {
  value = "${var.docker_image}"
}
