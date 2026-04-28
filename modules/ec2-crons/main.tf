

resource "aws_key_pair" "key" {
  key_name   = format("kp-%s", var.instance_name)
  public_key = var.public_key
}





resource "aws_security_group" "ec2_sg" {
  name        = format("%s-ec2-sg", var.instance_name)
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id

  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  # Ingress rule for TCP port 22 (SSH)
  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
  }

  # Ingress rule for TCP port 443 (HTTPS)
  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    to_port     = 443
  }

  # Ingress rule for TCP port 80 (HTTP)
  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
  }

  # Ingress rule for TCP port 1194 (Used for OpenVPN)
  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 1194
    to_port     = 1194
  }

  # Ingress rule for all UDP ports
  ingress {
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 19409
    to_port     = 19409
  }
}


resource "aws_instance" "ec2" {
  depends_on=[aws_key_pair.key, aws_security_group.ec2_sg ]
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.key.id
  
  subnet_id              = var.subnet_id
  associate_public_ip_address = var.associate_public_ip

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted = true
    kms_key_id = aws_kms_key.kms_key.arn
  }

  tags = {
    Name = var.instance_name
  }
}

resource "aws_eip" "ec2_eip" {

  instance = var.use_elastic_ip ? aws_instance.ec2.id : null
  tags = {
    Name = format("%s-eip", var.instance_name)
  }
}

resource "aws_ebs_volume" "volume1" {
  depends_on=[aws_instance.ec2 ]
  availability_zone = aws_instance.ec2.availability_zone
  size              = 40
  type = "gp3"
  encrypted = true
  kms_key_id = aws_kms_key.kms_key.arn
  tags = {
    Name = format("%s-ebs-1", var.instance_name)
  }
}

resource "aws_volume_attachment" "volume1_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.volume1.id
  instance_id = aws_instance.ec2.id
}

resource "aws_kms_key" "kms_key" {
  description             = var.instance_name
  deletion_window_in_days = 10
}