data "terraform_remote_state" "global" {
  backend = "s3"
  config = {
    bucket = "mock-g-cloud-8325"
    key    = "environments/global/terraform.tfstate"
    region = "us-west-2"
  }
}


data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


module "dev_deploy_role" {
  source = "../../modules/iam-role"
  oidc_provider_arn = data.terraform_remote_state.global.outputs.oidc_provider_arn
  repo_name = var.repo_name
  repo_owner = var.repo_owner
  state_bucket_name = var.state_bucket_name
  aws_region    = data.aws_region.current.id
  aws_account_id = data.aws_caller_identity.current.account_id
  deploy_role_name = var.deploy_role_name
  create_deploy_role = true
}