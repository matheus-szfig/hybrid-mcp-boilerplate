output "app_url" {
  description = "Public URL of the Cloud Run service."
  value       = google_cloud_run_v2_service.main.uri
}

output "mcp_sse_url" {
  description = "MCP SSE endpoint URL."
  value       = "${google_cloud_run_v2_service.main.uri}/mcp/sse"
}

output "db_host" {
  description = "Cloud SQL PostgreSQL public IP."
  value       = google_sql_database_instance.main.public_ip_address
}

output "artifact_registry_repo" {
  description = "Artifact Registry repository URL for pushing container images."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${local.prefix}"
}
