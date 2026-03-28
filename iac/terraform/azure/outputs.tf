output "app_url" {
  description = "Public URL of the deployed App Service."
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "mcp_sse_url" {
  description = "MCP SSE endpoint URL."
  value       = "https://${azurerm_linux_web_app.main.default_hostname}/mcp/sse"
}

output "db_host" {
  description = "PostgreSQL Flexible Server FQDN."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "db_name" {
  description = "PostgreSQL database name."
  value       = var.db_name
}
