variable "cluster_name" {
  description = "Name of the EKS Cluster"
  type = string
}

variable "vpc_cidr" {
  description = "CIDR block for Cluster's VPC"
  type = string
  default = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for cluster's subnet, one per AZ"
  type = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "Availability Zones to spread out the subnets across"
  type = list(string)
  default = ["us-west-2a", "us-west-2b"]
}
