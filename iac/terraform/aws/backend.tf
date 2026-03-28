terraform {
  backend "s3" {
    # All values supplied at init time via -backend-config=backends/<env>.conf
    # Run: terraform init -backend-config=backends/dev.conf
  }
}
