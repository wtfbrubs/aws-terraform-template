provider "aws" {
  region = var.aws_region

  # default_tags aplica estas tags em todos os recursos AWS criados por este provider.
  # Facilita rastreamento de custos, auditoria e identificação de recursos no console.
  default_tags {
    tags = {
      ManagedBy = "terraform"
      Alias     = var.alias
    }
  }
}

module "iam" {
  source = "./iam/produtivo"
  alias  = var.alias
}

module "cloudtrail" {
  source = "./cloudtrail"
  alias  = var.alias
}

module "dlm" {
  source = "./dlm"
}

module "vpc" {
  source             = "./vpc"
  vpc_name           = var.vpc_name
  availability_zones = ["sa-east-1a", "sa-east-1b", "sa-east-1c", "sa-east-1d"]
}

module "ec2" {
  source              = "./ec2"
  subnet_id           = module.vpc.public_subnets_ids[0]
  vpc_id              = module.vpc.vpc_id
  associate_public_ip = true # se eip for usado deve obrigatoriamente ser true
  instance_type       = "t2.micro"
  root_volume_size    = "8"
  use_elastic_ip      = true
  ami_id              = "ami-0b6c2d49148000cd5"
  instance_name       = var.alias
  public_key          = var.ec2_public_key
}

module "rds" {
  source             = "./rds"
  rds_name           = var.alias
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets_ids
  # Restringe o security group do RDS ao tráfego interno da VPC
  vpc_cidr_block = module.vpc.vpc_cidr_block
}

# Bug corrigido: source era "./codecommit-bi" (diretório inexistente)
module "codecommit_bi" {
  source       = "./codecommit-repo"
  repo_name    = "bi"
  alias        = var.alias
  cluster_name = module.ecs.cluster_name
}

# Bug corrigido: faltava source = "./acm"
module "acm" {
  source  = "./acm"
  dominio = var.domain
}

module "alb" {
  source     = "./alb"
  alb_name   = format("%s-alb", var.alias)
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets_ids
  cert_arn   = module.acm.cert_validado
}

module "ecs" {
  source = "./ecs"
  alias  = var.alias
}

# module "eks" {
#   source             = "./eks"
#   alias              = var.alias
#   vpc_id             = module.vpc.vpc_id
#   private_subnet_ids = module.vpc.private_subnets_ids
#   public_subnet_ids  = module.vpc.public_subnets_ids
#   kubernetes_version = "1.30"
#   node_instance_type = "t3.medium"
#   node_desired_size  = 2
#   node_min_size      = 1
#   node_max_size      = 4
# }

module "ecs_service_bi" {
  source             = "./ecs-service"
  service_name       = format("%s-%s", var.alias, module.codecommit_bi.repo_name)
  cluster_id         = module.ecs.cluster_id
  task_family        = format("%s-%s", var.alias, module.codecommit_bi.repo_name)
  task_cpu           = "256"
  task_memory        = "512"
  execution_role_arn = module.ecs.ecs_role_arn
  container_name     = format("%s-%s", var.alias, module.codecommit_bi.repo_name)
  container_image    = "nginx:latest"
  container_port     = 80
  subnet_ids         = module.vpc.private_subnets_ids
  desired_count      = 1
  alias              = var.alias
  vpc_id             = module.vpc.vpc_id
  listener_arn       = module.alb.alb_listener443_arn
  alb_sg_id          = module.alb.alb_sg_id
  target_group_port  = 80
  aws_region         = var.aws_region
  app_dns            = format("bi.%s", var.domain)
  zone_id            = module.acm.zone_id
  alb_dns_name       = module.alb.alb_dns_name
  max_capacity       = 1
  mem_threshold      = 90
  cpu_threshold      = 80

  # Passe variáveis de ambiente não-sensíveis aqui.
  # Exemplo: [{ name = "DATABASE_HOST", value = "meu-rds.sa-east-1.rds.amazonaws.com" }]
  container_environment = []

  # Para senhas e tokens, use container_secrets com ARNs do Secrets Manager.
  # O execution role já tem permissão configurada para lê-los.
  # Exemplo: [{ name = "DATABASE_PASSWORD", valueFrom = "arn:aws:secretsmanager:..." }]
  container_secrets = []
}
