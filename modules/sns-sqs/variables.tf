variable "topic_name" {
  description = "Name of the click-events SNS Topic"
  type = string
  default = "click-events"
}

variable "queue_name" {
  description = "Name of the SQS queue subscribed to the click-events topic"
  type = string
  default = "click-events-queue"
}

variable "dlq_name" {
  description = "Name of the Dead Letter Queue for failed message processing"
  type = string
  default = "click-events-dlq"
}

variable "max_receive_count" {
  description = "Number of processing attempts before a message moves to the DLQ"
  type = number
  default = 3
}
