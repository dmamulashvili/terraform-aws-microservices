variable "name" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}

variable "https_listener_certificate_arn" {
  type = string
}

variable "tags" {
  type = map(string)
}