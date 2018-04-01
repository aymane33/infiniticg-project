terraform {
 required_version = ">= 0.10.6"
}

provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
  version = "~> 1.0"
  shared_credentials_file = "./credentials"
}
