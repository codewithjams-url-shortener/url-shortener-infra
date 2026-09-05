variable "replication_group_id" {
  description = "Unique Identifier of the Redis replication group"
  type = string
  default = "url-shortener-redis"
}

variable "node_type" {
  description = "Cache Node instance type"
  type = string
  default = "cache.t3.micro"
}

variable "port" {
  description = "Port Redis listens on"
  type = number
  default = 6379
}
