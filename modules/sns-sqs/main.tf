terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_sns_topic" "click_events" {
  name = var.topic_name
}

resource "aws_sqs_queue" "click_events_dlq" {
  name = var.dlq_name
}

resource "aws_sqs_queue" "click_events" {

  name = var.queue_name
  visibility_timeout_seconds = 30
  message_retention_seconds = 86400

  redrive_policy = jsonencode(
    {
      deadLetterTargetArn = aws_sqs_queue.click_events_dlq.arn
      maxReceiveCount     = var.max_receive_count
    }
  )

}

resource "aws_sns_topic_subscription" "click_events" {
  topic_arn = aws_sns_topic.click_events.arn
  protocol = "sqs"
  endpoint = aws_sqs_queue.click_events.arn
}
