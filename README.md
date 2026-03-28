# Hybrid MCP Boilerplate

A boilerplate for building **hybrid MCP (Model Context Protocol) servers** — a single deployable app that exposes both a standard REST API (FastAPI) and an MCP server over SSE on the same process. AI clients connect to the MCP endpoint; humans and integrations use the REST API. Both share the same business logic.

## What this is

```
main.py                        # entry point — mounts MCP SSE onto FastAPI
src/
  settings.py                  # typed env-var config with pydantic-settings
  api/
    app.py                     # FastAPI instance + CORS + router registration
    routers/
      words.py                 # example: CRUD REST endpoints
  mcp/
    app.py                     # FastMCP instance
    tools/
      words.py                 # example: same CRUD exposed as MCP tools
  services/
    words.py                   # business logic — shared by REST and MCP
iac/
  terraform/                   # Azure infrastructure (App Service + PostgreSQL)
  scripts/bootstrap.sh         # one-time state storage setup
.github/workflows/
  iac-plan.yml                 # terraform plan on PR
  iac-deploy.yml               # terraform apply on merge
```

**Stack:** Python 3.12, FastAPI, FastMCP, Pydantic v2, uv, Alembic, PostgreSQL  
**Deploy:** Azure App Service (Basic B1, always-on) + PostgreSQL Flexible Server  
**IaC:** Terraform with per-subscription environments and GitHub Actions CI/CD

---

## Setup

### Prerequisites

- [Python 3.12+](https://www.python.org/downloads/)
- [uv](https://docs.astral.sh/uv/getting-started/installation/) — `curl -LsSf https://astral.sh/uv/install.sh | sh`
- [Git](https://git-scm.com/)

### 1. Clone and install

```bash
git clone <your-repo-url>
cd hybrid-mcp
uv sync
```

### 2. Configure environment

Copy the example env and fill in your values:

```bash
cp .env.example .env
```

`.env` values:

```env
# App
APP_NAME=hybrid-mcp

# CORS
CORS_ALLOWED_ORIGINS=["http://localhost:3000"]
CORS_ALLOWED_METHODS=["GET","POST","PUT","DELETE","OPTIONS"]
CORS_ALLOWED_HEADERS=["*"]

# Database
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=hybrid_mcp
DATABASE_USER=postgres
DATABASE_PASSWORD=secret

# Sharepoint (optional integration)
SHAREPOINT_CLIENT_ID=
SHAREPOINT_CLIENT_SECRET=
SHAREPOINT_TENANT_ID=
SHAREPOINT_SITE_URL=
SHAREPOINT_FILE_PATH=
```

### 3. Run locally

```bash
uv run uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

| Endpoint | Description |
|---|---|
| `http://localhost:8000/docs` | REST API docs (Swagger UI) |
| `http://localhost:8000/api/words/` | Example words CRUD |
| `http://localhost:8000/mcp/sse` | MCP SSE stream |

### 4. Test the MCP connection

Use the official MCP inspector:

```bash
npx @modelcontextprotocol/inspector http://localhost:8000/mcp/sse
```

It opens a browser UI where you can browse and call all registered MCP tools.

---

## Making changes

### Adding a new feature (REST + MCP)

Every feature follows the same three-file pattern:

#### 1. Create the service — `src/services/<feature>.py`

Pure business logic, no HTTP or MCP concerns:

```python
def list_items() -> list[str]:
    ...

def add_item(item: str) -> list[str]:
    ...
```

#### 2. Create the REST router — `src/api/routers/<feature>.py`

```python
from fastapi import APIRouter
from src.services.<feature> import list_items, add_item

router = APIRouter(prefix="/<feature>", tags=["<feature>"])

@router.get("/", response_model=list[str])
def get_items():
    return list_items()

@router.post("/", response_model=list[str], status_code=201)
def create_item(body: ItemBody):
    return add_item(body.item)
```

Register it in `src/api/app.py`:

```python
from src.api.routers.<feature> import router as feature_router

api_router.include_router(feature_router)
```

#### 3. Create the MCP tools — `src/mcp/tools/<feature>.py`

```python
from mcp.server.fastmcp import FastMCP
from src.services.<feature> import list_items, add_item

def register_feature_tools(server: FastMCP) -> None:

    @server.tool()
    def feature_list() -> list[str]:
        """List all items."""
        return list_items()

    @server.tool()
    def feature_add(item: str) -> list[str]:
        """Add an item."""
        return add_item(item)
```

Register it in `src/mcp/app.py`:

```python
from src.mcp.tools.<feature> import register_feature_tools

register_feature_tools(mcp)
```

### Adding environment variables

Add new settings to `src/settings.py`. Each nested class is a standalone `BaseSettings` that reads its own prefixed env vars independently:

```python
class _MyIntegration(BaseSettings):
    model_config = _config("MY_INTEGRATION_")

    api_key: str
    base_url: str = "https://api.example.com"
```

Then add it to `_Settings`:

```python
class _Settings(BaseSettings):
    ...
    my_integration: _MyIntegration = _MyIntegration()
```

Access anywhere via `from src.settings import settings` → `settings.my_integration.api_key`.

### Database migrations

Migrations use [Alembic](https://alembic.sqlalchemy.org/). From the project root:

```bash
# Create a new migration
uv run alembic revision --autogenerate -m "add my table"

# Apply migrations
uv run alembic upgrade head

# Rollback one step
uv run alembic downgrade -1
```

---

## Deploying

### Step 0 — Choose your provider

**Pick one provider and set it in one place.** Open `.github/workflows/iac-deploy.yml` and set the default on this line:

```yaml
# .github/workflows/iac-deploy.yml
TF_PROVIDER: ${{ inputs.provider || 'azure' }}  # ← change to: azure | aws | gcp
```

This controls which provider is used on every automatic branch-triggered deploy (PR merged into `dev` or `main`). For one-off manual deploys to a different provider you can always override it via `workflow_dispatch` without changing this line.

All infrastructure lives in `iac/terraform/<provider>/` — only files for your chosen provider need to be filled in.

| Provider | Compute | Database | ~Cost/env/month |
|---|---|---|---|
| **azure** | App Service Basic B1 (always-on) | PostgreSQL Flexible Server B1ms | $28 |
| **aws** | Elastic Beanstalk t3.micro | RDS PostgreSQL t4g.micro | $20 |
| **gcp** | Cloud Run (min-instances=1) | Cloud SQL db-f1-micro | $22 |

> **GCP only:** Cloud Run requires a container image. Build and push to Artifact Registry before deploying (see below).
> **AWS only:** Elastic Beanstalk requires a `Procfile` at the repo root: `web: uvicorn main:app --host 0.0.0.0 --port 5000`

### Prerequisites

- [Terraform 1.6+](https://developer.hashicorp.com/terraform/install)
- Cloud CLI for your chosen provider:
  - Azure: [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) — `az login`
  - AWS: [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) — `aws configure`
  - GCP: [gcloud CLI](https://cloud.google.com/sdk/docs/install) — `gcloud auth application-default login`

### First-time setup

#### 1. Fill in your values

Edit the backend config and environment file for your chosen provider and environment:

```
iac/terraform/<provider>/backends/dev.conf   # state storage config
iac/terraform/<provider>/envs/dev.tfvars     # subscription/project ID + app values
```

#### 2. Bootstrap state storage

Run once per provider + environment to create the remote state bucket/storage account:

```bash
./iac/scripts/bootstrap.sh azure dev
./iac/scripts/bootstrap.sh aws   dev
./iac/scripts/bootstrap.sh gcp   dev
```

#### 3. Deploy

```bash
# Azure
terraform -chdir=iac/terraform/azure init -backend-config=backends/dev.conf
terraform -chdir=iac/terraform/azure apply -var-file=envs/dev.tfvars -var="db_password=<password>"

# AWS
terraform -chdir=iac/terraform/aws init -backend-config=backends/dev.conf
terraform -chdir=iac/terraform/aws apply -var-file=envs/dev.tfvars -var="db_password=<password>"

# GCP (build and push image first — see below)
terraform -chdir=iac/terraform/gcp init -backend-config=backends/dev.conf
terraform -chdir=iac/terraform/gcp apply -var-file=envs/dev.tfvars -var="db_password=<password>"
```

#### GCP — building and pushing a container image

Run `terraform apply` once first to create the Artifact Registry repository, then:

```bash
# Build
docker build -t <region>-docker.pkg.dev/<project>/<app-name>-dev/app:latest .

# Push
gcloud auth configure-docker <region>-docker.pkg.dev
docker push <region>-docker.pkg.dev/<project>/<app-name>-dev/app:latest
```

Then update `container_image` in `iac/terraform/gcp/envs/dev.tfvars` and re-apply.

You will also need a `Dockerfile` at the repo root. Example:

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install uv && uv sync --no-dev
CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### GitHub Actions CI/CD

The workflow files live in `iac/github-actions/` and are **inactive by default** so they don't run on the boilerplate repo itself. To activate them in your project:

```bash
mkdir -p .github/workflows
cp iac/github-actions/iac-plan.yml   .github/workflows/
cp iac/github-actions/iac-deploy.yml .github/workflows/
```

Once in `.github/workflows/`, GitHub will pick them up automatically.

| Event | Action |
|---|---|
| PR targeting `dev` | `terraform plan` against dev, result posted as PR comment |
| PR merged into `dev` | `terraform apply` to dev |
| PR targeting `main` | `terraform plan` against prod |
| PR merged into `main` | `terraform apply` to prod |
| Manual `workflow_dispatch` | choose provider + environment |

The provider defaults to `azure` on branch-triggered runs. To deploy to a different provider, use `workflow_dispatch` and select the provider.

#### Required GitHub secrets (set per GitHub environment `dev` / `prod`)

| Secret | Used by |
|---|---|
| `DB_PASSWORD` | all providers |
| `AZURE_CLIENT_ID` | azure |
| `AZURE_TENANT_ID` | azure |
| `AZURE_SUBSCRIPTION_ID` | azure |
| `AWS_ROLE_ARN` | aws |
| `AWS_REGION` | aws |
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | gcp |
| `GCP_SERVICE_ACCOUNT` | gcp |

Only set the secrets for the provider(s) you use. All providers use **OIDC / Workload Identity** — no long-lived credentials stored in GitHub.
