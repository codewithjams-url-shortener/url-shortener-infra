output "cluster_name" {
  description = "Name of the EKS Cluster"
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "API Server Endpoint for the EKS Cluster"
  value = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster"
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "vpc_id" {
  description = "Unique Identifier of VPC created for this cluster"
  value = aws_vpc.this.id
}

output "subnet_ids" {
  description = "Unique Identifier of Subnets created for this cluster"
  value = aws_subnet.this[*].id
}
