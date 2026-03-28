output "app_url" {
  description = "Public URL of the Elastic Beanstalk environment."
  value       = "http://${aws_elastic_beanstalk_environment.main.cname}"
}

output "db_host" {
  description = "RDS PostgreSQL endpoint."
  value       = aws_db_instance.main.address
}

output "db_name" {
  description = "PostgreSQL database name."
  value       = var.db_name
}
