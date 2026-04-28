variable "alias" {
  description = "Alias padrão da conta. Nome do cliente"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas onde os nodes serão provisionados"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs das subnets públicas incluídas na VPC config do cluster"
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes. Versões suportadas pelo EKS: 1.29, 1.30, 1.31, 1.32. Verifique em: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html"
  type        = string
  default     = "1.32"
}

variable "endpoint_public_access" {
  description = "Habilita acesso público ao endpoint da API do cluster"
  type        = bool
  default     = true
}

variable "node_instance_type" {
  description = "Tipo de instância EC2 dos nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_disk_size" {
  description = "Tamanho do disco dos nodes em GB"
  type        = number
  default     = 20
}

variable "node_desired_size" {
  description = "Número desejado de nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Número mínimo de nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Número máximo de nodes"
  type        = number
  default     = 4
}
