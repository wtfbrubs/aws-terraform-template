variable "vpc_cidr_block" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "100.121.0.0/16"
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
}

variable "public_subnet_cidr_blocks" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["100.121.0.0/24", "100.121.2.0/24"]
}

variable "private_subnet_cidr_blocks" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["100.121.1.0/24", "100.121.3.0/24"]
}
