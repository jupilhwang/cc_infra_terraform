# Confluent Cloud API Credentials
variable "project_name" {
  description = "Project name prefix applied to all managed Confluent resource names"
  type        = string
  default     = "bunjang-poc"

  validation {
    condition     = trimspace(var.project_name) != ""
    error_message = "project_name cannot be empty."
  }
}

variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "cloud_region" {
  description = "Cloud provider region"
  type        = string
  default     = "us-east-1"
}

variable "schema_registry_package" {
  description = "Schema Governance package for Schema Registry (ESSENTIALS or ADVANCED)"
  type        = string
  default     = "ADVANCED"

  validation {
    condition     = contains(["ESSENTIALS", "ADVANCED"], upper(var.schema_registry_package))
    error_message = "schema_registry_package must be either ESSENTIALS or ADVANCED."
  }
}

# MySQL Database Configuration
variable "mysql_hostname" {
  description = "MySQL database hostname"
  type        = string
}

variable "mysql_port" {
  description = "MySQL database port"
  type        = string
  default     = "3306"
}

variable "mysql_username" {
  description = "MySQL database username"
  type        = string
}

variable "mysql_password" {
  description = "MySQL database password"
  type        = string
  sensitive   = true
}

variable "mysql_server_id" {
  description = "MySQL server ID for CDC"
  type        = string
  default     = "1001"
}

variable "mysql_server_name" {
  description = "MySQL server name for CDC"
  type        = string
  default     = "mysql-server"
}

variable "mysql_database_include_list" {
  description = "Comma-separated list of databases to include in CDC"
  type        = string
  default     = "production"
}

variable "mysql_table_include_list" {
  description = "Comma-separated list of tables to include in CDC (format: database.table)"
  type        = string
  default     = "production.users,production.products,production.orders"
}
