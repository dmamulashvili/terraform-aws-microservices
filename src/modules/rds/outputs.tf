output "master_password" {
  value = random_password.master_password.result
}

output "endpoint" {
  value = aws_db_instance.this.endpoint
}