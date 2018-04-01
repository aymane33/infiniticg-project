variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}
variable "aws_profile" {
  description = "AWS Profile to launch servers."
}
variable "sshKey" {
  type = "string"
}
variable "ec2AMI" {}
variable "cidr" {}
variable "private-subnet-list-ids" { type = "list" }
variable "public-subnet-list-ids" { type = "list" }
variable "vpc-id" {}
