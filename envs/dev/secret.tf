data "github_repository" "repo" {
  full_name = "Thee5176/Accounting_CQRS_Project"
}

resource "github_repository_environment" "repo_environment" {
  repository  = data.github_repository.repo.name
  environment = "AWS and Supabase"
}

# EC2 Public IP
resource "github_actions_environment_secret" "ec2_public_ip" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.repo_environment.environment
  secret_name     = "EC2_PUBLIC_IP"
  plaintext_value = aws_instance.web_server.public_ip
}

# DB credentials
resource "github_actions_environment_secret" "db_username" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.repo_environment.environment
  secret_name     = "DB_USER"
  plaintext_value = var.db_username
}

resource "github_actions_environment_secret" "db_password" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.repo_environment.environment
  secret_name     = "DB_PASSWORD"
  plaintext_value = var.db_password
}
resource "github_actions_environment_secret" "db_connection_url" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.repo_environment.environment
  secret_name     = "DB_URL"
  plaintext_value = format("jdbc:postgresql://%s/%s", aws_db_instance.web_db.endpoint, var.db_schema)
}

resource "github_actions_environment_secret" "jwt_secret" {
  repository      = data.github_repository.repo.name
  environment     = github_repository_environment.repo_environment.environment
  secret_name     = "JWT_SECRET"
  plaintext_value = var.jwt_secret
}