resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = aws_subnet.private_db[*].id
  tags       = { Name = "${var.project_name}-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username

  # RDS generates the password and stores it in AWS Secrets Manager.
  # Nothing sensitive in Terraform code or state variables.
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false # DB must never be reachable from the internet
  multi_az               = false # set true for production HA

  backup_retention_period = 1 # free-plan accounts allow at most 1 day
  copy_tags_to_snapshot   = true

  # Lab-friendly teardown. For production: deletion_protection = true, skip_final_snapshot = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = { Name = "${var.project_name}-db" }
}
