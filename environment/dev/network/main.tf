

module "network" {
  source = "../../../modules/network"
  flow_log_retention = 0
  flow_log_role_arn = ""
  key_deletion_window = 7
  project_name = var.project_name
  vpc_cidr = var.vpc_cidr

}