output "arn" {
  value = aws_ecs_cluster.this.arn
}

output "name" {
  value = aws_ecs_cluster.this.name
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.this.name
}