variable "name" {
  type = string
}

variable "vpc_zone_identifier" {
  type = list(string)
}

variable "max_size" {
  type = number
}
variable "min_size" {
  type = number
}

variable "protect_from_scale_in" {
  type = bool
}

variable "health_check_grace_period" {
  type = number
}
variable "health_check_type" {
  type = string
}

variable "launch_template_vpc_security_group_ids" {
  type = list(string)
}
variable "launch_template_image_id" {
  type = string
}
variable "launch_template_instance_type" {
  type = string
}
variable "launch_template_user_data" {
  type = string
}
variable "launch_template_iam_instance_profile_role_policies" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}