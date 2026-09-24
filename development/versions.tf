terraform {
  required_version = ">= 1.15.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.66.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = ">= 1.4.1"
    }
  }
}
