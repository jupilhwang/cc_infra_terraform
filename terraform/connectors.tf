
# Debezium MySQL CDC Connector
# resource "confluent_connector" "mysql_cdc" {
#   environment {
#     id = confluent_environment.poc.id
#   }
#   kafka_cluster {
#     id = confluent_kafka_cluster.standard.id
#   }

#   config_sensitive = {
#     "database.password" = var.mysql_password
#   }

#   config_nonsensitive = {
#     "connector.class"                          = "MySqlCdcSourceV2"
#     "name"                                     = local.mysql_connector_name
#     "kafka.auth.mode"                          = "SERVICE_ACCOUNT"
#     "kafka.service.account.id"                 = confluent_service_account.app_manager.id
#     "database.hostname"                        = var.mysql_hostname
#     "database.port"                            = var.mysql_port
#     "database.user"                            = var.mysql_username
#     "database.server.id"                       = var.mysql_server_id
#     "database.server.name"                     = var.mysql_server_name
#     "database.include.list"                    = var.mysql_database_include_list
#     "table.include.list"                       = var.mysql_table_include_list
#     "database.history.kafka.bootstrap.servers" = confluent_kafka_cluster.standard.bootstrap_endpoint
#     "database.history.kafka.topic"             = "${var.mysql_server_name}.history"
#     "output.data.format"                       = "AVRO"
#     "output.key.format"                        = "AVRO"
#     "tasks.max"                                = "1"
#   }

#   depends_on = [
#     confluent_kafka_topic.mysql_cdc_topic,
#   ]
# }