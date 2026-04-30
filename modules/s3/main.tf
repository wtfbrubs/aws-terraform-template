resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}


# resource "aws_s3_bucket_acl" "bucket_acl" {
#   bucket = aws_s3_bucket.bucket.id
#   acl    = "private"
# }


resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_access_block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_kms_key" "kmskey" {
  description             = format("Chave da bucket %s", var.bucket_name)
  deletion_window_in_days = 10
}

resource "aws_kms_alias" "kmskey" {
  name          = format("alias/s3-%s", var.bucket_name)
  target_key_id = aws_kms_key.kmskey.key_id
}



resource "aws_s3_bucket_server_side_encryption_configuration" "ss_enxryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.kmskey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_iam_policy" "full_access" {
  name        = format("FullAccessPolicy-s3-%s", var.bucket_name)
  description = "Política de acesso total a todos os recursos da bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "s3:*",
        Resource = [
          aws_s3_bucket.bucket.arn,
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_group" "full_access_group" {
  name = format("FullAccessGroup-s3-%s", var.bucket_name)
}

resource "aws_iam_group_policy_attachment" "full_access_attach" {
  group      = aws_iam_group.full_access_group.name
  policy_arn = aws_iam_policy.full_access.arn
}

resource "aws_iam_policy" "read_write" {
  name        = format("ReadWritePolicy-s3-%s", var.bucket_name)
  description = "Política de acesso de leitura e escrita da bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:ListBucket", "s3:GetObject", "s3:PutObject"],
        Resource = [
          aws_s3_bucket.bucket.arn,
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_group" "read_write_group" {
  name = format("ReadWriteGroup-s3-%s", var.bucket_name)
}

resource "aws_iam_group_policy_attachment" "read_write_attach" {
  group      = aws_iam_group.read_write_group.name
  policy_arn = aws_iam_policy.read_write.arn
}

resource "aws_iam_policy" "read_only" {
  name        = format("ReadOnlyPolicy-s3-%s", var.bucket_name)
  description = "Política de acesso de apenas leitura da bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = [
          aws_s3_bucket.bucket.arn,
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_group" "read_only_group" {
  name = format("ReadOnlyGroup-s3-%s", var.bucket_name)
}

resource "aws_iam_group_policy_attachment" "read_only_attach" {
  group      = aws_iam_group.read_only_group.name
  policy_arn = aws_iam_policy.read_only.arn
}