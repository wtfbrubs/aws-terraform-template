terraform {
  # Garante que versões antigas do Terraform não executem este código.
  # A sintaxe HCL e alguns recursos usados requerem >= 1.9.
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # Necessário pelo módulo EKS para buscar o thumbprint do OIDC provider
    # automaticamente, sem precisar hardcodar o valor.
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
