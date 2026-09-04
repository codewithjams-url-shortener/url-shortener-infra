output "table_name" {
  description = "Name of the DynamoDB Links table"
  value = aws_dynamodb_table.links.name
}

output "table_arn" {
  description = "ARN of the DynamoDB Links table"
  value = aws_dynamodb_table.links.arn
}

output "stream_arn" {
  description = "ARN of the table's DynamoDB Stream, for the CDC consumer"
  value = aws_dynamodb_table.links.stream_arn
}
