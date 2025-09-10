variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}
variable "db_username" {
  description = "RDS root username for the database"
  type        = string
  default     = "db_master"
}

variable "db_password" {
  description = "RDS root password for the database."
  type        = string
  sensitive   = true
}

variable "db_schema" {
  description = "RDS database name to be created."
  type        = string
  default     = "record"
}

variable "jwt_secret" {
  description = "Secret key for signing JWT tokens"
  type        = string
  sensitive   = true
}
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "Thee5176"
}
variable "github_token" {
  description = "GitHub token with repo and admin:repo_hook permissions"
  type        = string
  sensitive   = true
}