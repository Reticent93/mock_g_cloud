

module "base" {
  source            = "../../../modules/base"
  project_name      = var.project_name
  aws_region        = var.aws_region
  state_bucket_name = var.state_bucket_name
  create_oidc_provider = var.create_oidc_provider
  create_deploy_role = var.create_deploy_role
  deploy_role_name = var.deploy_role_name

  db_user = var.db_user
  db_resource_id = var.db_resource_id
  aws_account_id = var.aws_account_id
  aws_cloudwatch_log_group = var.aws_cloudwatch_log_group
  oidc_provider_arn = var.oidc_provider_arn
}

import {
  id = "GitHub_Actions_Deploy_Role_DEV"
  to = module.base.aws_iam_role.github_deploy_role[0]
}

import {
  id = "arn:aws:iam::${var.aws_account_id}:policy/Github-TF-State_Access-Policy-GitHub_Actions_Deploy_Role_DEV"
  to = module.base.aws_iam_policy.tf_state_access_policy
}

import {
  id = "mock-g-cloud-app-role"
  to = module.base.aws_iam_role.app_role
}

import {
  id = "mock-g-cloud-flow-logs-role"
  to = module.base.aws_iam_role.vpc_flow_log_role
}

import {
  id = "mock-g-cloud-app-profile"
  to = module.base.aws_iam_instance_profile.app_profile
}