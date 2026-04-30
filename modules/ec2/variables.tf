

variable "ami_id" {
  description = "The key pair ID for the EC2 instance"
  type        = string
  default     = "ami-0b6c2d49148000cd5"
}

variable "instance_type" {
  description = "The key pair ID for the EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "associate_public_ip" {
  type    = bool
  default = true
}
variable "root_volume_size" {
  type    = number
  default = "8"
}
variable "use_elastic_ip" {
  type    = bool
  default = false
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_name" {
  type    = string
  default = "ec2-exemplo"
}

# Chave pública SSH para o key pair da instância.
# Nunca coloque o valor diretamente aqui — passe via tfvars ou variável de ambiente.
# Geração local: ssh-keygen -t rsa -b 4096 -f ~/.ssh/minha-chave
variable "public_key" {
  description = "Chave pública SSH para acesso à instância"
  type        = string
}

# Portas TCP abertas no security group. Por padrão restringe a SSH, HTTP e HTTPS.
# Sobrescreva conforme necessário para cada ambiente.
variable "ingress_ports" {
  description = "Portas TCP liberadas no security group da instância"
  type        = list(number)
  default     = [22, 80, 443]
}

variable "ingress_cidrs" {
  description = "CIDRs com acesso às portas de ingress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}