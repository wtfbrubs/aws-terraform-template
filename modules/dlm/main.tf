data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "dlm_lifecycle_role" {
  name               = "dlm-lifecycle-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "dlm_lifecycle" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*::snapshot/*"]
  }
  
}

resource "aws_iam_role_policy" "dlm_lifecycle" {
  name   = "dlm-lifecycle-policy"
  role   = aws_iam_role.dlm_lifecycle_role.id
  policy = data.aws_iam_policy_document.dlm_lifecycle.json
}

resource "aws_dlm_lifecycle_policy" "diario14" {
  description        = "politica de snapshots diarios"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "14 snapshots diarios"

      create_rule {
        cron_expression = "cron(0 3 * * ? *)"
      }

      retain_rule {
        count = 14
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = false
    }

    target_tags = {
      Snapshot_diario = "true"
    }
  }
  tags = {
    Name = "Diario14"
  }
}

resource "aws_dlm_lifecycle_policy" "semanal4" {
  description        = "politica de snapshots semanais"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "4 snapshots semanais"

      create_rule {
        cron_expression = "cron(0 3 ? * 2 *)"
      }

      retain_rule {
        count = 4
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = false
    }

    target_tags = {
      Snapshot_semanal = "true"
    }
  }
  tags = {
    Name = "Semanal4"
  }
}

resource "aws_dlm_lifecycle_policy" "mensal12" {
  description        = "politica de snapshots mensais"
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "4 snapshots semanais"

      create_rule {
        cron_expression = "cron(0 3 1 * ? *)"
      }

      retain_rule {
        count = 12
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = false
    }

    target_tags = {
      Snapshot_mensal = "true"
    }
  }
  tags = {
    Name = "Mensal12"
  }
}cp