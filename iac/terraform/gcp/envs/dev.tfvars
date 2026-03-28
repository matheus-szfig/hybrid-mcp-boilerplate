project_id      = "your-gcp-project-id"   # replace with your GCP project ID
region          = "us-central1"
environment     = "dev"
app_name        = "hybrid-mcp"
container_image = "us-central1-docker.pkg.dev/your-project/hybrid-mcp-dev/app:latest"

db_name     = "hybrid_mcp"
db_user     = "mcpadmin"
db_password = "REPLACE_ME"

cors_allowed_origins = ["*"]
cors_allowed_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
cors_allowed_headers = ["*"]
