variable "alias" {
  description = "Alias padrão da conta. Nome do cliente"
  type        = string
}

variable "task_family" {
  description = "Família da definição de tarefa"
  type        = string
}

variable "task_cpu" {
  description = "CPU necessária para a tarefa"
  type        = string
}

variable "task_memory" {
  description = "Memória necessária para a tarefa"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN da role de execução da tarefa"
  type        = string
}

variable "container_name" {
  description = "Nome do container na definição de tarefa"
  type        = string
}

variable "container_image" {
  description = "Imagem do container"
  type        = string
}

variable "container_port" {
  description = "Porta do container"
  type        = number
}

variable "service_name" {
  description = "Nome do serviço ECS"
  type        = string
}

variable "cluster_id" {
  description = "ID do cluster ECS"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs de subnets para o serviço ECS"
  type        = list(string)
}

variable "desired_count" {
  description = "Número desejado de instâncias do serviço"
  type        = number
}

variable "vpc_id" {
  type = string
}

variable "alb_sg_id" {
  description = "ID do security group do ALB — ingress do ECS é restrito a ele"
  type        = string
}

variable "listener_arn" {
  type = string
}

variable "target_group_port" {
  description = "Porta do target group"
  type        = number
}

variable "aws_region" {
  description = "AWS region to launch servers."
  type        = string
  default     = "sa-east-1"
}

variable "app_dns" {
  description = "DNS do app."
  type        = string
}

variable "zone_id" {
  description = "Zona do Route53 para criação do CNAME automático."
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name do ALB."
  type        = string
}

variable "max_capacity" {
  description = "Capacidade máxima do autoscaling."
  type        = number
}

variable "mem_threshold" {
  description = "% de memória para acionar scale-out."
  type        = number
  default     = 80
}

variable "cpu_threshold" {
  description = "% de CPU para acionar scale-out."
  type        = number
  default     = 60
}

variable "health_check_path" {
  description = "Path HTTP para o health check do container (requer curl na imagem)."
  type        = string
  default     = "/"
}

# Variáveis de ambiente não-sensíveis injetadas no container.
# Para host, porta, nome do banco e outras configs sem segredo.
# Exemplo:
# container_environment = [
#   { name = "DATABASE_HOST", value = "meu-rds.sa-east-1.rds.amazonaws.com" },
#   { name = "DATABASE_DB",   value = "minha_base" }
# ]
variable "container_environment" {
  description = "Variáveis de ambiente não-sensíveis do container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# Segredos injetados via Secrets Manager ou SSM Parameter Store.
# O campo valueFrom recebe o ARN do secret (Secrets Manager) ou o nome
# do parâmetro com prefixo (SSM). O execution role já tem permissão para lê-los.
# Exemplo:
# container_secrets = [
#   { name = "DATABASE_PASSWORD", valueFrom = "arn:aws:secretsmanager:sa-east-1:123456789:secret:db-pass-AbCdEf" },
#   { name = "API_TOKEN",         valueFrom = "/myapp/prod/api-token" }
# ]
variable "container_secrets" {
  description = "Segredos injetados via Secrets Manager ou SSM Parameter Store"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default   = []
  sensitive = true
}
