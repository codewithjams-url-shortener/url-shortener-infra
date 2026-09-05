output "topic_arn" {
  description = "ARN of the click-events SNS topic — Redirect Service publishes here"
  value = aws_sns_topic.click_events.arn
}

output "queue_url" {
  description = "URL of the click-events SQS queue — Analytics Service consumes from here"
  value = aws_sqs_queue.click_events.url
}

output "queue_arn" {
  description = "ARN of the click-events SQS queue"
  value = aws_sqs_queue.click_events.arn
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue, for future monitoring/alerting on failed message processing"
  value       = aws_sqs_queue.click_events_dlq.arn
}
