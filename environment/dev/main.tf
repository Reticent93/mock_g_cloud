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
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

module "dev_iam" {
  source                   = "../../modules/iam-role"
  project_name             = var.project_name
  oidc_provider_arn        = data.terraform_remote_state.global.outputs.oidc_provider_arn
  repo_name                = var.repo_name
  repo_owner               = var.repo_owner
  state_bucket_name        = var.state_bucket_name
  aws_region               = data.aws_region.current.id
  aws_account_id           = data.aws_caller_identity.current.account_id
  deploy_role_name         = "GitHub_Actions_Deploy_Role_DEV"
  create_deploy_role       = true
  aws_cloudwatch_log_group = module.dev_vpc.flow_log_group_arn
  db_resource_id           = module.dev_db.db_resource_id
  db_password_secret_arn   = module.dev_db.db_password_secret_arn
}


module "dev_vpc" {
  source                 = "../../modules/vpc"
  project_name           = var.project_name
  flow_log_retention     = var.flow_log_retention
  flow_log_role_arn      = module.dev_iam.flow_log_role_arn
  vpc_cidr               = var.vpc_cidr
  aws_availability_zones = data.aws_availability_zones.available.names
  app_sg                 = module.dev_apps.app_sg_id
  key_deletion_window    = 30
  name_suffix            = "dev"
}

module "dev_apps" {
  source = "../../modules/application"
  project_name = var.project_name
  aws_region = var.aws_region
  alb_sg_id = module.dev_vpc.alb_sg_id
  private_subnet_ids = module.dev_vpc.private_subnet_ids
  public_subnet_ids = module.dev_vpc.public_subnet_ids
  vpc_id = module.dev_vpc.vpc_id
  vpc_cidr = module.dev_vpc.vpc_cidr
  aws_iam_instance_profile_name = module.dev_iam.aws_instance_profile_name
  db_endpoint = module.dev_db.db_endpoint
  db_sg_id = module.dev_db.db_resource_id
  ami_id = data.aws_ami.amazon_linux.id
  db_secret_arn = module.dev_db.db_password_secret_arn
}

module "dev_db" {
  source = "../../modules/db"
  apps_sg_id   = module.dev_apps.app_sg_id
  private_subnet_ids = module.dev_vpc.private_subnet_ids
  project_name = var.project_name
  vpc_id       = module.dev_vpc.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_apps" {
  description = "Allows LB to send traffic to App"
  from_port        = 80
  to_port          = 80
  ip_protocol       = "tcp"
  security_group_id = module.dev_vpc.alb_sg_id
  referenced_security_group_id = module.dev_apps.app_sg_id
}


moved {
  from = module.dev_deploy_role.aws_iam_role.github_deploy_role[0]
  to   = module.dev_iam.aws_iam_role.github_deploy_role[0]
}

moved {
  from = module.dev_deploy_role.aws_iam_policy.tf_state_access_policy
  to   = module.dev_iam.aws_iam_policy.tf_state_access_policy
}

moved {
  from = module.dev_deploy_role.aws_iam_role_policy_attachment.github_deploy_state_access[0]
  to   = module.dev_iam.aws_iam_role_policy_attachment.github_deploy_state_access[0]
}