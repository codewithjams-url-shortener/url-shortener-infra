provider "aws" {

  region = "us-west-2"
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_requesting_account_id = true
  s3_use_path_style = true

  endpoints {
    s3 = "http://localhost:4566"
  }

}

run "creates_bucket" {

  command = apply

  variables {
    bucket_name = "test-url-shortener-events"
  }

  assert {
    condition = output.bucket_name == "test-url-shortener-events"
    error_message = "Bucket name did not match the input variable"
  }

  assert {
    condition = output.bucket_arn == "arn:aws:s3:::test-url-shortener-events"
    error_message = "Bucket ARN did not match the expected format"
  }

}
