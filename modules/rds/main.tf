resource "aws_db_instance" "rds_db" {
  allocated_storage    = 20
  storage_type         = "gp3"
  engine               = "mysql"
  engine_version       = "8.0.33"
  instance_class       = "db.t3.micro"
  identifier           = var.rds_name
  username             = var.user_name
#   password             = var.user_pass // Use uma maneira segura para definir a senha
#   parameter_group_name = "default.mysql8.0"
  db_subnet_group_name = aws_db_subnet_group.db_sub_grp.id // Substitua pelo nome do seu DB Subnet Group
  vpc_security_group_ids = [aws_security_group.rds_sg.id] // Substitua pelo seu Security Group ID
  multi_az               = false
  backup_retention_period = 7
  backup_window           = "04:00-04:30"
  maintenance_window      = "Mon:00:00-Mon:03:00"
  auto_minor_version_upgrade = true
  deletion_protection       = true
  storage_encrypted         = true
  manage_master_user_password = true
  master_user_secret_kms_key_id = aws_kms_key.db_kms.key_id
  # Configurações de monitoramento e logs
  monitoring_interval    = 60
  monitoring_role_arn    = aws_iam_role.rds_monitoring_role.arn // Substitua pelo ARN da sua IAM role
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  skip_final_snapshot = true
  apply_immediately = true

  # Configuração de rede
  publicly_accessible = false

  # Configuração de autoscaling
  max_allocated_storage = 100
}



resource "aws_kms_key" "db_kms" {
  description = "kms key para o recurso"
}

resource "aws_db_subnet_group" "db_sub_grp" {
  name       = var.rds_name
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "rds_sg" {
  vpc_id      = var.vpc_id
  name = format("%s-rds-sg", var.rds_name)
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_iam_role" "rds_monitoring_role" {
  name = format("%s-monitoring-role", var.rds_name)
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = aws_iam_policy.monitoring_policy.arn
}

resource "aws_iam_policy" "monitoring_policy" {
  name        = format("%s-em-policy", var.rds_name)
  path        = "/"
  description = "Politica de Enhanced Monitoring para instancia rds"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogGroups",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:PutRetentionPolicy"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:RDS*"
            ]
        },
        {
            "Sid": "EnableCreationAndManagementOfRDSCloudwatchLogStreams",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams",
                "logs:GetLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:*:*:log-group:RDS*:log-stream:*"
            ]
        }
    ]
  })
}