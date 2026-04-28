variable "ec2_public_key" {
  description = "Chave pública SSH para as instâncias EC2"
  type        = string
  default     = ""
}

variable "alias" {
  description = "Alias padrão da conta. Nome do cliente"
  type        = string
  default     = "meu-ambiente"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  type        = string
  default     = "sa-east-1"
}

variable "vpc_name" {
  description = "Nome da VPC"
  type        = string
  default     = "vpc-meu-ambiente"
}

variable "domain" {
  description = "Domínio principal usado no ACM e nos registros DNS dos serviços"
  type        = string
  default     = "example.com"
}
