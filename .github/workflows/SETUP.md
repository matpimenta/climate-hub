# GitHub Actions Setup for GCP Deployment

This guide explains how to configure GitHub Actions to deploy your Terraform infrastructure to GCP.

## Prerequisites

1. GCP Project: `climate-hub-478222`
2. GitHub repository with admin access
3. gcloud CLI installed locally

## Setup Steps

### 1. Create GCS Bucket for Terraform State

```bash
export PROJECT_ID="climate-hub-478222"
export REGION="us-central1"

# Create state bucket
gcloud storage buckets create gs://${PROJECT_ID}-terraform-state \
  --project=${PROJECT_ID} \
  --location=${REGION} \
  --uniform-bucket-level-access

# Enable versioning for rollback capability
gcloud storage buckets update gs://${PROJECT_ID}-terraform-state \
  --versioning
```

### 2. Create Service Account for GitHub Actions

```bash
# Create service account
gcloud iam service-accounts create github-actions-terraform \
  --display-name="GitHub Actions Terraform Deployer" \
  --project=${PROJECT_ID}

# Grant necessary roles
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:github-actions-terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/editor"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:github-actions-terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.securityAdmin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:github-actions-terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/resourcemanager.projectIamAdmin"

# Grant access to state bucket
gcloud storage buckets add-iam-policy-binding gs://${PROJECT_ID}-terraform-state \
  --member="serviceAccount:github-actions-terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

### 3. Configure Workload Identity Federation

```bash
# Create Workload Identity Pool
gcloud iam workload-identity-pools create "github-actions-pool" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
export REPO_OWNER="YOUR_GITHUB_USERNAME_OR_ORG"
export REPO_NAME="YOUR_REPO_NAME"

gcloud iam workload-identity-pools providers create-oidc "github-actions-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${REPO_OWNER}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Allow GitHub Actions to impersonate the service account
gcloud iam service-accounts add-iam-policy-binding \
  "github-actions-terraform@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe ${PROJECT_ID} --format='value(projectNumber)')/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository/${REPO_OWNER}/${REPO_NAME}"
```

### 4. Get Workload Identity Provider Resource Name

```bash
# Get the full resource name
gcloud iam workload-identity-pools providers describe "github-actions-provider" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" \
  --format="value(name)"
```

This will output something like:
```
projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider
```

### 5. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add the following **Repository Secrets**:

1. **GCP_WORKLOAD_IDENTITY_PROVIDER**
   - Value: The output from step 4 (e.g., `projects/123456789/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider`)

2. **GCP_SERVICE_ACCOUNT**
   - Value: `github-actions-terraform@climate-hub-478222.iam.gserviceaccount.com`

### 6. Create GitHub Environment

1. Go to repository → Settings → Environments
2. Click "New environment"
3. Name it `dev`
4. (Optional) Add protection rules:
   - Required reviewers
   - Wait timer
   - Deployment branches

### 7. Initialize Terraform Locally (First Time)

```bash
cd infrastructure/terraform/environments/dev

# Copy and update terraform.tfvars
cp terraform.tfvars terraform.tfvars

# Edit terraform.tfvars with your values
cat > terraform.tfvars <<EOF
project_id = "climate-hub-478222"
region = "us-central1"
cost_center = "data-engineering"

# Networking
vpc_cidr = "10.0.0.0/16"
dataflow_subnet_cidr = "10.0.1.0/24"
composer_subnet_cidr = "10.0.2.0/24"
cloud_run_subnet_cidr = "10.0.3.0/24"
enable_vpc_flow_logs = true

# Storage
bronze_retention_days = 2555
silver_retention_days = 1825
enable_cross_region_replication = false

# BigQuery
bigquery_location = "US"

# Dataflow
dataflow_machine_type = "n1-standard-2"
dataflow_max_workers = 10
enable_preemptible_workers = true

# Cloud Composer
enable_composer = true
composer_node_count = 3
composer_machine_type = "n1-standard-2"
composer_disk_size_gb = 30

# API Gateway
enable_api_gateway = true
oauth_issuer = "https://accounts.google.com"
oauth_audiences = []
api_rate_limit_rpm = 1000

# Vertex AI
enable_vertex_ai = false
vertex_ai_node_count = 1

# Security
enable_cmek = false

# Monitoring
notification_channels = []
daily_cost_threshold = 100
data_freshness_sla_minutes = 120
EOF

# Initialize Terraform
terraform init \
  -backend-config="bucket=${PROJECT_ID}-terraform-state" \
  -backend-config="prefix=environments/dev"

# Optional: Plan locally to verify
terraform plan -var="project_id=${PROJECT_ID}" -var="region=${REGION}"
```

## Workflow Behavior

### On Pull Request
- Runs `terraform plan`
- Comments the plan on the PR
- Does NOT apply changes

### On Push to Main
- Runs `terraform plan`
- If changes detected, runs `terraform apply` automatically
- Requires `dev` environment approval (if configured)

### Manual Trigger (workflow_dispatch)
- Runs drift detection
- Checks if infrastructure has drifted from Terraform state
- Reports any detected drift

## Testing the Workflow

### Test Plan Only
1. Create a feature branch
2. Make changes to Terraform files
3. Create a PR to main
4. Check the PR comment for the plan output

### Test Full Deployment
1. Merge PR to main (or push to main)
2. GitHub Actions will run automatically
3. Monitor the workflow in Actions tab
4. Terraform will apply changes

### Test Drift Detection
1. Go to Actions tab
2. Select "Deploy Dev Environment to GCP" workflow
3. Click "Run workflow"
4. Select branch and run

## Troubleshooting

### Authentication Failed

If you see authentication errors:

```bash
# Verify service account exists
gcloud iam service-accounts describe \
  github-actions-terraform@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=${PROJECT_ID}

# Verify workload identity pool
gcloud iam workload-identity-pools describe github-actions-pool \
  --location=global \
  --project=${PROJECT_ID}
```

### State Bucket Not Found

```bash
# Check if bucket exists
gcloud storage buckets describe gs://${PROJECT_ID}-terraform-state

# If not, create it
gcloud storage buckets create gs://${PROJECT_ID}-terraform-state \
  --project=${PROJECT_ID} \
  --location=${REGION} \
  --uniform-bucket-level-access
```

### Permission Denied

The service account needs these roles:
- `roles/editor` - Manage most GCP resources
- `roles/iam.securityAdmin` - Manage IAM policies
- `roles/resourcemanager.projectIamAdmin` - Manage project IAM
- `roles/storage.objectAdmin` - Manage state bucket

Verify roles:
```bash
gcloud projects get-iam-policy ${PROJECT_ID} \
  --flatten="bindings[].members" \
  --format='table(bindings.role)' \
  --filter="bindings.members:github-actions-terraform@${PROJECT_ID}.iam.gserviceaccount.com"
```

## Security Best Practices

1. **Least Privilege**: The service account has broad permissions. In production, consider splitting into separate service accounts for plan and apply.

2. **Branch Protection**: Enable branch protection rules on main to require PR reviews.

3. **Environment Protection**: Configure the `dev` environment with required reviewers for manual approval before apply.

4. **Secret Rotation**: Periodically rotate Workload Identity Federation credentials.

5. **Audit Logging**: Enable Cloud Audit Logs to track all infrastructure changes.

## Cost Optimization

The workflow only triggers on:
- Changes to `infrastructure/terraform/**` files
- Changes to the workflow file itself

This prevents unnecessary workflow runs and reduces costs.

## Next Steps

1. Set up similar workflows for staging and production environments
2. Configure Slack/Email notifications for deployment status
3. Add policy checks (e.g., terraform-compliance, tfsec)
4. Implement automated testing for Terraform modules

## Resources

- [GitHub Actions Workload Identity Federation](https://github.com/google-github-actions/auth)
- [Terraform GitHub Actions](https://developer.hashicorp.com/terraform/tutorials/automation/github-actions)
- [GCP Workload Identity Federation](https://cloud.google.com/iam/docs/workload-identity-federation)
