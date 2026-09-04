terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_dynamodb_table" "links" {

  name = var.table_name
  billing_mode = var.billing_mode
  hash_key = "shortCode"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "shortCode"
    type = "S"
  }

  attribute {
    name = "ownerId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "N"
  }

  ttl {
    attribute_name = "expiresAt"
    enabled = true
  }

  global_secondary_index {

    name = "ownerId-createdAt-index"
    projection_type = "ALL"

    key_schema {
      attribute_name = "ownerId"
      key_type = "HASH"
    }

    key_schema {
      attribute_name = "createdAt"
      key_type       = "RANGE"
    }

  }

}

