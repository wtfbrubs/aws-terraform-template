resource "aws_ecs_cluster" "cluster" {
  name = var.alias
}
resource "aws_iam_role" "ecs_execution_role" {

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Permite que o execution role leia secrets do Secrets Manager e do SSM.
# Necessário quando container_secrets é usado no módulo ecs-service.
# Em produção, restrinja Resource aos ARNs específicos dos secrets do serviço.
resource "aws_iam_role_policy" "ecs_secrets_policy" {
  name = format("%s-secrets-policy", var.alias)
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "ssm:GetParameters",
        "kms:Decrypt"
      ]
      Resource = "*"
    }]
  })
}


