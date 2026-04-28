resource "aws_cloudtrail" "cloudtrail-auditoria" {
  depends_on = [aws_s3_bucket_policy.cloudtrail-auditoria]

  name                          = "cloudtrail-auditoria"
  s3_bucket_name                = aws_s3_bucket.cloudtrail-auditoria.id
  s3_key_prefix                 = "CLIENTE"
  include_global_service_events = true
}

resource "aws_s3_bucket" "cloudtrail-auditoria" {
  bucket        = "CLIENTE-cloudtrail"
  force_destroy = true
}

data "aws_iam_policy_document" "cloudtrail-auditoria" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail-auditoria.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/cloudtrail-auditoria"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail-auditoria.arn}/CLIENTE/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/cloudtrail-auditoria"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail-auditoria" {
  bucket = aws_s3_bucket.cloudtrail-auditoria.id
  policy = data.aws_iam_policy_document.cloudtrail-auditoria.json
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}