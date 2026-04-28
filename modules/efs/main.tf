resource "aws_efs_file_system" "my_efs" {
  creation_token = var.efs_name
  encrypted      = true
  throughput_mode = "elastic"

  
  tags = {
    Name = var.efs_name
  }
}


resource "aws_efs_mount_target" "efs_mt" {
  for_each         = toset(var.subnet_ids)
  file_system_id   = aws_efs_file_system.my_efs.id
  subnet_id        = each.value
  security_groups  = [aws_security_group.efs_sg.id] # Substitua var.efs_security_group pela variável ou valor do seu grupo de segurança
}

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Security Group para acesso ao EFS"
  vpc_id      = var.vpc_id  # Substitua var.vpc_id pelo ID da sua VPC

  ingress {
    from_port   = 2049  # Porta padrão para NFS
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]  # Substitua var.vpc_cidr pelo CIDR da sua VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Permite todo o tráfego de saída
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EFS Security Group"
  }
}


resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.my_efs.id

  backup_policy {
    status = "ENABLED"
  }
}