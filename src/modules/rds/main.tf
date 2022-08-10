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

resource "aws_db_instance" "this" {
  engine                 = "postgres"
#  engine_version         = "14.2"
  instance_class         = var.instance_class
  storage_type           = "gp2"
  allocated_storage      = 20
  identifier             = local.rds_name
  username               = var.master_username
  password               = random_password.master_password.result
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.this.id
  skip_final_snapshot    = true
  publicly_accessible    = true
  deletion_protection    = false
}