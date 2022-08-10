variable "region" {
  type = string
}

variable "app_name" {
  type = string
}

# Route 53 Hosted Zone
variable "domain_name" {
  type = string
}

# ALB https
variable "certificate_arn" {
  type = string
}

variable "env_name" {
  type = string
  validation {
    condition     = var.env_name == "dev" || var.env_name == "stage" || var.env_name == "prod"
    error_message = "The env_name value must be dev, stage or prod."
  }
}

variable "db_master_username" {
  type = string
}

#variable "access_key" {
#  type = string
#}
#
#variable "secret_key" {
#  type = string
#}
