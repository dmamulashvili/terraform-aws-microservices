variable "name" {
  type = string
}

variable "subnet_group_subnet_ids" {
  type = list(string)
}

variable "cluster_vpc_security_group_ids" {
  type = list(string)
}
variable "cluster_master_username" {
  type = string
}

variable "cluster_instance_instance_class" {
  type = string
}

variable "appautoscaling_target_min_capacity" {
  type = number
}
variable "appautoscaling_target_max_capacity" {
  type = number
}
variable "appautoscaling_policy_cpu_target_value" {
  type = number
  default = 0
}
variable "appautoscaling_policy_conn_target_value" {
  type = number
  default = 0
}


variable "tags" {
  type = map(string)
}