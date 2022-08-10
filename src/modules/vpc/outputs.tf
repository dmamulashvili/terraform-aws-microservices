output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnets_ids" {
  value = [for v in aws_subnet.public : v.id]
}
output "private_app_subnets_ids" {
  value = [for v in aws_subnet.private_app : v.id]
}
output "private_res_subnets_ids" {
  value = [for v in aws_subnet.private_res : v.id]
}

output "public_subnets_cidr_blocks" {
  value = [for v in aws_subnet.public : v.cidr_block]
}
output "private_app_subnets_cidr_blocks" {
  value = [for v in aws_subnet.private_app : v.cidr_block]
}
output "private_res_subnets_cidr_blocks" {
  value = [for v in aws_subnet.private_res : v.cidr_block]
}