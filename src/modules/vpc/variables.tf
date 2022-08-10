variable "name" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "public_subnets_dmz" {
  type = list(string)
}

variable "private_subnets_app" {
  type = list(string)
  default = []
}

variable "private_subnets_res" {
  type = list(string)
  default = []
}

variable "tags" {
  type = map(string)
}