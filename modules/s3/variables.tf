variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "sa-east-1"
}

variable "vpc_name" {
  description = "nome da VPC"
  default     = "vpc-gasfacil"
}

variable "alias" {
  description = "Alias padrão da conta. Nome do cliente"
  default = "gasfacil"
}


variable "bucket_name" {
  description = "Nome da bucket"
}
