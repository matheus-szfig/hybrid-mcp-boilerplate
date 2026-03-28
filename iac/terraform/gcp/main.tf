locals {
  prefix = "${var.app_name}-${var.environment}"
}

# ── Enable required APIs ──────────────────────────────────────────────────────

resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sql" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# ── Artifact Registry ─────────────────────────────────────────────────────────
# Repository to push container images into before deploying Cloud Run.

resource "google_artifact_registry_repository" "main" {
  repository_id = local.prefix
  location      = var.region
  format        = "DOCKER"

  depends_on = [google_project_service.artifactregistry]
}

# ── Cloud SQL PostgreSQL ──────────────────────────────────────────────────────
# db-f1-micro — cheapest shared-core tier (~$7/month).
# No HA, single zone, public IP with SSL required.

resource "google_sql_database_instance" "main" {
  name             = local.prefix
  database_version = "POSTGRES_16"
  region           = var.region

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"

    backup_configuration {
      enabled = true
    }

    ip_configuration {
      ipv4_enabled = true

      # Allow Cloud Run to connect via public IP
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }
  }

  deletion_protection = false

  depends_on = [google_project_service.sql]
}

resource "google_sql_database" "main" {
  name     = var.db_name
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "main" {
  name     = var.db_user
  instance = google_sql_database_instance.main.name
  password = var.db_password
}

# ── Cloud Run ─────────────────────────────────────────────────────────────────
# min-instances = 1 prevents cold starts.
# Requires a container image — build and push to Artifact Registry first.

resource "google_cloud_run_v2_service" "main" {
  name     = local.prefix
  location = var.region

  template {
    scaling {
      min_instance_count = 1
    }

    containers {
      image = var.container_image

      ports {
        container_port = 8000
      }

      env {
        name  = "APP_NAME"
        value = var.app_name
      }
      env {
        name  = "DATABASE_HOST"
        value = google_sql_database_instance.main.public_ip_address
      }
      env {
        name  = "DATABASE_PORT"
        value = "5432"
      }
      env {
        name  = "DATABASE_NAME"
        value = var.db_name
      }
      env {
        name  = "DATABASE_USER"
        value = var.db_user
      }
      env {
        name  = "DATABASE_PASSWORD"
        value = var.db_password
      }
      env {
        name  = "CORS_ALLOWED_ORIGINS"
        value = jsonencode(var.cors_allowed_origins)
      }
      env {
        name  = "CORS_ALLOWED_METHODS"
        value = jsonencode(var.cors_allowed_methods)
      }
      env {
        name  = "CORS_ALLOWED_HEADERS"
        value = jsonencode(var.cors_allowed_headers)
      }
    }
  }

  depends_on = [google_project_service.run]
}

# Allow unauthenticated (public) access to Cloud Run
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.main.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
