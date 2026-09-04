provider "aws" {
  region = "us-west-2"
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_requesting_account_id = true
  s3_use_path_style = true

  endpoints {
    rds = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
  }
}

run "creates_db_with_credentials_in_secrets_manager" {

  command = apply

  variables {
    db_identifier = "test-rds-postgres"
  }

  assert {
    condition = output.db_name == "url_shortener"
    error_message = "Expected the default db_name to be used"
  }

  assert {
    condition = output.db_endpoint != ""
    error_message = "Expected a database endpoint"
  }

  assert {
    condition = output.secret_arn != ""
    error_message = "Expected a Secrets Manager secret ARN"
  }

}
