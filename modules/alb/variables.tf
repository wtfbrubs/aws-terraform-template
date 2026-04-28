variable "alb_name" {
  description = "O nome do Application Load Balancer"
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

variable "cert_arn"{
  description = "Arn do certficiado validado para ser usado no listener 443 https"

}
