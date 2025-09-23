provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "ap-northeast-1"
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}