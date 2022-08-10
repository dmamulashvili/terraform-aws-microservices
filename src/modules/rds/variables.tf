variable "name" {
  type = string
}

variable "subnet_group_subnet_ids" {
  type = list(string)
}

variable "vpc_security_group_ids" {
  type = list(string)
}
variable "master_username" {
  type = string
}

variable "instance_class" {
  type = string
}


variable "tags" {
  type = map(string)
}