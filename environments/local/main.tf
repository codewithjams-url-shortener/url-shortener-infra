terraform {

  required_providers {

    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }

    random = {
      source = "hashicorp/random"
      version = "~> 3.6"
    }

  }

}

provider "aws" {

  region = "us-west-2"
  access_key = "test"
  secret_key = "test"
  skip_credentials_validation = true
  skip_requesting_account_id = true
  s3_use_path_style = true

  endpoints {
    dynamodb = "http://localhost:4566"
    s3 = "http://localhost:4566"
    sqs = "http://localhost:4566"
    sns = "http://localhost:4566"
    rds = "http://localhost:4566"
    elasticache = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    eks = "http://localhost:4566"
    iam = "http://localhost:4566"
    ec2 = "http://localhost:4566"
  }

}

module "eks_cluster" {
  source = "../../modules/eks-cluster"
  cluster_name = "url-shortener-local"
}

module "dynamodb_table" {
  source = "../../modules/dynamodb-table"
  table_name = "Links"
}

module "rds_postgres" {
  source = "../../modules/rds-postgres"
}

module "elasticache_redis" {
  source = "../../modules/elasticache-redis"
}

module "s3_bucket" {
  source = "../../modules/s3-bucket"
}

module "sns_sqs" {
  source = "../../modules/sns-sqs"
}
