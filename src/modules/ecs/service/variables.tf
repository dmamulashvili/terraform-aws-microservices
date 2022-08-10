variable "region" {
  type = string
}

variable "name" {
  type = string
}
variable "host_header" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ecs_cluster_arn" {
  type = string
}
variable "ecs_cluster_name" {
  type = string
}

variable "ecs_cluster_capacity_provider_name" {
  type = string
}

variable "desired_count" {
  type = number
}

variable "task_definition_container_definition_cpu" {
  type = number
}
variable "task_definition_container_definition_memory_hard" {
  type = number
}
variable "task_definition_container_definition_memory_soft" {
  type = number
}
variable "task_definition_container_definition_environment" {
  type = object({
    name  = string
    value = string
  })
}


variable "route53_zone_id" {
  type = string
}


variable "load_balancer_arn_suffix" {
  type = string
}
variable "load_balancer_dns_name" {
  type = string
}
variable "load_balancer_zone_id" {
  type = string
}
variable "load_balancer_listener_arn" {
  type = string
}

variable "appautoscaling_target_max_capacity" {
  type = number
}
variable "appautoscaling_target_min_capacity" {
  type = number
}
variable "appautoscaling_policy_cpu_target_value" {
  description = "ECSServiceAverageCPUUtilization"
  type        = number
}
variable "appautoscaling_policy_memory_target_value" {
  description = "ECSServiceAverageMemoryUtilization"
  type        = number
}
variable "appautoscaling_policy_alb_target_value" {
  description = "ALBRequestCountPerTarget"
  type        = number
}

variable "tags" {
  type = map(string)
}

