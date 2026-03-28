variable "project_id" {
  description = "GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region for all resources."
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Deployment environment (dev, prod)."
  type        = string
}

variable "app_name" {
  description = "Application name — used in resource names and APP_NAME env var."
  type        = string
  default     = "hybrid-mcp"
}

variable "container_image" {
  description = "Full container image URL (e.g. us-central1-docker.pkg.dev/project/repo/app:tag)."
  type        = string
}

# ── Database ──────────────────────────────────────────────────────────────────

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "hybrid_mcp"
}

variable "db_user" {
  description = "PostgreSQL user name."
  type        = string
  default     = "mcpadmin"
}

variable "db_password" {
  description = "PostgreSQL user password."
  type        = string
  sensitive   = true
}

# ── CORS ─────────────────────────────────────────────────────────────────────

variable "cors_allowed_origins" {
  description = "List of allowed CORS origins."
  type        = list(string)
  default     = ["*"]
}

variable "cors_allowed_methods" {
  description = "List of allowed CORS methods."
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
}

variable "cors_allowed_headers" {
  description = "List of allowed CORS headers."
  type        = list(string)
  default     = ["*"]
}
