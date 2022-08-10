locals {
  service_name = var.name
  ecr_name     = "${local.service_name}-ecr"
  td_name      = "${local.service_name}-td"
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${local.service_name}"
  retention_in_days = 1

  tags = merge(
    { Name = "/ecs/${local.service_name}" },
    var.tags
  )
}


resource "aws_ecr_repository" "this" {
  name                 = local.ecr_name
  image_tag_mutability = "MUTABLE"

  tags = merge(
    { Name = local.ecr_name },
    var.tags
  )
}

resource "aws_ecs_task_definition" "this" {
  family = local.td_name

  container_definitions = jsonencode([
    {
      name              = local.td_name
      image             = "${aws_ecr_repository.this.repository_url}:latest"
      cpu               = var.task_definition_container_definition_cpu
      memory            = var.task_definition_container_definition_memory_hard == 0 ? null : var.task_definition_container_definition_memory_hard
      memoryReservation = var.task_definition_container_definition_memory_soft
      logConfiguration  = {
        logDriver = "awslogs"
        options   = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      portMappings = [
        {
          containerPort = 80
          hostPort      = 0
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = var.task_definition_container_definition_environment.name
          value = var.task_definition_container_definition_environment.value
        }
      ]
    }
  ])

  tags = merge(
    { Name = local.td_name },
    var.tags
  )
}


resource "aws_ecs_service" "this" {
  name = local.service_name

  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.this.arn

  desired_count = var.desired_count

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  health_check_grace_period_seconds = 0

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = aws_ecs_task_definition.this.family
    container_port   = 80
  }

  capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = var.ecs_cluster_capacity_provider_name
  }

  propagate_tags = "NONE"

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = merge(
    { Name = local.service_name },
    var.tags
  )
}

resource "aws_appautoscaling_target" "this" {
  count = var.appautoscaling_target_max_capacity > 0 && var.appautoscaling_target_min_capacity >= 0 ? 1 : 0

  max_capacity       = var.appautoscaling_target_max_capacity
  min_capacity       = var.appautoscaling_target_min_capacity
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_policy" {
  count = var.appautoscaling_policy_cpu_target_value > 0 ? 1 : 0

  name = "${local.service_name}-cpu-tts"

  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.this[0].resource_id

  policy_type = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.appautoscaling_policy_cpu_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "memory_policy" {
  count = var.appautoscaling_policy_memory_target_value > 0 ? 1 : 0

  name = "${local.service_name}-memory-tts"

  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.this[0].resource_id

  policy_type = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = var.appautoscaling_policy_memory_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "alb_policy" {
  count = var.appautoscaling_policy_alb_target_value > 0 ? 1 : 0

  name = "${local.service_name}-alb-tts"

  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.this[0].resource_id

  policy_type = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label = "${var.load_balancer_arn_suffix}/${aws_lb_target_group.this.arn_suffix}"
    }

    target_value       = var.appautoscaling_policy_alb_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${local.service_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = merge(
    { Name = "${local.service_name}-tg" },
    var.tags
  )
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.load_balancer_listener_arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
  condition {
    host_header {
      values = [var.host_header]
    }
  }
}

resource "aws_route53_record" "this" {
  zone_id = var.route53_zone_id
  name    = var.host_header
  type    = "A"

  alias {
    name                   = var.load_balancer_dns_name
    zone_id                = var.load_balancer_zone_id
    evaluate_target_health = true
  }
}