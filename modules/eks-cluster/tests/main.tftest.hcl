provider "aws" {

  region                      = "us-west-2"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    iam = "http://localhost:4566"
    ec2 = "http://localhost:4566"
    eks = "http://localhost:4566"
  }

}

run "creates_cluster_with_expected_name" {

  command = apply

  variables {
    cluster_name = "test-eks-cluster"
  }

  assert {
    condition = output.cluster_name == "test-eks-cluster"
    error_message = "Cluster name did not match the input variable"
  }

  assert {
    condition = length(output.subnet_ids) == 2
    error_message = "Expected two subnets to be created"
  }

  assert {
    condition = output.vpc_id != ""
    error_message = "Expected a VPC to be created"
  }

}
