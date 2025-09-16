data "github_repository" "repo" {
  full_name = "Thee5176/Accounting_CQRS_Project"
}

resource "github_repository_environment" "dev_environment" {
  repository  = data.github_repository.repo.name
  environment = "Development"
}

# EC2 Public IP
resource "github_actions_environment_secret" "ec2_public_ip" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.dev_environment.environment
  secret_name     = "EC2_PUBLIC_IP"
  plaintext_value = aws_instance.web_server.public_ip
}

# Backend Database Secrets
resource "github_actions_environment_variable" "db_username" {
  repository    = data.github_repository.repo.name
  environment   = github_repository_environment.dev_environment.environment
  variable_name = "DB_USER"
  value         = var.db_username
}

resource "github_actions_environment_secret" "db_password" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.dev_environment.environment
  secret_name     = "DB_PASSWORD"
  plaintext_value = var.db_password
}
resource "github_actions_environment_secret" "db_connection_url" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.dev_environment.environment
  secret_name     = "DB_URL"
  plaintext_value = format("jdbc:postgresql://%s/%s", aws_db_instance.web_db.endpoint, var.db_schema)
}
resource "github_actions_environment_secret" "jwt_secret" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.dev_environment.environment
  secret_name     = "JWT_SECRET"
  plaintext_value = var.jwt_secret
}

# AWS Credentials
resource "github_actions_environment_secret" "aws_access_key_id" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.dev_environment.environment
  secret_name     = "AWS_ACCESS_KEY_ID"
  plaintext_value = var.aws_access_key
}

resource "github_actions_environment_secret" "aws_secret_access_key" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.dev_environment.environment
  secret_name     = "AWS_SECRET_ACCESS_KEY"
  plaintext_value = var.aws_secret_key
}

resource "github_actions_environment_variable" "aws_region" {
  repository    = data.github_repository.repo.name
  environment   = github_repository_environment.dev_environment.environment
  variable_name = "AWS_REGION"
  value         = var.aws_region
}

# Docker Hub Credentials
resource "github_actions_environment_variable" "dockerhub_username" {
  repository    = data.github_repository.repo.name
  environment   = github_repository_environment.dev_environment.environment
  variable_name = "DOCKERHUB_USERNAME"
  value         = var.dockerhub_username
}

resource "github_actions_environment_secret" "dockerhub_token" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.dev_environment.environment
  secret_name     = "DOCKERHUB_TOKEN"
  plaintext_value = var.dockerhub_token
}

resource "github_actions_environment_secret" "github_token" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.dev_environment.environment
  secret_name     = "EC2_SSH_PRIVATE_KEY"
  plaintext_value = var.ec2_private_key
}