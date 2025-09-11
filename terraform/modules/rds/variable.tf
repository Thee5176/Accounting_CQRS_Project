variable "db_username" {
  description = "RDS root username for the database"
  type        = string
  sensitive   = false
}

variable "db_password" {
  description = "RDS root password for the database."
  type        = string
  sensitive   = true
}

variable "db_schema" {
  description = "RDS database name to be created."
  type        = string
  sensitive   = false
}