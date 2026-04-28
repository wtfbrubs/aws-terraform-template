variable "repo_name" {
  description = "nome do repo"
}

variable "alias" {
  description = "Alias padrão da conta. Nome do cliente"
}

variable "pipeline_branch" {
  description = "branch da pipeline"
  default     = "master"
}

variable "codecommit_repo_arn" {
  description = "ARN of the CodeCommit repository"
  type        = string
}


variable "cluster_name"{
  description = "nome do cluster"
}
variable "service_name"{
  description = "nome do serviço"
}

