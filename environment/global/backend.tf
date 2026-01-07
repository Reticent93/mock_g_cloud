terraform {
  backend "s3" {
    bucket = "mock-g-cloud-8325"
    key    = "environments/global/terraform.tfstate"
    region = "us-west-2"
    dynamodb_table = "tflock-lock-table"
  }
}