
resource "aws_key_pair" "key" {
  key_name   = format("kp-%s", var.instance_name)
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDicBAmfnkLskp2+fBRc12tNJeIe7nejlRc80Euvg5kHHaydxguELQXodB7D0I7Gv2hubRxENREpl+OkA89hUMuxtq1hX+48mf2I8gDldUjmnp9u4OgSiTV1gHhLDViVezB1UNcnIm8a1R3oiVq+2AirIh8ucnMt2OdOp0nwyns8KotyE00v9VNOPwuNB0MbM1WnlTIASQgLhPBL383lekR4ooFHBlJ8Q+FrY1HcvH5XQk5WUBP1rGGenTmuOgjIsXdSvoDOVYkWPwsZH2g6JLsMQZZUZw4GhGk77gvbZ5c2fWS3J629QPtpfVOhIpkENVFWbY02H6vNer/W5gBksY/ gasfacil-sandbox-2023-12-05"
}




resource "aws_security_group" "ec2_sg" {
  name        = format("%s-ec2-sg", var.instance_name)
  description = "Security group for EC2 instance"
  vpc_id      = var.vpc_id

  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
  }

  ingress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port = "0"
    to_port = "0"
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