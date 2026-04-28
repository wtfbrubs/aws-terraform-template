provider "aws" {
  region = var.aws_region  # Altere para a região que você está utilizando
  # Você pode adicionar outras configurações do provedor aqui, se necessário
}

module "iam" {
  source = "./iam"
  alias = var.alias
  # Aqui você pode passar variáveis para o módulo IAM, se necessário
}


module "cloudtrail" {
  source = "./cloudtrail"
#  cloudtrail_name = "cloudtrail_auditoria"
}
module "dlm" {
  source = "./dlm"
#  cloudtrail_name = "cloudtrail_auditoria"
}

module "vpc" {
  source = "./vpc"
  region         =  var.aws_region
  vpc_name       =  var.vpc_name
  availability_zones = ["sa-east-1a", "sa-east-1b", "sa-east-1c", "sa-east-1d"]
}


module "ec2" {
  source = "./ec2"
  subnet_id = module.vpc.public_subnets_ids[0]
  vpc_id = module.vpc.vpc_id
  associate_public_ip = true # se eip for usado deve obrigatoriamente ser true
  instance_type = "t2.micro"
  root_volume_size = "8"
  use_elastic_ip = true
  ami_id = "ami-0b6c2d49148000cd5"
  instance_name = "gasfacil-sandbox" 
}

module "rds" {
  source = "./rds"
  rds_name= "gasfacil-sandbox"
  vpc_id = module.vpc.vpc_id
  // outras configurações necessárias para o módulo RDS
  private_subnet_ids = module.vpc.private_subnets_ids

}

module "codecommit_bi" {
  source = "./codecommit-bi"
  repo_name= "bi"
  alias = var.alias
}


module "acm" {
  dominio = "gasfacil24h.com.br"
}

module "alb" {
  source             = "./alb"
  alb_name           = format("%s-alb",var.alias)
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnets_ids
  cert_arn           = module.acm.cert_validado
}


module "ecs" {
  source = "./ecs"
  alias = var.alias
  private_subnet_ids = module.vpc.private_subnets_ids
  public_subnet_ids = module.vpc.public_subnets_ids
  vpc_id = module.vpc.vpc_id
}

module "ecs_service_bi" {
  source              = "./ecs-service"
  service_name        = format("%s-%s",var.alias, module.codecommit_bi.repo_name)
  cluster_id          = module.ecs.cluster_id
  task_family         = format("%s-%s",var.alias, module.codecommit_bi.repo_name)
  task_cpu            = "256"
  task_memory         = "512"
  execution_role_arn  = module.ecs.ecs_role_arn
  container_name      = format("%s-%s",var.alias, module.codecommit_bi.repo_name)
  container_image     = "nginx:latest"  # Substitua pela sua imagem
  container_port      = 80
  subnet_ids          = module.vpc.private_subnets_ids
  desired_count       = 1
  alias               = var.alias
  vpc_id              = module.vpc.vpc_id
  listener_arn        = module.alb.alb_listener443_arn
  target_group_port   = 80
  aws_region          = var.aws_region
  app_dns             = "bi-sandbox.gasfacil24h.com.br"
  zone_id             = module.acm.zone_id
  alb_dns_name        = module.alb.alb_dns_name
  max_capacity        = 1
  mem_treshold        = 90
  cpu_treshold        = 80
}
