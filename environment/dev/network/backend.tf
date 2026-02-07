terraform {
  backend "s3" {
    bucket         = "mock-g-cloud-8325"
    key            = "environment/dev/network/terraform.tfstate"
    region         = "us-west-2"
    use_lockfile = true
  }
}