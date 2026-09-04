output "db_endpoint" {
  description = "Connection endpoint (host:port) for the database"
  value = aws_db_instance.this.endpoint
}

output "db_address" {
  description = "Hostname of the database, without the port"
  value = aws_db_instance.this.address
}

output "db_port" {
  description = "Port the database is listening on"
  value = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial database"
  value = aws_db_instance.this.db_name
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret holding the master credentials"
  value = aws_secretsmanager_secret.rds_master.arn
}
