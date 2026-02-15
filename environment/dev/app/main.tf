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

  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  alb_sg_id = data.terraform_remote_state.network.outputs.alb_security_group_id
  ami_id = ""
  aws_iam_instance_profile_name = data.terraform_remote_state.base.outputs.iam_instance_profile
  aws_region = var.aws_region
  db_endpoint = data.terraform_remote_state.network.outputs.db_endpoint
  db_secret_arn = data.terraform_remote_state.network.outputs.db_password_secret_arn
  db_security_group_id = data.terraform_remote_state.network.outputs.db_security_group_id
  db_sg_id = data.terraform_remote_state.network.outputs.db_security_group_id
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  project_name = var.project_name
  public_subnet_ids = data.terraform_remote_state.network.outputs.public_subnet_ids
  vpc_cidr = data.terraform_remote_state.network.outputs.vpc_cidr
}