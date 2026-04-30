
# Busca o ID da conta AWS atual dinamicamente.
# Evita hardcodar account IDs no código, o que causaria falhas ao usar
# o template em contas diferentes.
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "basic_role" {
  name = "BasicAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        },
        Action = "sts:AssumeRole",
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "basic_policy" {
  name = "BasicAccessPolicy"
  role = aws_iam_role.basic_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:Describe*",
          "s3:Get*",
          "s3:List*"
        ],
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "admin_role" {
  name = "FullAdminAccessRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = data.aws_caller_identity.current.account_id
        },
        Action = "sts:AssumeRole",
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "admin_policy" {
  name = "FullAdminAccessPolicy"
  role = aws_iam_role.admin_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "*",
        Resource = "*"
      },
    ]
  })
}

resource "aws_accessanalyzer_analyzer" "analyzer" {
  analyzer_name = "analyzer"
}

resource "aws_iam_account_alias" "alias" {
  account_alias = var.alias

}


resource "aws_iam_group_policy_attachment" "attach-grupo-dev-power-user" {
  group      = aws_iam_group.dev-power-users.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitPowerUser"
}


resource "aws_iam_group" "dev-power-users" {
  name = "dev-power-users"
}