provider "aws" {
  region     = var.region
#  access_key = var.access_key
#  secret_key = var.secret_key
  profile = ""
}

locals {
  name = "${var.app_name}-${var.env_name}"

  vpc_name = "${local.name}-vpc"
  asg_name = "${local.name}-asg"
  ecs_name = "${local.name}-ecs"
  alb_name = "${local.name}-alb"
  rds_name = "${local.name}-rds"

  tags = {
    Environment = var.env_name,
    Terraform   = true
  }
}


##
# VPC
##
module "vpc" {
  source = "./modules/vpc"

  name       = local.vpc_name
  cidr_block = "10.0.0.0/16"

  public_subnets_dmz = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets_app = ["10.0.11.0/24","10.0.12.0/24","10.0.13.0/24"] # Single NAT in 1a zone
  private_subnets_res = ["10.0.111.0/24","10.0.112.0/24","10.0.113.0/24"]

  tags = local.tags
}


# ECS Optimized AMIs
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-optimized_AMI.html
data "aws_ssm_parameter" "ecs_optimized_ami" {
  #  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended"
}
##
# Auto Scaling Group
##
module "asg" {
  source = "./modules/asg"

  name = local.asg_name

  vpc_zone_identifier = module.vpc.private_app_subnets_ids

  max_size = 4
  min_size = 1

  health_check_grace_period = 300
  health_check_type         = "EC2"

  # Required for aws_ecs_capacity_provider auto_scaling_group_provider managed_termination_protection = "ENABLED"
  protect_from_scale_in = true

  launch_template_vpc_security_group_ids = [aws_security_group.asg_sg.id]

  launch_template_image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  launch_template_instance_type = "t4g.micro"

  launch_template_user_data = <<-EOT
    #!/bin/bash
    cat <<'EOF' >> /etc/ecs/ecs.config
    ECS_CLUSTER=${local.ecs_name}
    ECS_LOGLEVEL=debug
    EOF
  EOT

  launch_template_iam_instance_profile_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  tags = merge(
    { AmazonECSManaged = true },
    local.tags
  )
}
resource "aws_security_group" "asg_sg" {
  name        = "${local.asg_name}-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow all from LB"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge({
    Name = "${local.asg_name}-sg"
  }, local.tags)
}


##
# Application Load Balancer
##
module "alb" {
  source = "./modules/alb"

  name = local.alb_name

  subnets         = module.vpc.public_subnets_ids
  security_groups = [aws_security_group.alb_sg.id, aws_security_group.web_access.id]

  https_listener_certificate_arn = var.certificate_arn

  tags = local.tags
}
resource "aws_security_group" "alb_sg" {
  name        = "${local.alb_name}-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = module.vpc.vpc_id

#  ingress {
#    description      = "Allow Http"
#    from_port        = 80
#    to_port          = 80
#    protocol         = "tcp"
#    cidr_blocks      = ["0.0.0.0/0"]
#    ipv6_cidr_blocks = ["::/0"]
#  }
#
#  ingress {
#    description      = "Allow Https"
#    from_port        = 443
#    to_port          = 443
#    protocol         = "tcp"
#    cidr_blocks      = ["0.0.0.0/0"]
#    ipv6_cidr_blocks = ["::/0"]
#  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge({
    Name = "${local.alb_name}-sg"
  }, local.tags)
}


##
# ECS Cluster
##
module "ecs_cluster" {
  source = "./modules/ecs"

  name = local.ecs_name

  capacity_provider_auto_scaling_group_arn = module.asg.arn

  tags = local.tags
}


##
# ECS Service
##
locals {
  env_map = {
    "dev"   = "Development",
    "stage" = "Staging",
    "prod"  = "Production"
  }
  services = {
    # all available prop sample
    "identity-api" : {
      desired_count = 0,
      cpu           = 0,
      memory_hard   = 0,
      memory_soft   = 128,
      autoscaling   = {
        max_capacity  = 0,
        min_capacity  = 0,
        alb_target    = 0,
        cpu_target    = 0,
        memory_target = 0
      }
    },
    "audit-api": {
      desired_count = 0,
      memory_soft   = 128,
      autoscaling   = {
        max_capacity  = 2,
        min_capacity  = 0,
        cpu_target    = 75
      }
    }
    "ordering-api" : {
      desired_count = 0,
      memory_soft   = 128,
      autoscaling   = {
        max_capacity  = 4,
        min_capacity  = 0,
        cpu_target    = 75,
        memory_target = 75
      }
    },
    "reporting-api" : {
      desired_count = 0,
      memory_hard   = 512,
      memory_soft   = 256,
      autoscaling   = {
        max_capacity  = 4,
        min_capacity  = 0,
        memory_target = 75
      }
    }
  }
}
module "ecs_service" {
  for_each = local.services

  source = "./modules/ecs/service"

  region = var.region

  name = "${each.key}-${var.env_name}"

  # *.dev.example.com, *.stage.example.com, *.example.com
  host_header = "${each.key}${var.env_name == "prod" ? "" : ".${var.env_name}"}.${var.domain_name}"

  vpc_id = module.vpc.vpc_id

  ecs_cluster_arn                    = module.ecs_cluster.arn
  ecs_cluster_name                   = module.ecs_cluster.name
  ecs_cluster_capacity_provider_name = module.ecs_cluster.capacity_provider_name

  desired_count = each.value.desired_count

  task_definition_container_definition_cpu         = try(each.value.cpu, 0)
  task_definition_container_definition_memory_hard = try(each.value.memory_hard, 0)
  task_definition_container_definition_memory_soft = try(each.value.memory_soft, 0)
  task_definition_container_definition_environment = {
    name  = "ASPNETCORE_ENVIRONMENT"
    value = local.env_map[var.env_name]
  }

  # Creates Route53 A Record pointing to ALB using host_header
  route53_zone_id        = aws_route53_zone.env_zone.zone_id
  
  load_balancer_arn_suffix = module.alb.arn_suffix
  load_balancer_dns_name = module.alb.dns_name
  load_balancer_zone_id  = module.alb.zone_id
  # Creates ALB Listener rule forwarding to Target Group using host_header
  load_balancer_listener_arn = module.alb.https_listener_arn

  appautoscaling_target_max_capacity        = try(each.value.autoscaling.max_capacity, 0)
  appautoscaling_target_min_capacity        = try(each.value.autoscaling.min_capacity, 0)
  appautoscaling_policy_cpu_target_value    = try(each.value.autoscaling.cpu_target, 0)
  appautoscaling_policy_memory_target_value = try(each.value.autoscaling.memory_target, 0)
  appautoscaling_policy_alb_target_value    = try(each.value.autoscaling.alb_target, 0)

  tags = local.tags
}


##
# RDS Aurora, Write/Read + Replica Autoscaling
##
resource "aws_security_group" "rds_sg" {
  name   = "${local.rds_name}-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    protocol    = "tcp"
    to_port     = 5432
    cidr_blocks = [for s in module.vpc.public_subnets_cidr_blocks : s]
  }

  tags = merge(
    { Name = "${local.rds_name}-sg" },
    local.tags
  )
}
module "rds_aurora" {
  source = "./modules/rds_aurora"

  name = "${local.rds_name}-aurora"

  subnet_group_subnet_ids = module.vpc.private_res_subnets_ids

  cluster_master_username        = var.db_master_username
  cluster_vpc_security_group_ids = [aws_security_group.rds_sg.id, aws_security_group.db_access.id]

  cluster_instance_instance_class = "db.t4g.medium"

  appautoscaling_target_min_capacity = 1
  appautoscaling_target_max_capacity = 4
  appautoscaling_policy_cpu_target_value = 75
  # https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.Managing.html
  appautoscaling_policy_conn_target_value = 375

  tags = local.tags
}


##
# Route 53
##
# Main hosted zone: example.com
data "aws_route53_zone" "main" {
  name = var.domain_name
}
# Environment hosted zone:  dev.example.com
resource "aws_route53_zone" "env_zone" {
  name = "${var.env_name}.${data.aws_route53_zone.main.name}"

  tags = local.tags
}
resource "aws_route53_record" "env_zone_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = aws_route53_zone.env_zone.name
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.env_zone.name_servers
}