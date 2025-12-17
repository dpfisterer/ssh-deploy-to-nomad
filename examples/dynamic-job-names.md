# Example: Dynamic Job Names with Template Substitution

This example shows how to use `[[VAR_NAME]]` placeholders in template files to create dynamic job names based on service and environment.

## Template File

`nomad/template.nomad.hcl`:
```hcl
# Dynamic job name based on service and environment
job "[[SERVICE_NAME]]-[[ENVIRONMENT]]" {
  datacenters = var.datacenters
  type        = "service"
  
  # Metadata with build information
  meta {
    service      = "[[SERVICE_NAME]]"
    environment  = "[[ENVIRONMENT]]"
    version      = "[[VERSION]]"
    git_commit   = "[[GIT_SHA]]"
    deployed_by  = "[[GITHUB_ACTOR]]"
    deployed_at  = "[[DEPLOY_TIME]]"
  }

  group "app" {
    count = var.instance_count

    network {
      port "http" {
        to = var.container_port
      }
    }

    task "app" {
      driver = "docker"

      config {
        image = var.docker_image
        ports = ["http"]
      }

      env {
        ENVIRONMENT = var.environment
        LOG_LEVEL   = var.log_level
      }

      resources {
        cpu    = var.cpu
        memory = var.memory
      }

      service {
        name = var.service_name
        port = "http"
        
        tags = var.service_tags

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
```

## Variables File

`nomad/variables.vars.hcl`:
```hcl
# Datacenter configuration
datacenters = [[DATACENTERS]]

# Service configuration
service_name = [[SERVICE_NAME]]
instance_count = [[INSTANCE_COUNT]]

# Docker configuration
docker_image = [[DOCKER_IMAGE]]
container_port = [[CONTAINER_PORT]]

# Environment configuration
environment = [[ENVIRONMENT]]
log_level = [[LOG_LEVEL]]

# Resource allocation
cpu = [[CPU]]
memory = [[MEMORY]]

# Service discovery tags
service_tags = [[SERVICE_TAGS]]
```

## GitHub Actions Workflow

`.github/workflows/deploy-dynamic.yml`:
```yaml
name: Deploy with Dynamic Job Name

on:
  push:
    branches: [main, staging, develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set environment based on branch
        id: set-env
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "ENVIRONMENT=production" >> $GITHUB_ENV
            echo "INSTANCE_COUNT=5" >> $GITHUB_ENV
            echo "LOG_LEVEL=info" >> $GITHUB_ENV
          elif [[ "${{ github.ref }}" == "refs/heads/staging" ]]; then
            echo "ENVIRONMENT=staging" >> $GITHUB_ENV
            echo "INSTANCE_COUNT=2" >> $GITHUB_ENV
            echo "LOG_LEVEL=debug" >> $GITHUB_ENV
          else
            echo "ENVIRONMENT=develop" >> $GITHUB_ENV
            echo "INSTANCE_COUNT=1" >> $GITHUB_ENV
            echo "LOG_LEVEL=debug" >> $GITHUB_ENV
          fi
      
      - name: Deploy to Nomad
        uses: dpfisterer/ssh-deploy-to-nomad@v1
        with:
          ssh-host: ${{ secrets.NOMAD_HOST }}
          ssh-user: ${{ secrets.NOMAD_USER }}
          ssh-key: ${{ secrets.SSH_PRIVATE_KEY }}
          service-name: document-api-${{ env.ENVIRONMENT }}
          hcl-template: nomad/template.nomad.hcl
          hcl-variables: nomad/variables.vars.hcl
          action: run
          env-vars: |
            SERVICE_NAME: document-api
            ENVIRONMENT: ${{ env.ENVIRONMENT }}
            VERSION: ${{ github.ref_name }}-${{ github.run_number }}
            GIT_SHA: ${{ github.sha }}
            GITHUB_ACTOR: ${{ github.actor }}
            DEPLOY_TIME: ${{ github.event.head_commit.timestamp }}
            DATACENTERS: ["dc1", "dc2"]
            INSTANCE_COUNT: ${{ env.INSTANCE_COUNT }}
            DOCKER_IMAGE: myorg/document-api:${{ github.sha }}
            CONTAINER_PORT: 8080
            LOG_LEVEL: ${{ env.LOG_LEVEL }}
            CPU: 500
            MEMORY: 512
            SERVICE_TAGS: ["api", "documents", "${{ env.ENVIRONMENT }}"]
```

## Result

For a push to `main` branch, this creates a Nomad job named:
```
document-api-production
```

With metadata:
```hcl
meta {
  service      = "document-api"
  environment  = "production"
  version      = "main-42"
  git_commit   = "abc123def456..."
  deployed_by  = "john-doe"
  deployed_at  = "2024-01-15T10:30:00Z"
}
```

For a push to `staging` branch:
```
document-api-staging
```

For a push to `develop` branch:
```
document-api-develop
```

## Benefits

1. **Single Template**: One template file works for all environments
2. **Clear Naming**: Job names clearly indicate service and environment
3. **Traceability**: Metadata tracks who deployed what, when, and from which commit
4. **Environment-Specific**: Different instance counts and log levels per environment
5. **Easy Rollback**: Version information makes it easy to track deployments

## Testing Locally

You can test the substitution without deploying:

```bash
# Set environment variables
export SERVICE_NAME="document-api"
export ENVIRONMENT="staging"
export VERSION="v1.2.3"
export GIT_SHA="abc123"
export GITHUB_ACTOR="test-user"
export DEPLOY_TIME="2024-01-15T10:00:00Z"
export DATACENTERS='["dc1"]'
export INSTANCE_COUNT="2"
export DOCKER_IMAGE="myorg/document-api:latest"
export CONTAINER_PORT="8080"
export LOG_LEVEL="debug"
export CPU="500"
export MEMORY="512"
export SERVICE_TAGS='["api", "test"]'

# Run test
cd test/
./test-template-substitution.sh
```

This will show you the final substituted template and variables files without deploying to Nomad.
