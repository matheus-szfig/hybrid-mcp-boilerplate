subscription_id = "00000000-0000-0000-0000-000000000000" # replace with dev subscription ID

environment = "dev"
location    = "eastus"
app_name    = "hybrid-mcp"

db_name     = "hybrid_mcp"
db_user     = "mcpadmin"
db_password = "REPLACE_ME" # use a strong password or inject via CI secret

cors_allowed_origins = ["*"]
cors_allowed_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
cors_allowed_headers = ["*"]
