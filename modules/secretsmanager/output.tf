output "secret_arn" {
  description = "ARN of the placeholder app-level secret — the reference ESO's ClusterSecretStore/ExternalSecret resources will point at"
  value = aws_secretsmanager_secret.app.arn
}

output "secret_name" {
  description = "Name of the placeholder app-level secret"
  value = aws_secretsmanager_secret.app.name
}
