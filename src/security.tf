locals {
  web_ingress = csvdecode(file("files/web_ingress.csv"))
  db_ingress  = csvdecode(file("files/db_ingress.csv"))
}

resource "aws_security_group" "web_access" {
  name = "${local.name}-web-access"

  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = local.web_ingress
    content {
      from_port   = 80
      protocol    = "tcp"
      to_port     = 80
      description = "${ingress.value.description}"
      cidr_blocks = ["${ingress.value.cidr}"]
    }
  }

  dynamic "ingress" {
    for_each = local.web_ingress
    content {
      from_port   = 443
      protocol    = "tcp"
      to_port     = 443
      description = "${ingress.value.description}"
      cidr_blocks = ["${ingress.value.cidr}"]
    }
  }

  tags = merge(
    { Name = "${local.name}-web-access" },
    local.tags
  )
}

resource "aws_security_group" "db_access" {
  name = "${local.name}-database-access"

  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = local.db_ingress
    content {
      from_port   = 5432
      protocol    = "tcp"
      to_port     = 5432
      description = "${ingress.value.description}"
      cidr_blocks = ["${ingress.value.cidr}"]
    }
  }

  tags = merge(
    { Name = "${local.name}-database-access" },
    local.tags
  )
}