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
data "aws_availability_zones" "available" {state = "available"}


module "dev_iam" {
  source                   = "../../modules/iam-role"
  oidc_provider_arn        = data.terraform_remote_state.global.outputs.oidc_provider_arn
  repo_name                = var.repo_name
  repo_owner               = var.repo_owner
  state_bucket_name        = var.state_bucket_name
  aws_region               = data.aws_region.current.id
  aws_account_id           = data.aws_caller_identity.current.account_id
  deploy_role_name         = var.deploy_role_name
  create_deploy_role       = true
  project_name             = var.project_name
  aws_cloudwatch_log_group = var.aws_cloudwatch_log_group
  db_resource_id           = var.db_resource_id
}


module "dev_vpc" {
  source                 = "../../modules/vpc"
  project_name           = var.project_name
  flow_log_retention     = var.flow_log_retention
  flow_log_role_arn      = module.dev_iam.flow_log_role_arn
  vpc_cidr               = var.vpc_cidr
  aws_availability_zones = data.aws_availability_zones.available.names
  name_suffix            = var.name_suffix
  key_deletion_window    = 30
  app_sg                = var.app_sg_id
}

module "dev_apps" {
  source = "../../modules/app"
  project_name = var.project_name
  alb_sg_id = module.dev_vpc.alb_sg_id
  private_subnet_ids = module.dev_vpc.private_subnet_ids
  public_subnet_ids = module.dev_vpc.public_subnet_ids
  vpc_id = module.dev_vpc.vpc_id
  db_sg_id = var.db_sg_id
  vpc_cidr = var.vpc_cidr
  aws_iam_instance_profile_name = var.aws_iam_instance_profile_name
  db_endpoint = module.dev_db.db_endpoint
}

module "dev_db" {
  source = "../../modules/db"
  apps_sg_id   = module.dev_apps.app_sg_id
  private_subnet_ids = module.dev_vpc.private_subnet_ids
  project_name = var.project_name
  vpc_id       = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_apps" {
  description = "Allows LB to send traffic to App"
  from_port        = 80
  to_port          = 80
  ip_protocol       = "tcp"
  security_group_id = module.dev_vpc.alb_sg_id
  referenced_security_group_id = module.dev_apps.app_sg_id
}