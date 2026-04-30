variable "repo_name" {
  description = "Nome do repositório CodeCommit"
  type        = string
}

variable "alias" {
  description = "Alias da conta"
  type        = string
}

variable "pipeline_branch" {
  description = "Branch que dispara o pipeline de deploy"
  type        = string
  default     = "master"
}

variable "codecommit_repo_arn" {
  description = "ARN do repositório CodeCommit"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster ECS"
  type        = string
}

variable "service_name" {
  description = "Nome do serviço ECS"
  type        = string
}
