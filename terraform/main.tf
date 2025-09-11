module "vpc" {
  source = "./modules/vpc"
}

module "alb" {
  source = "./modules/alb"
}

module "ec2" {
  source = "./modules/ec2"
}

module "rds" {
  source = "./modules/rds"
  db_username = var.db_username
  db_password = var.db_password
  db_schema   = var.db_schema
}

module "gh_secret" {
  source = "./modules/gh_secret"
  aws_access_key = var.aws_access_key
  db_username     = var.db_username
  db_password     = var.db_password
  db_schema       = var.db_schema
  aws_secret_key  = var.aws_secret_key
  jwt_secret      = var.jwt_secret
  github_owner    = var.github_owner
  github_token    = var.github_token
}