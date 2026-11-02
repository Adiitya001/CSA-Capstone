output "alb_dns_name" {
  description = "Open this URL in a browser to test the app"
  value       = "http://${aws_lb.app.dns_name}"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "app_instance_id" {
  description = "Connect with: aws ssm start-session --target <id>"
  value       = aws_instance.app.id
}

output "app_private_ip" {
  value = aws_instance.app.private_ip
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "rds_publicly_accessible" {
  value = aws_db_instance.main.publicly_accessible
}

output "rds_secret_arn" {
  description = "Secrets Manager secret holding the generated DB password"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "flow_log_group" {
  value = aws_cloudwatch_log_group.flow_logs.name
}

output "cloudtrail_bucket" {
  value = aws_s3_bucket.cloudtrail.id
}
