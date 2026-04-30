plugin "aws" {
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
  version = "0.35.0"
  enabled = true
}

# Pega interpolações antigas como "${var.foo}" em vez de var.foo
rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Pega uso de .index em vez de [*]
rule "terraform_deprecated_index" {
  enabled = true
}

# Bloqueia variáveis/outputs/locals declarados mas nunca referenciados
rule "terraform_unused_declarations" {
  enabled = true
}

# Exige que todas as variáveis tenham type definido
rule "terraform_typed_variables" {
  enabled = true
}

# Garante que required_version esteja presente
rule "terraform_required_version" {
  enabled = true
}

# Garante que required_providers esteja presente
rule "terraform_required_providers" {
  enabled = true
}

# Desabilitado: módulos locais (./vpc, ./ecs, etc.) não têm versão para pinar
rule "terraform_module_pinned_source" {
  enabled = false
}

# Desabilitado: submodules internos herdam os constraints do módulo raiz (modules/versions.tf).
# Exigir required_version e required_providers em cada submodule seria redundante.
rule "terraform_required_version" {
  enabled = false
}

rule "terraform_required_providers" {
  enabled = false
}

# Desabilitado: template tem variáveis sem description intencionalmente
rule "terraform_documented_variables" {
  enabled = false
}

rule "terraform_documented_outputs" {
  enabled = false
}
