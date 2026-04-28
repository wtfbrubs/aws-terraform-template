module "main" {
  source         = "./modules"
  ec2_public_key = var.ec2_public_key
  alias          = var.alias
  aws_region     = var.aws_region
  vpc_name       = var.vpc_name
  domain         = var.domain
}