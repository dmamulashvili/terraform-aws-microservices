variable "region" {
  type = string
}

variable "app_name" {
  type = string
}

variable "domain_name" {
  type = string
}

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

variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}