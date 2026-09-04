terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

data "aws_iam_policy_document" "eks_assume_role" {

  statement {

    actions = ["sts:AssumeRole"]
    effect = "Allow"

    principals {
      identifiers = ["eks.amazonaws.com"]
      type = "Service"
    }

  }

}

resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = aws_iam_role.eks_cluster.name
}

resource "aws_vpc" "this" {

  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = var.cluster_name
  }

}

resource "aws_subnet" "this" {

  count = length(var.subnet_cidrs)
  vpc_id = aws_vpc.this.id
  cidr_block = var.subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.cluster_name}-subnet-${count.index}"
  }

}

resource "aws_eks_cluster" "this" {

  name = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = aws_subnet.this[*].id
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster]

}
