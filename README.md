# terraform-aws-microservices
Terraform configuration sample to create AWS 3-Tier Infrastructure for deploying Microservices using ECS & RDS/Aurora PostgreSQL

Install AWS CLI
* <https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>

Configure access_key & secret_key using aws profile
```console
aws configure --profile myprofile
```
or use access_key & secret_key variables. 

`variables.tf`
```terraform
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
```
`main.tf`
```terraform
provider "aws" {
  region     = var.region
#  access_key = var.access_key
#  secret_key = var.secret_key
  profile = ""
}
```
Terraform backend is disabled. view `versions.tf`
> https://www.terraform.io/language/settings/backends/configuration
```terraform
// Terraform Cloud
terraform {
  cloud {
    organization = ""

    workspaces {
      name = ""
    }
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

// AWS S3
terraform {
  backend "s3" {
    bucket  = ""
    key     = ""
    region  = ""
    profile = ""
#    access_key = ""
#    secret_key = ""
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
```

Initialize Terraform
```console
cd src
terraform init
```
***

Plan & Apply
```console
terraform plan
terraform apply
```
Destroy
```console
terraform destroy
```
