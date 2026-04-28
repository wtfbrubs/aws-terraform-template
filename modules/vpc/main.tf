# provider "aws" {
#   region = var.region
# }

resource "aws_vpc" "main" {
  cidr_block          = var.vpc_cidr_block
  enable_dns_support  = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = format("%s-public-%02d", var.vpc_name, count.index + 1)
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnet_cidr_blocks[count.index]
  availability_zone       = var.availability_zones[count.index]

  tags = {
    Name = format("%s-private-%02d", var.vpc_name, count.index + 1)
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = format("%s-igw", var.vpc_name)
  }
}

resource "aws_eip" "nat_eip" {
  depends_on = [aws_internet_gateway.igw]
  domain   = "vpc"

  tags = {
    Name = format("%s-nat-eip", var.vpc_name)
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = format("%s-nat-gw", var.vpc_name)
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = format("%s-public", var.vpc_name)
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = format("%s-private", var.vpc_name)
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}




resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = format("%s-public", var.vpc_name)
  }
}

resource "aws_network_acl_rule" "public_inbound" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  # protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  # from_port      = 22
  # to_port        = 22
}

resource "aws_network_acl_rule" "public_outbound" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_association" "public" {
  count          = length(var.public_subnet_cidr_blocks)
  network_acl_id = aws_network_acl.public.id
  subnet_id      = aws_subnet.public[count.index].id
}



resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = format("%s-private", var.vpc_name)
  }
}

resource "aws_network_acl_rule" "private_inbound" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  # protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  # from_port      = 22
  # to_port        = 22
}

resource "aws_network_acl_rule" "private_outbound" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_association" "private" {
  count          = length(var.private_subnet_cidr_blocks)
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private[count.index].id
}


