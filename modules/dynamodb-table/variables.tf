variable "table_name" {
  description = "Name of the DynamoDB Links table"
  type = string
  default = "Links"
}

variable "billing_mode" {
  description = "DynamoDB Billing Mode"
  type = string
  default = "PAY_PER_REQUEST"
}
