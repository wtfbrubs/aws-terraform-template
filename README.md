# aws-terraform-template

Template de infraestrutura AWS gerenciada com Terraform, voltado para ambientes de produção e sandbox em contas AWS da região `sa-east-1`. Inclui pipeline GitLab CI com estimativa de custo via Infracost.

## Visão Geral

```
┌─────────────────────────────────────────────────────┐
│                      AWS Account                     │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │                   VPC                        │   │
│  │  ┌─────────────────┐  ┌──────────────────┐  │   │
│  │  │  Public Subnets  │  │ Private Subnets  │  │   │
│  │  │  EC2 + EIP       │  │  ECS (Fargate)   │  │   │
│  │  │  ALB             │  │  RDS (MySQL)     │  │   │
│  │  │  NAT Gateway     │  │  EFS             │  │   │
│  │  └─────────────────┘  └──────────────────┘  │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ACM · Route53 · CloudTrail · DLM · S3 · Lambda     │
│  CodeCommit · ECR · SES · IAM · CloudWatch           │
└─────────────────────────────────────────────────────┘
```

## Pré-requisitos

- Terraform >= 1.0
- AWS CLI configurado com credenciais válidas
- Bucket S3 para armazenar o estado remoto (ver `backend.tf`)
- GitLab CI com as variáveis `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` configuradas

## Estrutura

```
.
├── backend.tf              # Configuração do backend S3
├── main.tf                 # Entrada principal — chama o módulo raiz
├── .gitlab-ci.yml          # Pipeline de plan/apply com estimativa de custo
└── modules/
    ├── main.tf             # Orquestração de todos os submódulos
    ├── variables.tf        # Variáveis globais (região, alias, vpc_name)
    ├── outputs.tf          # Outputs da VPC expostos ao nível raiz
    ├── vpc/                # Rede completa
    ├── ec2/                # Instância de uso geral
    ├── ec2-crons/          # Instância para tarefas agendadas
    ├── rds/                # Banco de dados MySQL
    ├── ecs/                # Cluster ECS e role de execução
    ├── ecs-service/        # Serviço Fargate com ALB e autoscaling
    ├── alb/                # Application Load Balancer
    ├── acm/                # Certificado SSL com validação DNS
    ├── codecommit-repo/    # Repositório + ECR + pipeline de deploy
    ├── cloudtrail/         # Auditoria de ações na conta
    ├── dlm/                # Políticas de snapshot de EBS
    ├── efs/                # Elastic File System
    ├── s3/                 # Bucket com criptografia e grupos IAM
    ├── lambda/             # Função Lambda via imagem de container
    ├── ses/                # Identidade de domínio para envio de e-mail
    ├── route53/            # Hosted zone
    └── iam/produtivo/      # Roles de acesso com MFA obrigatório
```

## Módulos

### `vpc`
Cria toda a camada de rede:
- VPC com DNS habilitado (`100.121.0.0/16` por padrão)
- Subnets públicas e privadas em múltiplas AZs
- Internet Gateway, NAT Gateway e Elastic IP para NAT
- Route tables separadas para tráfego público e privado
- NACLs para subnets públicas e privadas

| Variável | Padrão | Descrição |
|---|---|---|
| `vpc_cidr_block` | `100.121.0.0/16` | CIDR da VPC |
| `vpc_name` | — | Tag de nome da VPC |
| `availability_zones` | — | Lista de AZs |
| `public_subnet_cidr_blocks` | `["100.121.0.0/24", "100.121.2.0/24"]` | CIDRs públicos |
| `private_subnet_cidr_blocks` | `["100.121.1.0/24", "100.121.3.0/24"]` | CIDRs privados |

### `ec2`
Instância EC2 de uso geral:
- Key pair configurável via variável
- Security group com ingress/egress aberto (ajustar conforme necessidade)
- Elastic IP opcional
- Volume raiz e volume adicional de 40 GB criptografados com KMS

### `ec2-crons`
Variante da instância EC2 voltada para cron jobs e serviços de infraestrutura:
- Portas 22 (SSH), 80 (HTTP), 443 (HTTPS), 1194 (OpenVPN) e 19409 (UDP)
- Volume raiz criptografado com KMS dedicado
- Volume adicional de 40 GB (gp3)

### `rds`
Banco de dados MySQL 8.0 gerenciado:
- Instância `db.t3.micro`, storage gp3 com autoscaling até 100 GB
- Senha gerenciada pelo Secrets Manager + KMS dedicado
- Enhanced Monitoring (60s), logs CloudWatch (audit, error, general, slowquery)
- Backup diário às 04:00 UTC com retenção de 7 dias
- `deletion_protection = true` — requer desativação manual antes de destruir

### `eks`
Cluster Kubernetes gerenciado (EKS):
- Cluster com logs do control plane habilitados (api, audit, authenticator, controllerManager, scheduler) — retenção de 7 dias no CloudWatch
- Endpoint privado sempre habilitado; endpoint público configurável via `endpoint_public_access`
- Managed Node Group em subnets privadas com autoscaling (`min`/`desired`/`max`)
- IAM Roles separadas para cluster e nodes com policies mínimas necessárias
- OIDC Provider configurado automaticamente para habilitar **IRSA** (IAM Roles for Service Accounts)
- Addons essenciais provisionados: `vpc-cni`, `kube-proxy`, `coredns`

| Variável | Padrão | Descrição |
|---|---|---|
| `kubernetes_version` | `1.30` | Versão do Kubernetes |
| `endpoint_public_access` | `true` | Expõe a API publicamente |
| `node_instance_type` | `t3.medium` | Tipo de instância dos nodes |
| `node_disk_size` | `20` | Disco dos nodes em GB |
| `node_desired_size` | `2` | Nodes desejados |
| `node_min_size` | `1` | Mínimo de nodes |
| `node_max_size` | `4` | Máximo de nodes |

> O `desired_size` é ignorado no lifecycle para não conflitar com o Cluster Autoscaler.

**Outputs disponíveis:** `cluster_name`, `cluster_id`, `cluster_endpoint`, `cluster_certificate_authority`, `oidc_provider_arn`, `oidc_provider_url`, `node_role_arn`.

### `ecs`
Cluster ECS e infraestrutura de suporte:
- Cluster com o nome definido por `alias`
- IAM Role de execução com a policy `AmazonECSTaskExecutionRolePolicy`

### `ecs-service`
Serviço Fargate completo:
- Task definition com variáveis de ambiente configuráveis
- Target Group HTTP + regra de roteamento no ALB por host header
- CloudWatch Log Group com retenção de 3 dias
- Registro DNS automático via Route53 (CNAME para o ALB)
- Autoscaling baseado em CPU e memória com cooldown de 300s

| Variável | Descrição |
|---|---|
| `service_name` | Nome do serviço |
| `container_image` | Imagem do container (ex: `nginx:latest`) |
| `container_port` | Porta exposta pelo container |
| `app_dns` | Subdomínio que será criado no Route53 |
| `max_capacity` | Capacidade máxima do autoscaling |
| `cpu_treshold` | % CPU para escalar (padrão: 60) |
| `mem_treshold` | % memória para escalar (padrão: 80) |

### `alb`
Application Load Balancer externo:
- Listener na porta 80 com redirect 301 para HTTPS
- Listener na porta 443 com certificado ACM
- Security group com ingress nas portas 80 e 443

### `acm`
Certificado SSL/TLS:
- Validação por DNS via Route53
- Cobre o domínio raiz e o wildcard `*.dominio`

### `codecommit-repo`
Stack completa de repositório:
- Repositório CodeCommit com branch padrão configurável
- ECR com scan automático no push e lifecycle de 10 imagens
- Submódulo `devops` para pipeline de deploy no ECS

### `cloudtrail`
Trail de auditoria da conta AWS:
- Eventos globais de serviço habilitados
- Logs armazenados em bucket S3 dedicado
- Substituir `CLIENTE` pelo alias da conta antes de usar

### `dlm`
Políticas de ciclo de vida de snapshots EBS:
- **Diário**: 14 retenções, execução às 03:00 UTC — tag `Snapshot_diario=true`
- **Semanal**: 4 retenções, toda segunda às 03:00 UTC — tag `Snapshot_semanal=true`
- **Mensal**: 12 retenções, dia 1 de cada mês às 03:00 UTC — tag `Snapshot_mensal=true`

Para ativar snapshots em um volume, adicione a tag correspondente ao recurso EC2 ou EBS.

### `efs`
Elastic File System criptografado:
- Throughput mode `elastic`
- Mount targets em todas as subnets fornecidas
- Security group restrito à porta 2049 (NFS) dentro do CIDR da VPC
- Backup automático habilitado

### `s3`
Bucket S3 com boas práticas:
- Versionamento habilitado
- Criptografia server-side com KMS dedicado
- 3 grupos IAM criados automaticamente: `FullAccess`, `ReadWrite`, `ReadOnly`

### `lambda`
Função Lambda via imagem de container:
- IAM Role com `AWSLambdaBasicExecutionRole`
- Configuração de imagem via `image_uri`

### `ses`
Identidade de domínio no Simple Email Service.
O arquivo `ses/main.tf` contém exemplos comentados para DKIM, verificação DNS e configuração de eventos CloudWatch.

### `route53`
Cria uma Hosted Zone para o domínio informado via variável `dominio`.

### `iam/produtivo`
Roles de acesso com MFA obrigatório:
- `BasicAccessRole`: leitura de EC2 e S3 (Describe*, Get*, List*)
- `FullAdminAccessRole`: acesso total à conta
- Grupo IAM `dev-power-users` com permissão CodeCommit Power User
- IAM Access Analyzer habilitado
- Account alias configurado via variável `alias`

## Variáveis Globais

Definidas em `modules/variables.tf`:

| Variável | Padrão | Descrição |
|---|---|---|
| `aws_region` | `sa-east-1` | Região AWS |
| `vpc_name` | `vpc-gasfacil` | Nome da VPC |
| `alias` | `gasfacil-sandbox` | Alias da conta / prefixo dos recursos |

Substitua os valores padrão pelo alias e domínio do ambiente alvo antes de provisionar.

## Backend

O estado remoto é armazenado em S3. Configure em `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket  = "<seu-bucket-de-estado>"
    key     = "estado/terraform.tfstate"
    region  = "sa-east-1"
    encrypt = true
  }
}
```

## Pipelines de CI/CD

### GitLab CI (`.gitlab-ci.yml`)

| Stage | Trigger | Descrição |
|---|---|---|
| `plan` | Automático | `terraform init` + `validate` + `plan` + estimativa de custo via Infracost |
| `cost-estimate` | — | (reservado) |
| `apply` | Manual (`master`) | `terraform apply` com o plano gerado |

O artefato `tfplan` é passado do stage `plan` para o `apply`.

**Variáveis necessárias** — configure em **Settings → CI/CD → Variables**:

| Variável | Descrição |
|---|---|
| `AWS_ACCESS_KEY_ID` | Access key da IAM User/Role |
| `AWS_SECRET_ACCESS_KEY` | Secret key da IAM User/Role |
| `AWS_DEFAULT_REGION` | Região AWS (padrão: `sa-east-1`) |

---

### GitHub Actions (`.github/workflows/terraform.yml`)

| Job | Trigger | Descrição |
|---|---|---|
| `plan` | Push em qualquer branch, PRs e `workflow_dispatch` | `terraform init` + `validate` + `plan` + estimativa de custo via Infracost |
| `apply` | Após `plan` aprovado, somente em `main`/`master` | `terraform apply` com aprovação manual via GitHub Environments |

O `apply` só é executado em push para `main` ou `master` e exige aprovação manual de um revisor configurado no Environment do repositório.

**Variáveis necessárias** — configure em **Settings → Secrets and variables → Actions**:

| Secret | Descrição |
|---|---|
| `AWS_ACCESS_KEY_ID` | Access key da IAM User/Role |
| `AWS_SECRET_ACCESS_KEY` | Secret key da IAM User/Role |
| `INFRACOST_API_KEY` | API key do Infracost (obter em [infracost.io](https://infracost.io)) |

**Configurar aprovação manual do apply:**

1. Acesse **Settings → Environments** no repositório.
2. Crie um environment chamado `production`.
3. Em **Required reviewers**, adicione os usuários ou times que precisam aprovar antes do apply rodar.

Após isso, toda vez que um push chegar em `main`/`master`, o job `apply` ficará pausado aguardando aprovação — equivalente ao `when: manual` do GitLab.

## Como usar

### 1. Configurar credenciais AWS

Você precisa de uma IAM User ou Role com permissões suficientes para criar os recursos desejados.
Configure as credenciais localmente via AWS CLI:

```bash
aws configure
# ou exporte diretamente:
export AWS_ACCESS_KEY_ID="sua-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
export AWS_DEFAULT_REGION="sa-east-1"
```

Verifique se as credenciais estão funcionando:

```bash
aws sts get-caller-identity
```

---

### 2. Criar o bucket de estado remoto

O bucket S3 para armazenar o `terraform.tfstate` precisa existir **antes** do `terraform init`.
Crie-o manualmente (uma única vez por conta/ambiente):

```bash
aws s3api create-bucket \
  --bucket <nome-do-bucket-de-estado> \
  --region sa-east-1 \
  --create-bucket-configuration LocationConstraint=sa-east-1

# Habilitar versionamento no bucket de estado (recomendado)
aws s3api put-bucket-versioning \
  --bucket <nome-do-bucket-de-estado> \
  --versioning-configuration Status=Enabled
```

Depois, edite `backend.tf` com o nome do bucket criado:

```hcl
terraform {
  backend "s3" {
    bucket  = "<nome-do-bucket-de-estado>"
    key     = "estado/terraform.tfstate"
    region  = "sa-east-1"
    encrypt = true
  }
}
```

---

### 3. Personalizar o template

Antes de provisionar, substitua os valores de exemplo pelos dados reais do ambiente:

| Arquivo | O que alterar |
|---|---|
| `modules/variables.tf` | `alias`, `vpc_name` (trocar `gasfacil-sandbox` pelo nome do cliente/ambiente) |
| `modules/cloudtrail/main.tf` | Substituir `CLIENTE` pelo alias da conta (aparece em 3 lugares) |
| `modules/main.tf` | Comentar os módulos que **não** serão usados no ambiente |
| `modules/ecs-service/main.tf` | Substituir variáveis de ambiente hardcoded (`DATABASE_*`) por valores reais ou mover para Secrets Manager |
| `modules/ec2/main.tf` | Substituir a `public_key` do `aws_key_pair` pela chave pública do ambiente |
| `modules/ec2-crons/main.tf` | Idem acima, se for usar esse módulo |

---

### 4. Inicializar o Terraform

```bash
terraform init
```

Este comando baixa os providers necessários e conecta ao backend S3.
Se o bucket de estado ainda não existir, o `init` falhará — volte ao passo 2.

---

### 5. Validar a configuração

```bash
terraform validate
```

Verifica erros de sintaxe e tipagem sem se conectar à AWS.
Para validar sem usar o backend S3 (útil em ambientes sem credenciais):

```bash
terraform init -backend=false
terraform validate
```

---

### 6. Gerar e revisar o plano

```bash
terraform plan -out=tfplan
```

Leia o output com atenção antes de aplicar. Pontos de atenção:
- Recursos com `deletion_protection = true` (RDS) não podem ser destruídos diretamente — precisam ter essa flag desativada antes.
- O módulo `acm` valida o certificado via Route53; o domínio precisa existir e estar apontando para a zona do Route53 gerenciada por este template.

---

### 7. Aplicar

```bash
terraform apply tfplan
```

> **Atenção**: a aplicação cria recursos reais na AWS e pode gerar custos.
> Use `terraform destroy` para remover tudo quando não for mais necessário.

---

### Via pipeline GitLab CI

Se preferir rodar via GitLab CI ao invés de localmente:

1. Configure as variáveis no GitLab: **Settings → CI/CD → Variables**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_DEFAULT_REGION` (opcional, padrão `sa-east-1`)
2. Faça push para qualquer branch — o stage `plan` roda automaticamente e exibe o custo estimado via Infracost.
3. Para aplicar, acesse o pipeline no GitLab e acione manualmente o stage `apply` (disponível apenas na branch `master`).
