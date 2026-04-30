variable "repo_name" {
  description = "Nome do repositório CodeCommit"
  type        = string
}

variable "default_branch" {
  description = "Branch padrão do repositório"
  type        = string
  default     = "master"
}

variable "alias" {
  description = "Alias da conta — usado como prefixo no nome do repositório ECR"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster ECS para o pipeline de deploy"
  type        = string
}
