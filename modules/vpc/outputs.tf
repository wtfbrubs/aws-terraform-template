output "private_subnets_ids" {
  value = aws_subnet.private.*.id
}

output "public_subnets_ids" {
  value = aws_subnet.public.*.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr_block" {
  value = aws_vpc.main.cidr_block
}