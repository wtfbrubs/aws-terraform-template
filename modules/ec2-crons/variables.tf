

variable "ami_id" {
  description = "The key pair ID for the EC2 instance"
  type        = string
  default = "ami-0b6c2d49148000cd5"
}

variable "instance_type" {
  description = "The key pair ID for the EC2 instance"
  type        = string
  default = "t2.micro"
}

variable "associate_public_ip" {
  type = bool
  default = true
}
variable "root_volume_size" {
  type = number
  default = "8"
}
variable "use_elastic_ip" {
  type = bool
  default = false
}

variable "vpc_id" {
  type        = string
}

variable "subnet_id" {
  type        = string
}

variable "instance_name" {
  type        = string
  default = "ec2-exemplo"
}