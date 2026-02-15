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

module "app" {
  source = "../../../modules/application"
  alb_sg_id = ""
  ami_id = ""
  aws_iam_instance_profile_name = ""
  aws_region = ""
  db_endpoint = ""
  db_secret_arn = ""
  db_security_group_id = ""
  db_sg_id = ""
  private_subnet_ids = []
  project_name = ""
  public_subnet_ids = []
  vpc_cidr = ""
  vpc_id = ""
}