terraform {
  backend "s3" {
    bucket = "mock-g-cloud-8325"
    key    = "environment/dev/app/terraform.tfstate"
    region = "us-west-2"
    use_lockfile = true
  }
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "mock-g-cloud-8325"
    key    = "environment/dev/network/terraform.tfstate"
    region = "us-west-2"
  }
}

data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = "mock-g-cloud-8325"
    key    = "environment/dev/base/terraform.tfstate"
    region = "us-west-2"
  }
}