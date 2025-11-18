# Environment Outputs
output "environment_id" {
  description = "The ID of the Confluent Cloud environment"
  value       = confluent_environment.poc.id
}

output "environment_name" {
  description = "The name of the Confluent Cloud environment"
  value       = confluent_environment.poc.display_name
}

# Kafka Cluster Outputs
output "kafka_cluster_id" {
  description = "The ID of the Kafka cluster"
  value       = confluent_kafka_cluster.standard.id
}

output "kafka_cluster_bootstrap_endpoint" {
  description = "The bootstrap endpoint used by Kafka clients to connect to the Kafka cluster"
  value       = confluent_kafka_cluster.standard.bootstrap_endpoint
}

output "kafka_cluster_rest_endpoint" {
  description = "The REST Endpoint of the Kafka cluster"
  value       = confluent_kafka_cluster.standard.rest_endpoint
}

# Service Account Outputs
output "service_account_id" {
  description = "The ID of the service account"
  value       = confluent_service_account.app_manager.id
}

output "kafka_api_key" {
  description = "The Kafka API Key for the service account"
  value       = confluent_api_key.app_manager_kafka_api_key.id
  sensitive   = true
}

output "kafka_api_secret" {
  description = "The Kafka API Secret for the service account"
  value       = confluent_api_key.app_manager_kafka_api_key.secret
  sensitive   = true
}

output "schema_registry_api_key" {
  description = "Schema Registry API Key for the service account"
  value       = confluent_api_key.schema_registry_api_key.id
  sensitive   = true
}

output "schema_registry_api_secret" {
  description = "Schema Registry API Secret for the service account"
  value       = confluent_api_key.schema_registry_api_key.secret
  sensitive   = true
}

# # Topic Outputs
# # Connector Outputs
# output "mysql_connector_id" {
#   description = "The ID of the MySQL CDC connector"
#   value       = confluent_connector.mysql_cdc.id
# }

# # Connector Status URLs (for manual checking)
# output "mysql_connector_status_url" {
#   description = "URL to check MySQL connector status"
#   value       = "https://confluent.cloud/environments/${confluent_environment.poc.id}/clusters/${confluent_kafka_cluster.standard.id}/connectors/${confluent_connector.mysql_cdc.id}"
# }
