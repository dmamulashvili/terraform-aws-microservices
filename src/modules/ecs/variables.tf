variable "name" {
  type = string
}

variable "capacity_provider_auto_scaling_group_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}