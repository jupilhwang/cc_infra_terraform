# Environment Outputs
output "environment_id" {
  description = "The ID of the Confluent Cloud environment"
  value       = confluent_environment.main.id
}

output "environment_name" {
  description = "The name of the Confluent Cloud environment"
  value       = confluent_environment.main.display_name
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

# Topic Outputs
output "mysql_cdc_topic_name" {
  description = "The name of the MySQL CDC topic"
  value       = confluent_kafka_topic.mysql_cdc_topic.topic_name
}

output "s3_sink_topic_name" {
  description = "The name of the S3 sink topic"
  value       = confluent_kafka_topic.s3_sink_topic.topic_name
}

output "logs_topic_name" {
  description = "The name of the logs topic"
  value       = confluent_kafka_topic.logs_topic.topic_name
}

# Connector Outputs
output "mysql_connector_id" {
  description = "The ID of the MySQL CDC connector"
  value       = confluent_connector.mysql_cdc.id
}

output "s3_connector_id" {
  description = "The ID of the S3 sink connector"
  value       = confluent_connector.s3_sink.id
}

# Connector Status URLs (for manual checking)
output "mysql_connector_status_url" {
  description = "URL to check MySQL connector status"
  value       = "https://confluent.cloud/environments/${confluent_environment.main.id}/clusters/${confluent_kafka_cluster.standard.id}/connectors/${confluent_connector.mysql_cdc.id}"
}

output "s3_connector_status_url" {
  description = "URL to check S3 connector status"
  value       = "https://confluent.cloud/environments/${confluent_environment.main.id}/clusters/${confluent_kafka_cluster.standard.id}/connectors/${confluent_connector.s3_sink.id}"
}