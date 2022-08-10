output "id" {
  value = aws_lb.this.id
}

output "arn" {
  value = aws_lb.this.arn
}

output "arn_suffix" {
  value = aws_lb.this.arn_suffix
}

output "name" {
  value = aws_lb.this.name
}

output "zone_id" {
  value = aws_lb.this.zone_id
}

output "dns_name" {
  value = aws_lb.this.dns_name
}

output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}