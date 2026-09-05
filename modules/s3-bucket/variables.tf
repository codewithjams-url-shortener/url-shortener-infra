variable "bucket_name" {
  description = "Name of the S3 Bucket where raw click events/lifecycle archive are stored"
  type = string
  default = "url-shortener-events"
}
