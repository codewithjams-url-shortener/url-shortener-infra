provider "aws" {
  region = "us-west-2"
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_requesting_account_id = true
  s3_use_path_style = true

  endpoints {
    secretsmanager = "http://localhost:4566"
  }

}

run "creates_placeholder_secret" {

  command = apply

  variables {
    secret_name = "test-app-secrets"
  }

  assert {
    condition = output.secret_name == "test-app-secrets"
    error_message = "Secret name did not match the input variable"
  }

  assert {
    condition = output.secret_arn != ""
    error_message = "Expected a non-empty secret ARN"
  }

}
