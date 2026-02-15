terraform {
  backend "s3" {
    bucket = "mock-g-cloud-8325"
    key    = "environment/dev/app/terraform.tfstate"
    region = "us-west-2"
    use_lockfile = true
  }

  required_providers  {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}



