data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.create_oidc_provider ? 1 : 0 # Create only if variable is true
  client_id_list = ["sts.amazonaws.com", ]
  url = "https://token.actions.githubusercontent.com"
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

#-------------------GITHUB ASSUME ROLE--------------------------#
data "aws_iam_policy_document" "github_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [var.create_oidc_provider ? aws_iam_openid_connect_provider.github_actions[0].arn : var.oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = ["repo:Reticent93/mock_g_cloud*"]
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
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
        ]
        Resource = ["arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/tflock-lock-table"]
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
  max_session_duration = 3600 # 1 hour which is the default

}

resource "aws_iam_role_policy_attachment" "flow_logs_iam_role_attachment" {
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
        Resource = "${aws_cloudwatch_log_group.vpc_flow_log.arn}:*"
      }
    ]
  })
}


#-------------------EC2 ROLE--------------------------#
resource "aws_iam_role" "app_role" {
  name = "${var.project_name}-app-role"
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
  count = var.db_resource_id != null ? 1 : 0
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
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:rds!db-*"
      }]
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name = "${var.project_name}-flow-logs"
  kms_key_id = aws_kms_key.first_key.arn
  retention_in_days = 365

}

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {Service = "monitoring.rds.amazonaws.com"}

    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attachment" {
  role = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"

}

resource "aws_kms_key" "first_key" {
  description = "KEY for Cloudwatch Flow Logs"
  enable_key_rotation = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      Action = "kms:*",
      Resource = "*"
    },
      {
        Sid = "Allow Github Actions to use key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.github_deploy_role[0].name}"
        },
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ],
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        },
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ],
        Resource = "*",
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        },
      },
    ],
  })
}

