variable "efs_name" {
  description = "O nome do EFS"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde o ALB será criado"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets para o ALB"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "CIDR block para a VPC"
  default     = "100.120.0.0/16"
}
