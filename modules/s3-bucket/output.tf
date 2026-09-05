output "bucket_name" {
  description = "Name of the S3 Bucket"
  value = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the S3 Bucket"
  value = aws_s3_bucket.this.arn
}
