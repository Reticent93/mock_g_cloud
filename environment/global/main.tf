data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "global_iam" {
  source = "../../modules/iam-role"

  create_oidc_provider = true
  create_deploy_role = false

  repo_name         = var.repo_name
  repo_owner        = var.repo_owner
  oidc_provider_arn = var.oidc_provider_arn
  state_bucket_name = var.state_bucket_name
  aws_region    = data.aws_region.current.name
  aws_account_id = data.aws_caller_identity.current.account_id
}