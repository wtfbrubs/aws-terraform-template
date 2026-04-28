
resource "aws_key_pair" "key" {
  key_name   = format("kp-%s", var.instance_name)
  public_key = var.public_key
}




resource "aws_security_group" "ec2_sg" {
  name        = format("%s-ec2-sg", var.instance_name)
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Portas abertas configuradas via variável ingress_ports (padrão: 22, 80, 443).
  # Sobrescreva ao instanciar o módulo para abrir apenas o necessário.
  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.ingress_cidrs
    }
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
    encrypted = true
    volume_size = var.root_volume_size
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
  encrypted = true
  tags = {
    Name = format("%s-ebs-1", var.instance_name)
  }
}

resource "aws_volume_attachment" "volume1_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.volume1.id
  instance_id = aws_instance.ec2.id
}