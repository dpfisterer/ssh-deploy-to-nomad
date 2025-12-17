# Template File Variable Substitution

This action now supports variable substitution in **both** the template file and the variables file using the `[[VAR_NAME]]` pattern.

## Use Cases

### 1. Dynamic Job Names

Dynamically set the Nomad job name based on the service or environment:

```hcl
# template.nomad.hcl
job "[[SERVICE_NAME]]" {
  datacenters = var.datacenters
  type        = "service"
  
  meta {
    environment = "[[ENVIRONMENT]]"
    version     = "[[VERSION]]"
  }

  group "app" {
    count = var.instance_count
    # ...
  }
}
```

**Workflow:**
```yaml
- uses: dpfisterer/ssh-deploy-to-nomad@v1
  with:
    env-vars: |
      SERVICE_NAME: my-api-service
      ENVIRONMENT: production
      VERSION: 1.2.3
      INSTANCE_COUNT: 5
    hcl-template: path/to/template.nomad.hcl
    hcl-variables: path/to/variables.vars.hcl
```

### 2. Environment-Specific Job Names

```hcl
job "[[APP_NAME]]-[[ENV]]" {
  # ...
}
```

With env-vars:
```yaml
APP_NAME: document-processor
ENV: staging
```

Results in: `job "document-processor-staging"`

### 3. Mixed Usage

You can use `[[VAR]]` placeholders in the template for static values (like job names) and `var.` references for values that come from the variables file:

**Template:**
```hcl
job "[[JOB_NAME]]" {
  datacenters = var.datacenters
  type        = "service"
  
  meta {
    environment = "[[ENVIRONMENT]]"
    git_commit  = "[[GIT_SHA]]"
  }

  group "app" {
    count = var.instance_count
    
    task "app" {
      driver = "docker"
      
      config {
        image = var.docker_image
      }
    }
  }
}
```

**Variables:**
```hcl
datacenters   = [[DATACENTERS]]
instance_count = [[INSTANCE_COUNT]]
docker_image  = [[DOCKER_IMAGE]]
```

**GitHub Actions Workflow:**
```yaml
- uses: dpfisterer/ssh-deploy-to-nomad@v1
  with:
    env-vars: |
      JOB_NAME: my-service
      ENVIRONMENT: production
      GIT_SHA: ${{ github.sha }}
      DATACENTERS: ["dc1", "dc2"]
      INSTANCE_COUNT: 3
      DOCKER_IMAGE: myorg/myapp:latest
```

## Key Differences

### Template File Substitution
- **Raw values**: No automatic quoting or type detection
- **Use for**: Job names, static metadata, IDs
- **Pattern**: `[[VAR_NAME]]`
- **Example**: `job "[[JOB_NAME]]"` → `job "my-service"`

### Variables File Substitution
- **Type-aware**: Automatic quoting for strings, no quotes for numbers/bools/arrays
- **Use for**: Configuration values passed to Nomad
- **Pattern**: `[[VAR_NAME]]`
- **Example**: `count = [[COUNT]]` → `count = 5` (number, unquoted)
- **Example**: `image = [[IMAGE]]` → `image = "nginx:latest"` (string, quoted)

## Important Notes

1. **Variable names**: Must be uppercase with underscores (e.g., `MY_VAR`, `SERVICE_NAME`)
2. **Hyphens**: Supported in placeholders (`[[MY-VAR]]`) but converted to underscores for env lookup
3. **Empty values**: In templates, empty vars are replaced with empty string (no quotes)
4. **var. references**: NOT substituted - these are Nomad's native variable syntax
5. **Both files processed**: Template AND variables files both support `[[VAR]]` substitution

## Example Output

Given this input:
```hcl
job "[[SERVICE_NAME]]" {
  meta {
    version = "[[VERSION]]"
  }
}
```

With `SERVICE_NAME=my-api` and `VERSION=1.0.0`, you get:
```hcl
job "my-api" {
  meta {
    version = "1.0.0"
  }
}
```

## Testing

Run the test to verify template substitution works:
```bash
cd test/
./test-template-substitution.sh
```
