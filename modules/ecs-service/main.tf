resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.subnet_ids
    security_groups = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn # Adicione a ARN do Target Group do ALB
    container_name   = var.container_name    # Nome do container conforme definido na definição de tarefa
    container_port   = var.container_port    # Porta que o container está ouvindo
  }

  desired_count = var.desired_count
  // Inclua outras configurações necessárias, como estratégias de implantação, etc.

  lifecycle {
    create_before_destroy = true
    ignore_changes = [task_definition,desired_count]
  }
}


resource "aws_ecs_task_definition" "task" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = var.execution_role_arn

  container_definitions = jsonencode([{
    name  = var.container_name
    image = var.container_image
    # Variáveis não-sensíveis (host, nome do banco, porta, etc.)
    environment = var.container_environment
    # Segredos via Secrets Manager ou SSM — nunca em environment.
    # O execution role (módulo ecs) já tem permissão para lê-los.
    secrets = var.container_secrets
    portMappings = [{
      containerPort = var.container_port
      hostPort      = var.container_port
    }]
    healthCheck  = {
      command     = ["CMD-SHELL", "exit 0"]
      # command     = ["CMD-SHELL", "curl -f http://localhost:${var.container_port}/ || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 10
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.log_group.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
    
  }])
}

resource "aws_security_group" "ecs_service_sg" {
  name        = format("%s-sg", var.service_name)
  description = "Security Group para o servico ECS na porta 80"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permite acesso de qualquer IP. Ajuste conforme necessário.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Permite todo o tráfego de saída
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs_service_sg"
  }
}



resource "aws_lb_target_group" "target_group" {
  name     = format("%s-tg",var.service_name)
  port     = var.target_group_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    matcher             = "200-299"
  }
}




resource "aws_lb_listener_rule" "host_based_routing" {
  listener_arn = var.listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

  condition {
    host_header {
      values = [var.app_dns]
    }
  }
}


resource "aws_cloudwatch_log_group" "log_group" {
  name = format("/ecs/%s",var.service_name)
  retention_in_days = 30
}



resource "aws_route53_record" "dns" {
  zone_id = var.zone_id
  name    = var.app_dns
  type    = "CNAME"
  ttl     = 300
  records = [var.alb_dns_name]
}



resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.desired_count
  resource_id        = "service/${var.alias}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}


resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = format("%s-%s-memory-autoscaling", var.alias, var.service_name)
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = var.mem_treshold
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = format("%s-%s-cpu-autoscaling", var.alias, var.service_name)
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.cpu_treshold
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
