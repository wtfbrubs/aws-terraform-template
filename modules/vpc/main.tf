resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
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

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]

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

# Um EIP e um NAT Gateway por AZ pública — evita perda de saída de internet
# nas subnets privadas caso uma AZ fique indisponível.
resource "aws_eip" "nat_eip" {
  count      = length(var.public_subnet_cidr_blocks)
  depends_on = [aws_internet_gateway.igw]
  domain     = "vpc"

  tags = {
    Name = format("%s-nat-eip-%02d", var.vpc_name, count.index + 1)
  }
}

resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.public_subnet_cidr_blocks)
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = format("%s-nat-gw-%02d", var.vpc_name, count.index + 1)
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

# Uma route table por subnet privada, cada uma apontando para o NAT da mesma AZ.
# Se houver mais subnets privadas que NATs, distribui em round-robin.
resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidr_blocks)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index % length(aws_nat_gateway.nat_gw)].id
  }

  tags = {
    Name = format("%s-private-%02d", var.vpc_name, count.index + 1)
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr_blocks)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
