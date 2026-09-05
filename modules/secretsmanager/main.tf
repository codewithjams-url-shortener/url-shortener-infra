resource "aws_secretsmanager_secret" "app" {
  name = var.secret_name
  description = "Placeholder for future app-level secrets synced into Kubernetes via ESO (ADR-0009)"
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode(
    {
      placeholder = true
    }
  )
}
