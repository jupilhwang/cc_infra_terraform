# Confluent Cloud API Credentials
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

# Environment Configuration
variable "environment_name" {
  description = "Name of the Confluent Cloud environment"
  type        = string
  default     = "production-env"
}

# Kafka Cluster Configuration
variable "cluster_name" {
  description = "Name of the Kafka cluster"
  type        = string
  default     = "kafka-cluster"
}

variable "cloud_provider" {
  description = "Cloud provider (AWS, GCP, or AZURE)"
  type        = string
  default     = "AWS"
}

variable "region" {
  description = "Cloud provider region"
  type        = string
  default     = "us-east-1"
}

# Service Account Configuration
variable "app_service_account_name" {
  description = "Name of the application service account"
  type        = string
  default     = "app-manager"
}

# Kafka Topics Configuration
variable "mysql_cdc_topic_name" {
  description = "Name of the MySQL CDC topic"
  type        = string
  default     = "mysql-cdc-events"
}

variable "mysql_cdc_topic_partitions" {
  description = "Number of partitions for MySQL CDC topic"
  type        = number
  default     = 6
}

variable "s3_sink_topic_name" {
  description = "Name of the S3 sink topic"
  type        = string
  default     = "s3-sink-events"
}

variable "s3_sink_topic_partitions" {
  description = "Number of partitions for S3 sink topic"
  type        = number
  default     = 6
}

variable "logs_topic_name" {
  description = "Name of the logs topic"
  type        = string
  default     = "logs"
}

variable "logs_topic_partitions" {
  description = "Number of partitions for logs topic"
  type        = number
  default     = 6
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

# MySQL Connector Configuration
variable "mysql_connector_name" {
  description = "Name of the MySQL CDC connector"
  type        = string
  default     = "mysql-cdc"
}

# S3 Configuration
variable "s3_bucket_name" {
  description = "S3 bucket name for data storage"
  type        = string
}

variable "s3_region" {
  description = "S3 bucket region"
  type        = string
  default     = "us-east-1"
}

variable "aws_access_key_id" {
  description = "AWS access key ID"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS secret access key"
  type        = string
  sensitive   = true
}

# S3 Connector Configuration
variable "s3_connector_name" {
  description = "Name of the S3 sink connector"
  type        = string
  default     = "s3-sink"
}