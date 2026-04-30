terraform {
  backend "s3" {
    bucket  = "gasfacil-terraform"
    key     = "estado/terraform.tfstate"
    region  = "sa-east-1"
    encrypt = true
  }
}