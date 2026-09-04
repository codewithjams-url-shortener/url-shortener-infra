provider "aws" {

  region = "us-west-2"
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_requesting_account_id = true
  s3_use_path_style = true

  endpoints {
    dynamodb = "http://localhost:4566"
  }

}

run "create_tables_with_stream_and_gsi" {

  command = apply

  variables {
    table_name = "test-links-table"
  }

  assert {
    condition = output.table_name == "test-links-table"
    error_message = "Table name did not match the input variable"
  }

  assert {
    condition = output.table_arn != ""
    error_message = "Expected a table ARN"
  }

  assert {
    condition = output.stream_arn != ""
    error_message = "Expected a stream ARN, since stream_enabled = true"
  }

}
