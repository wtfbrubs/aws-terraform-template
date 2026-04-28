
variable "rds_name" {
  description = "nome da database"
  default     = "rds-database"
}

variable "user_name" {
  description = "nome do usuário master"
  default     = "admin"
}

variable "user_pass" {
  description = "password do usuário master"
  default     = "@12345a"
}

variable "private_subnet_ids" {
  description = "lista das subnets do subnet group"
}

variable "vpc_id" {
  type        = string
}