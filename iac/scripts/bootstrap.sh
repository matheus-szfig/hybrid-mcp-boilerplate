#!/usr/bin/env bash
# Bootstrap script — run ONCE per provider+environment before first terraform init.
# Creates the remote state storage for Terraform.
#
# Usage:
#   ./iac/scripts/bootstrap.sh azure dev
#   ./iac/scripts/bootstrap.sh aws   dev
#   ./iac/scripts/bootstrap.sh gcp   dev

set -euo pipefail

PROVIDER=${1:-""}
ENV=${2:-""}

if [[ -z "$PROVIDER" || -z "$ENV" ]]; then
  echo "Usage: $0 <provider> <environment>"
  echo "  provider: azure | aws | gcp"
  echo "  environment: dev | prod"
  exit 1
fi

CONF_FILE="$(dirname "$0")/../terraform/${PROVIDER}/backends/${ENV}.conf"

if [[ ! -f "$CONF_FILE" ]]; then
  echo "Backend config not found: $CONF_FILE"
  exit 1
fi

# ── Azure ─────────────────────────────────────────────────────────────────────
bootstrap_azure() {
  local resource_group storage_account container location subscription

  resource_group=$(grep 'resource_group_name' "$CONF_FILE" | cut -d'"' -f2)
  storage_account=$(grep 'storage_account_name' "$CONF_FILE" | cut -d'"' -f2)
  container=$(grep 'container_name' "$CONF_FILE" | cut -d'"' -f2)
  location=$(grep 'location' "$CONF_FILE" | cut -d'"' -f2)
  subscription=$(grep 'subscription_id' "$CONF_FILE" | cut -d'"' -f2)

  echo "  Subscription:    $subscription"
  echo "  Resource Group:  $resource_group"
  echo "  Storage Account: $storage_account"
  echo "  Container:       $container"

  az account set --subscription "$subscription"

  az group create \
    --name "$resource_group" \
    --location "$location" \
    --output none

  az storage account create \
    --name "$storage_account" \
    --resource-group "$resource_group" \
    --location "$location" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --output none

  az storage container create \
    --name "$container" \
    --account-name "$storage_account" \
    --auth-mode login \
    --output none
}

# ── AWS ───────────────────────────────────────────────────────────────────────
bootstrap_aws() {
  local bucket region

  bucket=$(grep 'bucket' "$CONF_FILE" | cut -d'"' -f2)
  region=$(grep 'region' "$CONF_FILE" | cut -d'"' -f2)

  echo "  Bucket: $bucket"
  echo "  Region: $region"

  aws s3api create-bucket \
    --bucket "$bucket" \
    --region "$region" \
    $([ "$region" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=$region" || true)

  aws s3api put-bucket-versioning \
    --bucket "$bucket" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption \
    --bucket "$bucket" \
    --server-side-encryption-configuration \
      '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

  aws s3api put-public-access-block \
    --bucket "$bucket" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
}

# ── GCP ───────────────────────────────────────────────────────────────────────
bootstrap_gcp() {
  local bucket

  bucket=$(grep 'bucket' "$CONF_FILE" | cut -d'"' -f2)

  echo "  Bucket: $bucket"

  gcloud storage buckets create "gs://${bucket}" \
    --uniform-bucket-level-access \
    --public-access-prevention

  gcloud storage buckets update "gs://${bucket}" \
    --versioning
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

echo "Bootstrapping Terraform state storage"
echo "  Provider:    $PROVIDER"
echo "  Environment: $ENV"

case "$PROVIDER" in
  azure) bootstrap_azure ;;
  aws)   bootstrap_aws   ;;
  gcp)   bootstrap_gcp   ;;
  *)
    echo "Unknown provider: $PROVIDER. Use azure, aws, or gcp."
    exit 1
    ;;
esac

echo ""
echo "Bootstrap complete. You can now run:"
echo "  terraform -chdir=iac/terraform/${PROVIDER} init -backend-config=backends/${ENV}.conf"
