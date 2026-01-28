resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.create_oidc_provider ? 1 : 0 # Create only if variable is true
  client_id_list = ["sts.amazonaws.com", ]
  url = "https://token.actions.githubusercontent.com"
}

#-------------------GITHUB ASSUME ROLE--------------------------#
data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      values = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test     = "StringLike"
      values = ["repo:${var.repo_owner}/${var.repo_name}:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}


#-------------------GITHUB DEPLOY ROLE--------------------------#
resource "aws_iam_role" "github_deploy_role" {
  count = var.create_deploy_role ? 1 : 0
  name               = var.deploy_role_name
  assume_role_policy = data.aws_iam_policy_document.github_assume_role.json
  max_session_duration = 3600 // 1 hour which is the default
}

resource "aws_iam_role_policy_attachment" "github_deploy_state_access" {
  count = var.create_deploy_role ? 1 : 0
  role = aws_iam_role.github_deploy_role[0].name
  policy_arn = aws_iam_policy.tf_state_access_policy.arn

}

resource "aws_iam_policy" "tf_state_access_policy" {
  name = "Github-TF-State_Access-Policy-${var.deploy_role_name}"
  description = "Minimal permissions for Github Actions to manage Terraform state file"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "S3StateAccess"
        Effect = "Allow"
        Action = [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket_name}",
          "arn:aws:s3:::${var.state_bucket_name}/*"
        ]
      },
      {
        Sid = "DynamoDBLocking"
        Effect = "Allow"
        Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
        ]
        Resource = [ "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/tflock-lock-table "]
      }
    ]
  })
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name               = "${var.project_name}-flow-logs-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
  max_session_duration = 3600 // 1 hour which is the default

}

resource "aws_iam_role_policy_attachment" "flow_logs_iam_role_attachment" {
  count = var.create_deploy_role ? 1 : 0
  role = aws_iam_role.vpc_flow_log_role.name
  policy_arn = aws_iam_policy.flow_log_policy.arn
}

resource "aws_iam_policy" "flow_log_policy" {
  name = "${var.project_name}-flow-log-to-cloudwatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "FlowLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ]
        Resource = var.aws_cloudwatch_log_group
      }
    ]
  })
}


#-------------------EC2 ROLE--------------------------#
resource "aws_iam_role" "app_role" {
  name = "${var.project_name}app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }]
  })
}

resource "aws_iam_policy" "rds_connect_policy" {
  description = "Allows EC2 connect to my Postgres RDS using IAM"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "rds-db:connect"
        Resource = "arn:aws:rds-db:${var.aws_region}:${var.aws_account_id}:dbuser:${var.db_resource_id}/${var.db_user}"
      }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_policy_attach" {
  role = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.rds_connect_policy.arn
}

resource "aws_iam_instance_profile" "app_profile" {
  name = "${var.project_name}-app-profile"
  role = aws_iam_role.app_role.name
}

resource "aws_iam_role_policy" "secrets_read" {
  name = "${var.project_name}-secrets-read"
  role = aws_iam_role.app_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "secretsmanager:GetSecretValue"
        Resource = var.db_password_secret_arn
      }]
  })
}


