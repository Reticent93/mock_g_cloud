terraform {
  backend "s3" {
    bucket = "mock-g-cloud-8325"
    key = "environment/dev/base/terraform.tfstate"
    region = "us-west-2"
    encrypt = true
    use_lockfile = true
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
