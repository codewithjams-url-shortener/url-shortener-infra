output "cache_endpoint" {
  description = "Address to connect to the Redis replication group"
  value = coalesce(
    aws_elasticache_replication_group.this.primary_endpoint_address,
    aws_elasticache_replication_group.this.configuration_endpoint_address
  )
}

output "cache_port" {
  description = "Port Redis is listening on"
  value = aws_elasticache_replication_group.this.port
}
