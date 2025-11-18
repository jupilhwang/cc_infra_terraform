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

locals {
  schema_registry_package = upper(var.schema_registry_package)

  resource_prefix = trimspace(var.project_name) == "" ? "" : "${trimspace(var.project_name)}-"

  environment_name                     = "${local.resource_prefix}env"
  kafka_cluster_name                   = "${local.resource_prefix}kafka-cluster"
  flink_compute_name                   = "${local.resource_prefix}flink-compute"
  service_account_name                 = "${local.resource_prefix}sa"
  api_key_display_name                 = "${local.resource_prefix}app-manager-kafka-api-key"
  schema_registry_api_key_display_name = "${local.resource_prefix}schema-registry-api-key"
  logs_topic_name                      = "${local.resource_prefix}logs"
  mysql_connector_name                 = "${local.resource_prefix}mysql-connector"
}

# Environment
resource "confluent_environment" "poc" {
  display_name = local.environment_name
  stream_governance {
    package = local.schema_registry_package
  }
}

data "confluent_schema_registry_cluster" "poc" {
  environment {
    id = confluent_environment.poc.id
  }
}

# Standard Kafka Cluster
resource "confluent_kafka_cluster" "standard" {
  display_name = local.kafka_cluster_name
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = var.cloud_region
  standard {}

  environment {
    id = confluent_environment.poc.id
  }
}

# Service Account for applications
resource "confluent_service_account" "app_manager" {
  display_name = local.service_account_name
  description  = "Service account for managing applications, connectors and environment resources"
}

# Role binding to make the service account admin of the Environment
resource "confluent_role_binding" "app_manager_env_admin" {
  principal   = "User:${confluent_service_account.app_manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.poc.resource_name
}

# API Key for the service account
resource "confluent_api_key" "app_manager_kafka_api_key" {
  display_name = local.api_key_display_name
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
      id = confluent_environment.poc.id
    }
  }

  depends_on = [
    confluent_role_binding.app_manager_env_admin
  ]
}

resource "confluent_api_key" "schema_registry_api_key" {
  display_name = local.schema_registry_api_key_display_name
  description  = "Schema Registry API Key for app manager service account"

  owner {
    id          = confluent_service_account.app_manager.id
    api_version = confluent_service_account.app_manager.api_version
    kind        = confluent_service_account.app_manager.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.poc.id
    api_version = data.confluent_schema_registry_cluster.poc.api_version
    kind        = data.confluent_schema_registry_cluster.poc.kind

    environment {
      id = confluent_environment.poc.id
    }
  }

  depends_on = [
    confluent_role_binding.app_manager_env_admin
  ]
}

# ACL for topic
resource "confluent_kafka_acl" "topic_write" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }

  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.app_manager.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
}
resource "confluent_kafka_acl" "topic_read" {
  kafka_cluster {
    id = confluent_kafka_cluster.standard.id
  }
  rest_endpoint = confluent_kafka_cluster.standard.rest_endpoint
  credentials {
    key    = confluent_api_key.app_manager_kafka_api_key.id
    secret = confluent_api_key.app_manager_kafka_api_key.secret
  }

  resource_type = "TOPIC"
  resource_name = "*"
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