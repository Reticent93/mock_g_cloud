data "terraform_remote_state" "base" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "environment/dev/base/terraform.tfstate"
    region = var.aws_region
  }
}

module "network" {
  source = "../../../modules/network"
  flow_log_retention = 0
  flow_log_role_arn = data.terraform_remote_state.base.outputs.vpc_flow_log_role_arn
  key_deletion_window = 7
  project_name = var.project_name
  vpc_cidr = var.vpc_cidr

}
