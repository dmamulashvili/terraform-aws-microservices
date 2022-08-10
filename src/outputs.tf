output "rds_master_password" {
  value = module.rds_aurora.master_password
  sensitive = true
}