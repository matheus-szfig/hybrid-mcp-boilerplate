from pydantic import ConfigDict
from pydantic_settings import BaseSettings


def _config(prefix: str = "") -> ConfigDict:
    return ConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
        env_prefix=prefix,
    )


########## INTEGRATIONS ##########

class _SharepointIntegration(BaseSettings):
    model_config = _config("SHAREPOINT_")

    client_id: str | None = None
    client_secret: str | None = None
    tenant_id: str | None = None
    site_url: str | None = None
    file_path: str | None = None

class _Integrations(BaseSettings):
    model_config = _config()

    sharepoint: _SharepointIntegration = _SharepointIntegration()

########## CORS ##########

class _Cors(BaseSettings):
    model_config = _config("CORS_")

    allowed_origins: list[str]
    allowed_methods: list[str]
    allowed_headers: list[str]

########## DATABASE ##########

class _Database(BaseSettings):
    model_config = _config("DATABASE_")

    host: str
    port: int = 5432
    name: str
    user: str
    password: str

########## SETTINGS ##########

class _Settings(BaseSettings):
    model_config = _config()

    app_name: str

    cors: _Cors = _Cors()
    database: _Database = _Database()
    integrations: _Integrations = _Integrations()

settings: _Settings = _Settings()