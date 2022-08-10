locals {
  rds_name          = var.name
  subnet_group_name = "${local.rds_name}-sg"
}

resource "aws_db_subnet_group" "this" {
  name       = local.subnet_group_name
  subnet_ids = var.subnet_group_subnet_ids

  tags = merge(
    { Name = local.subnet_group_name },
    var.tags
  )
}

resource "random_password" "master_password" {
  length  = 16
  special = true
}

resource "aws_rds_cluster" "this" {
  cluster_identifier              = local.rds_name
  engine                          = "aurora-postgresql"
  #  engine_version                  = "13.6"
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = var.cluster_vpc_security_group_ids
  master_username                 = var.cluster_master_username
  master_password                 = random_password.master_password.result
  backup_retention_period         = 7
  skip_final_snapshot             = true
  enabled_cloudwatch_logs_exports = ["postgresql"]
  #  deletion_protection = true
}

resource "aws_rds_cluster_instance" "this" {
  count               = 2
  identifier          = "${local.rds_name}-${count.index}"
  cluster_identifier  = aws_rds_cluster.this.id
  instance_class      = var.cluster_instance_instance_class
  engine              = aws_rds_cluster.this.engine
  engine_version      = aws_rds_cluster.this.engine_version
  publicly_accessible = true
}

resource "aws_appautoscaling_target" "this" {
  count = var.appautoscaling_target_max_capacity > 0 && var.appautoscaling_target_min_capacity >= 0 ? 1 : 0

  service_namespace  = "rds"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  resource_id        = "cluster:${aws_rds_cluster.this.id}"
  min_capacity       = var.appautoscaling_target_min_capacity
  max_capacity       = var.appautoscaling_target_max_capacity
}

resource "aws_appautoscaling_policy" "cpu_policy" {
  count = var.appautoscaling_policy_cpu_target_value > 0 ? 1 : 0
  
  name = "${local.rds_name}-cpu-tts"

  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.this[0].resource_id

  policy_type = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }

    target_value       = var.appautoscaling_policy_cpu_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}

resource "aws_appautoscaling_policy" "conn_policy" {
  count = var.appautoscaling_policy_conn_target_value > 0 ? 1 : 0

  name = "${local.rds_name}-conn-tts"

  service_namespace  = aws_appautoscaling_target.this[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.this[0].resource_id

  policy_type = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageDatabaseConnections"
    }

    target_value       = var.appautoscaling_policy_conn_target_value
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}