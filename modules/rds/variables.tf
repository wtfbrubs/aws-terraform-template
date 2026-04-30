variable "rds_name" {
  description = "Nome da instância RDS"
  type        = string
  default     = "rds-database"
}

variable "user_name" {
  description = "Nome do usuário master"
  type        = string
  default     = "admin"
}

# user_pass removido — o módulo usa manage_master_user_password = true,
# que delega a criação e rotação da senha ao Secrets Manager automaticamente.
# Não é necessário (nem recomendado) gerenciar a senha pelo Terraform.

variable "private_subnet_ids" {
  description = "Lista de IDs das subnets privadas para o subnet group"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

# Usado para restringir o security group do RDS ao tráfego interno da VPC.
# Recebe o output vpc_cidr_block do módulo vpc.
variable "vpc_cidr_block" {
  description = "CIDR da VPC — apenas este bloco terá acesso à porta 3306"
  type        = string
}
