variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
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

# ── Database ──────────────────────────────────────────────────────────────────

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "hybrid_mcp"
}

variable "db_user" {
  description = "PostgreSQL administrator username."
  type        = string
  default     = "mcpadmin"
}

variable "db_password" {
  description = "PostgreSQL administrator password."
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
