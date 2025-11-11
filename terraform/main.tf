# Confluent Cloud Provider
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.51.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# Environment
resource "confluent_environment" "main" {
  display_name = var.environment_name
}

# Standard Kafka Cluster
resource "confluent_kafka_cluster" "standard" {
  display_name = var.cluster_name
  availability = "SINGLE_ZONE"
  cloud        = var.cloud_provider
  region       = var.region
  standard {}

  environment {
    id = confluent_environment.main.id
  }
}

# Service Account for applications
resource "confluent_service_account" "app_manager" {
  display_name = var.app_service_account_name
  description  = "Service account for managing applications, connectors and environment resources"
}

# Role binding to make the service account admin of the Environment
resource "confluent_role_binding" "app_manager_env_admin" {
  principal   = "User:${confluent_service_account.app_manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.main.resource_name
}

# API Key for the service account
resource "confluent_api_key" "app_manager_kafka_api_key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key for app manager service account"

  owner {
    id          = confluent_service_account.app_manager.id
    api_version = confluent_service_account.app_manager.api_version
    kind        = confluent_service_account.app_manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.standard.id
    api_version = confluent_kafka_cluster.standard.api_version
    kind        = confluent_kafka_cluster.standard.kind

    environment {
      id = confluent_environment.main.id
    }
  }

  depends_on = [
    confluent_role_binding.app_manager_env_admin
  ]
}

# Kafka Topic for MySQL CDC
resource "confluent_kafka_topic" "mysql_cdc_topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }

  topic_name       = var.mysql_cdc_topic_name
  partitions_count = var.mysql_cdc_topic_partitions
}

# Kafka Topic for S3 sink
resource "confluent_kafka_topic" "s3_sink_topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }

  topic_name       = var.s3_sink_topic_name
  partitions_count = var.s3_sink_topic_partitions
}

# Kafka Topic for Logs
resource "confluent_kafka_topic" "logs_topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }

  topic_name       = var.logs_topic_name
  partitions_count = var.logs_topic_partitions

  config = {
    "retention.ms" = "-1"  # Infinite retention
  }
}

# Debezium MySQL CDC Connector
resource "confluent_connector" "mysql_cdc" {
  environment {
    id = confluent_environment.main.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }

  config_sensitive = {
    "database.password" = var.mysql_password
  }

  config_nonsensitive = {
    "connector.class"                    = "MySqlCdcSource"
    "name"                              = var.mysql_connector_name
    "kafka.auth.mode"                   = "SERVICE_ACCOUNT"
    "kafka.service.account.id"          = confluent_service_account.app_manager.id
    "database.hostname"                 = var.mysql_hostname
    "database.port"                     = var.mysql_port
    "database.user"                     = var.mysql_username
    "database.server.id"                = var.mysql_server_id
    "database.server.name"              = var.mysql_server_name
    "database.include.list"             = var.mysql_database_include_list
    "table.include.list"                = var.mysql_table_include_list
    "database.history.kafka.bootstrap.servers" = confluent_kafka_cluster.standard.bootstrap_endpoint
    "database.history.kafka.topic"     = "${var.mysql_server_name}.history"
    "output.data.format"                = "AVRO"
    "output.key.format"                 = "AVRO"
    "tasks.max"                         = "1"
  }

  depends_on = [
    confluent_kafka_topic.mysql_cdc_topic,
  ]
}

# S3 Sink Connector
resource "confluent_connector" "s3_sink" {
  environment {
    id = confluent_environment.main.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }

  config_sensitive = {
    "aws.access.key.id"     = var.aws_access_key_id
    "aws.secret.access.key" = var.aws_secret_access_key
  }

  config_nonsensitive = {
    "connector.class"               = "S3Sink"
    "name"                         = var.s3_connector_name
    "kafka.auth.mode"              = "SERVICE_ACCOUNT"
    "kafka.service.account.id"     = confluent_service_account.app_manager.id
    "topics"                       = var.s3_sink_topic_name
    "s3.bucket.name"               = var.s3_bucket_name
    "s3.region"                    = var.s3_region
    "input.data.format"            = "AVRO"
    "output.data.format"           = "PARQUET"
    "time.interval"                = "HOURLY"
    "flush.size"                   = "1000"
    "tasks.max"                    = "1"
    "s3.part.size"                 = "5242880"
    "s3.compression.type"          = "gzip"
    "behavior.on.null.values"      = "ignore"
    "behavior.on.malformed.data"   = "ignore"
    "parquet.codec"                = "gzip"
  }

  depends_on = [
    confluent_kafka_topic.s3_sink_topic,
  ]
}

# ACL for MySQL CDC topic
resource "confluent_kafka_acl" "mysql_cdc_topic_write" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }

  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.mysql_cdc_topic.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app_manager.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
}

resource "confluent_kafka_acl" "mysql_cdc_topic_read" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }

  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.mysql_cdc_topic.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app_manager.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
}

# ACL for S3 sink topic
resource "confluent_kafka_acl" "s3_sink_topic_read" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }

  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.s3_sink_topic.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app_manager.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
}

# ACL for consumer groups
resource "confluent_kafka_acl" "consumer_group" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }

  resource_type = "GROUP"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app_manager.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
}