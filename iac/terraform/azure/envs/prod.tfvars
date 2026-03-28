subscription_id = "00000000-0000-0000-0000-000000000000" # replace with prod subscription ID

environment = "prod"
location    = "eastus"
app_name    = "hybrid-mcp"

db_name     = "hybrid_mcp"
db_user     = "mcpadmin"
db_password = "REPLACE_ME" # injected via CI secret — do not commit real value

cors_allowed_origins = ["https://your-domain.com"] # replace with real origins
cors_allowed_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
cors_allowed_headers = ["*"]
