resource "aws_codecommit_repository" "repo" {
  repository_name = var.repo_name
  default_branch = var.default_branch
}

resource "aws_ecr_repository" "ecr_repo" {
  name                 = format("%s-%s",var.alias, var.repo_name)
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_lifecycle_policy" {
  repository = aws_ecr_repository.ecr_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description = "Manter as últimas 10 imagens"
        action = {
          type = "expire"
        }
        selection = {
          tagStatus = "any"
          countType = "imageCountMoreThan"
          countNumber = 10
        }
      }
    ]
  })
}


module "pipeline_devops" {
  source = "./devops"
  repo_name= var.repo_name
  alias = var.alias
  pipeline_branch = "master"
  codecommit_repo_arn=aws_codecommit_repository.repo.arn
  cluster_name=var.cluster_name
  service_name=format("%s-%s",var.alias, var.repo_name)
}

