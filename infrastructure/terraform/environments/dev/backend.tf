# GCP Data Platform - Backend Configuration for Terraform State
#
# This configuration stores Terraform state in Google Cloud Storage (GCS)
# with versioning enabled for rollback capability.
#
# Before running terraform init, create the state bucket:
#
#   export PROJECT_ID="your-gcp-project-id"
#   export REGION="us-central1"
#
#   # Create state bucket
#   gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${PROJECT_ID}-terraform-state
#
#   # Enable versioning for rollback
#   gsutil versioning set on gs://${PROJECT_ID}-terraform-state
#
#   # Enable bucket encryption (optional)
#   gsutil encryption default set -k projects/${PROJECT_ID}/locations/${REGION}/keyRings/terraform-state/cryptoKeys/state-key gs://${PROJECT_ID}-terraform-state
#

# Note: The backend block in main.tf uses variable interpolation which is evaluated during init.
# If you need to change the backend configuration, run:
#
#   terraform init -reconfigure -backend-config="bucket=NEW_BUCKET_NAME"
#

# Alternative: Create backend config file for dynamic configuration
# Create a file called backend-config.hcl:
#
# bucket = "my-project-terraform-state"
# prefix = "environments/dev"
#
# Then run:
#   terraform init -backend-config=backend-config.hcl
