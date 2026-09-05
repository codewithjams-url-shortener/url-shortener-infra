provider "aws" {

  region = "us-west-2"
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_requesting_account_id = true
  s3_use_path_style = true

  endpoints {
    sns = "http://localhost:4566"
    sqs = "http://localhost:4566"
  }

}

run "creates_topic_queue_and_dlq" {

  command = apply

  variables {
    topic_name = "test-click-events"
    queue_name = "test-click-events-queue"
    dlq_name   = "test-click-events-dlq"
  }

  assert {
    condition     = output.topic_arn != ""
    error_message = "Expected a non-empty topic ARN"
  }

  assert {
    condition     = output.queue_url != ""
    error_message = "Expected a non-empty queue URL"
  }

  assert {
    condition     = output.queue_arn != ""
    error_message = "Expected a non-empty queue ARN"
  }

  assert {
    condition     = output.dlq_arn != ""
    error_message = "Expected a non-empty DLQ ARN"
  }

}
