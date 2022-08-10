locals {
  vpc_name        = var.name
  igw_name        = "${var.name}-igw"
  nat_name        = "${var.name}-nat"
  subnet_dmz_name = "${var.name}-subnet-dmz"
  subnet_app_name = "${var.name}-subnet-app"
  subnet_res_name = "${var.name}-subnet-res"
}

resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  enable_dns_hostnames = true

  tags = merge({
    Name = local.vpc_name
  }, var.tags)
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_ids = data.aws_availability_zones.available.zone_ids
}

# DMZ Subnets
resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets_dmz)

  vpc_id     = aws_vpc.this.id
  cidr_block = each.key

  availability_zone_id = length(var.public_subnets_dmz) >= length(local.az_ids) ? element(local.az_ids, index(var.public_subnets_dmz, each.value)) : null

  map_public_ip_on_launch = true

  tags = merge({
    Name = "${local.subnet_dmz_name}-${element(local.az_ids, index(var.public_subnets_dmz, each.value))}"
  }, var.tags)
}

# APP Subnets
resource "aws_subnet" "private_app" {
  for_each = toset(var.private_subnets_app)

  vpc_id     = aws_vpc.this.id
  cidr_block = each.key

  availability_zone_id = length(var.private_subnets_app) >= length(local.az_ids) ? element(local.az_ids, index(var.private_subnets_app, each.value)) : null

  tags = merge({
    Name = "${local.subnet_app_name}-${element(local.az_ids, index(var.private_subnets_app, each.value))}"
  }, var.tags)
}

# RES Subnets
resource "aws_subnet" "private_res" {
  for_each = toset(var.private_subnets_res)

  vpc_id     = aws_vpc.this.id
  cidr_block = each.key

  availability_zone_id = length(var.private_subnets_res) >= length(local.az_ids) ? element(local.az_ids, index(var.private_subnets_res, each.value)) : null

  tags = merge({
    Name = "${local.subnet_res_name}-${element(local.az_ids, index(var.private_subnets_res, each.value))}"
  }, var.tags)
}

# Internet Gateway for Public Subnets DMZ
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge({
    Name = local.igw_name
  }, var.tags)
}

# Public Subnets DMZ Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    { "Name" = "${var.name}-rt-dmz" },
    var.tags
  )
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id      = each.value.id
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  timeouts {
    create = "5m"
  }
}

# NAT Gateway for Private subnets APP
resource "aws_eip" "nat" {
  count = length(var.private_subnets_app) > 0 ? 1 : 0

  vpc = true

  tags = merge(
    { "Name" = "${var.name}-eip-nat" },
    var.tags
  )
}

resource "aws_nat_gateway" "this" {
  count = length(var.private_subnets_app) > 0 ? 1 : 0

  allocation_id = element(aws_eip.nat.*.id, 0)
  subnet_id     = element([for v in aws_subnet.public : v.id], 0)

  depends_on = [aws_internet_gateway.this]
}

# Private Subnets APP Route Table
resource "aws_route_table" "private_app" {
  count = length(var.private_subnets_app) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    { "Name" = "${var.name}-rt-app" },
    var.tags
  )
}

resource "aws_route_table_association" "private_app" {
  for_each = aws_subnet.private_app

  route_table_id = aws_route_table.private_app[0].id
  subnet_id      = each.value.id
}

resource "aws_route" "private_app_nat_gateway" {
  count = length(var.private_subnets_app) > 0 ? 1 : 0

  route_table_id         = aws_route_table.private_app[0].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

# Private Subnets RES Route Tables
resource "aws_route_table" "private_res" {
  count = length(var.private_subnets_res) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(
    { "Name" = "${var.name}-rt-res" },
    var.tags
  )
}

resource "aws_route_table_association" "private_res" {
  for_each = aws_subnet.private_res

  route_table_id = aws_route_table.private_res[0].id
  subnet_id      = each.value.id
}