locals {
  asg_name     = var.name
  lt_name      = "${var.name}-lt"
  profile_name = "${local.lt_name}-iam-prf"
  role_name    = "${local.profile_name}-role"
}

resource "aws_autoscaling_group" "this" {
  name = local.asg_name
  
  vpc_zone_identifier = var.vpc_zone_identifier

  max_size = var.max_size
  min_size = var.min_size
  
  health_check_grace_period = var.health_check_grace_period
  health_check_type = var.health_check_type

  launch_template {
    name = aws_launch_template.this.name
  }
  
  protect_from_scale_in = var.protect_from_scale_in

  dynamic "tag" {
    for_each = var.tags
    content {
      key   = tag.key
      value = tag.value
      
      propagate_at_launch = true
    }
  }
}

resource "aws_launch_template" "this" {
  name = local.lt_name
  
  vpc_security_group_ids = var.launch_template_vpc_security_group_ids

  image_id      = var.launch_template_image_id
  instance_type = var.launch_template_instance_type

  user_data = base64encode(var.launch_template_user_data)

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge({
    Name = local.lt_name
  }, var.tags)
}

resource "aws_iam_instance_profile" "this" {
  name = local.profile_name
  role = aws_iam_role.this.name

  tags = merge({
    Name = local.profile_name
  }, var.tags)
}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    sid     = "EC2AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

resource "aws_iam_role" "this" {
  name = local.role_name

  assume_role_policy    = data.aws_iam_policy_document.assume_role_policy.json
  force_detach_policies = true

  tags = merge({
    Name = local.role_name
  }, var.tags)
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.launch_template_iam_instance_profile_role_policies)

  policy_arn = each.value
  role       = aws_iam_role.this.name
}