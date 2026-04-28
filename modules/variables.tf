variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "sa-east-1"
}

variable "vpc_name" {
  description = "nome da VPC"
  default     = "vpc-gasfacil"
}

variable "alias" {
  description = "Alias padrão da conta. Nome do cliente"
  default     = "meu-ambiente"
}

# Chave pública SSH usada pelos módulos ec2 e ec2-crons.
# Gere localmente: ssh-keygen -t rsa -b 4096 -f ~/.ssh/minha-chave
# Cole o conteúdo de ~/.ssh/minha-chave.pub no terraform.tfvars.
variable "ec2_public_key" {
  description = "Chave pública SSH para as instâncias EC2"
  type        = string
}

variable "domain" {
  description = "Domínio principal usado no ACM e nos registros DNS dos serviços"
  type        = string
  default     = "example.com"
}