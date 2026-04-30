variable "efs_name" {
  description = "O nome do EFS"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde o EFS será criado"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets para os mount targets"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "CIDR block da VPC — restringe o security group do EFS ao tráfego interno"
  type        = string
  default     = "100.120.0.0/16"
}
