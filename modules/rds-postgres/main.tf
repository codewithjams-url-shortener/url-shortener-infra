resource "random_password" "master" {

  length = 24
  special = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"

}

resource "aws_db_instance" "this" {

  identifier = var.db_identifier
  engine = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  allocated_storage = var.allocated_storage
  db_name = var.db_name
  username = var.username
  password = random_password.master.result
  skip_final_snapshot = true

}

resource "aws_secretsmanager_secret" "rds_master" {

  name = "${var.db_identifier}-master-credentials"

}

resource "aws_secretsmanager_secret_version" "rds_master" {

  secret_id = aws_secretsmanager_secret.rds_master.id

  secret_string = jsonencode(
    {
      username = var.username
      password = random_password.master.result
      engine = "postgres"
      host = aws_db_instance.this.address
      port = aws_db_instance.this.port
      dbname = var.db_name
    }
  )

}
