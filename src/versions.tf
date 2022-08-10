// Terraform Cloud
#terraform {
#  cloud {
#    organization = ""
#
#    workspaces {
#      name = ""
#    }
#  }
#  required_providers {
#    aws = {
#      source = "hashicorp/aws"
#    }
#  }
#}

// AWS S3
#terraform {
#  backend "s3" {
#    bucket  = ""
#    key     = ""
#    region  = ""
#    profile = ""
##    access_key = ""
##    secret_key = ""
#  }
#  required_providers {
#    aws = {
#      source = "hashicorp/aws"
#    }
#  }
#}