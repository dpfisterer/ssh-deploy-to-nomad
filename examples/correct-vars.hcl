# Example: Correct vars.hcl Configuration

# ⚠️ This file should contain ONLY variable assignments, not definitions!
# Variable definitions go in your template.hcl file.

# Datacenter configuration - array value
datacenters = [[DATACENTER]]

# Docker image configuration
document_service_image = [[DOCUMENT_SERVICE_IMAGE]]

# Scaling configuration
document_service_count = [[DOCUMENT_SERVICE_COUNT]]

# Network configuration
document_service_port = 3000
document_service_host = [[DOCUMENT_SERVICE_HOST]]

# Resource limits
document_service_cpu = [[DOCUMENT_SERVICE_CPU]]
document_service_memory = [[DOCUMENT_SERVICE_MEMORY]]

# S3 Configuration
document_service_s3_bucket = [[DOCUMENT_SERVICE_S3_BUCKET]]
document_service_s3_prefix = [[DOCUMENT_SERVICE_S3_PREFIX]]
document_service_s3_endpoint = [[DOCUMENT_SERVICE_S3_ENDPOINT]]
document_service_s3_region = [[DOCUMENT_SERVICE_S3_REGION]]
document_service_s3_access_key = [[DOCUMENT_SERVICE_S3_ACCESS_KEY]]
document_service_s3_secret_key = [[DOCUMENT_SERVICE_S3_SECRET_KEY]]

# Environment Configuration
document_service_environment = [[DEPLOY_ENVIRONMENT]]
document_service_name = [[DEPLOY_ENVIRONMENT]]

# JWT/Auth Configuration
document_service_jwt_secret = [[DOCUMENT_SERVICE_JWT_SECRET]]
document_service_jwt_oauth2_client_id = [[DOCUMENT_SERVICE_JWT_OAUTH2_CLIENT_ID]]
document_service_jwt_tenant_id = [[DOCUMENT_SERVICE_JWT_TENANT_ID]]
