terraform {
  cloud {
    organization = "Thee5176"
    workspaces {
      name = "AWS_for_Accounting_Project"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.9.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.6.0"
    }
  }

  required_version = ">= 1.13.0"
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.aws_region
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}