locals {
  ecs_name = var.name
}

resource "aws_ecs_cluster" "this" {
  name = local.ecs_name

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.this.name
      }
    }
  }

  tags = merge(
    { Name = local.ecs_name },
    var.tags
  )
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/ecs/${local.ecs_name}"
  retention_in_days = 7

  tags = merge(
    { Name = "/aws/ecs/${local.ecs_name}" },
    var.tags
  )
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = [aws_ecs_capacity_provider.this.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.this.name
  }
}

resource "aws_ecs_capacity_provider" "this" {
  name = "${local.ecs_name}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = var.capacity_provider_auto_scaling_group_arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 5
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}