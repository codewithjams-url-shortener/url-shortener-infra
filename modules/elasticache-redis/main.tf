terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_elasticache_replication_group" "this" {

  replication_group_id = var.replication_group_id
  description = "Redis Cache for Redirect Service (link lookups, rate-limiting)"
  engine = "redis"
  node_type = var.node_type
  num_cache_clusters = 1
  port = var.port

  lifecycle {
    ignore_changes = [num_cache_clusters]
  }

}
