variable "db_identifier" {
  description = "RDS instance identifier"
  type = string
  default = "url-shortener-postgres"
}

variable "db_name" {
  description = "Name of the initial database created on the instance"
  type = string
  default = "url_shortener"
}

variable "username" {
  description = "Master username for the database"
  type = string
  default = "url_shortener_admin"
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type = string
  default = "15"
}

variable "instance_class" {
  description = "RDS instance class"
  type = string
  default = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type = number
  default = 20
}
