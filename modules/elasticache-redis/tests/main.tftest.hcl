provider "aws" {

  region = "us-west-2"
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_requesting_account_id = true
  s3_use_path_style = true

  endpoints {
    elasticache = "http://localhost:4566"
  }

}

run "creates_redis_replication_group" {

  command = apply

  variables {
    replication_group_id = "test-redis"
  }

  assert {
    condition = output.cache_endpoint != ""
    error_message = "Expected a non-empty cache endpoint"
  }

  assert {
    condition = output.cache_port == 6379
    error_message = "Expected the default Redis port"
  }

}
