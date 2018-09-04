
output "alb_dns_name" {
  value = "${aws_alb.alb.dns_name}"
  description = "The dns name of the created alb"
}
