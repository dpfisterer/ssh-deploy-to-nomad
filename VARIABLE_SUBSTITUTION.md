# Variable Substitution Guide

This guide explains how to properly configure variable substitution in your Nomad deployment files.

## File Structure

You need two HCL files for deployment:

1. **Template file** (`*.template.hcl`): Your Nomad job specification that uses variables
2. **Variables file** (`*.vars.hcl`): Variable assignments with placeholders

## Variables File Format

Your `*.vars.hcl` file should contain **only variable assignments**, not variable definitions.

### ✅ Correct Format

```hcl
# Variable assignments with [[PLACEHOLDER]] syntax
datacenters = [[DATACENTER]]
service_image = [[SERVICE_IMAGE]]
service_count = [[SERVICE_COUNT]]
service_host = [[SERVICE_HOST]]
service_cpu = [[SERVICE_CPU]]
service_memory = [[SERVICE_MEMORY]]

# For complex placeholders with context
service_name = [[ENVIRONMENT]]-[[SERVICE_NAME]]

# Empty values will be replaced with ""
api_key = [[API_KEY]]
```

### ❌ Incorrect Format

```hcl
# DON'T include variable definitions
variable "datacenters" {
  type = list(string)
}

# DON'T use bare variable names without [[...]]
datacenters = DATACENTER  # Wrong!

# DON'T use nested brackets
datacenters = [[[DATACENTER]]]  # Wrong!
```

## Environment Variables in GitHub Actions

In your workflow YAML, provide values as proper HCL literals:

### ✅ Correct Values

```yaml
env-vars: |
  DATACENTER: '["dc1"]'                    # Array with quoted string
  SERVICE_IMAGE: ghcr.io/org/service:v1.0  # String (will be auto-quoted)
  SERVICE_COUNT: 3                         # Number (stays unquoted)
  SERVICE_CPU: 100                         # Number
  SERVICE_MEMORY: 256                      # Number
  DEBUG_ENABLED: true                      # Boolean (stays unquoted)
  API_KEY: my-secret-key                   # String (will be auto-quoted)
  EMPTY_VALUE: ""                          # Empty string
```

### ❌ Common Mistakes

```yaml
env-vars: |
  DATACENTER: ["dc1"]        # Missing quotes! Will become [dc1] (invalid HCL)
  SERVICE_COUNT: "3"         # Quoted number! Will become "3" instead of 3
  DEBUG_ENABLED: "true"      # Quoted boolean! Will become "true" instead of true
```

## Placeholder Naming Rules

- Start with uppercase letter or underscore: `A-Z` or `_`
- Can contain: uppercase letters, numbers, underscores, hyphens: `A-Z0-9_-`
- Examples:
  - `[[SERVICE_NAME]]` ✅
  - `[[ENVIRONMENT]]` ✅
  - `[[SERVICE_NAME-SUFFIX]]` ✅ (hyphens OK)
  - `[[my_var]]` ❌ (lowercase not supported)
  - `[[123VAR]]` ❌ (can't start with number)

## Type Handling

The deployment script automatically formats values based on type:

| Input Value | Detected Type | HCL Output |
|-------------|---------------|------------|
| `true` or `false` | Boolean | `true` / `false` (unquoted) |
| `123` | Number | `123` (unquoted) |
| `3.14` | Float | `3.14` (unquoted) |
| `["a","b"]` | JSON Array | `["a","b"]` (preserved) |
| `{"key":"val"}` | JSON Object | `{"key":"val"}` (preserved) |
| `hello` | String | `"hello"` (quoted) |
| `` (empty) | Empty | `""` (empty string) |
| `null` | Null | `""` (empty string) |

## Complete Example

### Template File (`nomad.template.hcl`)

```hcl
job "my-service" {
  datacenters = var.datacenters
  
  group "app" {
    count = var.service_count
    
    task "server" {
      driver = "docker"
      
      config {
        image = var.service_image
      }
      
      resources {
        cpu    = var.service_cpu
        memory = var.service_memory
      }
    }
  }
}

variable "datacenters" {
  type = list(string)
}

variable "service_image" {
  type = string
}

variable "service_count" {
  type = number
}

variable "service_cpu" {
  type = number
}

variable "service_memory" {
  type = number
}
```

### Variables File (`nomad.vars.hcl`)

```hcl
# Variable assignments - placeholders will be substituted
datacenters = [[DATACENTER]]
service_image = [[SERVICE_IMAGE]]
service_count = [[SERVICE_COUNT]]
service_cpu = [[SERVICE_CPU]]
service_memory = [[SERVICE_MEMORY]]
```

### GitHub Actions Workflow

```yaml
- name: Deploy to Nomad
  uses: dpfisterer/ssh-deploy-to-nomad@v1
  with:
    ssh-host: ${{ vars.DEPLOYMENT_HOST }}
    ssh-user: ${{ vars.DEPLOYMENT_USER }}
    ssh-key: ${{ secrets.DEPLOYMENT_SSH_KEY }}
    service-name: my-service
    hcl-template: deploy/nomad.template.hcl
    hcl-variables: deploy/nomad.vars.hcl
    action: run
    env-vars: |
      DATACENTER: '["dc1", "dc2"]'
      SERVICE_IMAGE: ghcr.io/org/my-service:v1.0.0
      SERVICE_COUNT: 3
      SERVICE_CPU: 500
      SERVICE_MEMORY: 1024
```

## Troubleshooting

### Error: "Variables not allowed"

This usually means your `*.vars.hcl` file contains variable **definitions** instead of **assignments**.

**Fix**: Remove all `variable "name" { ... }` blocks. Keep only assignments like `name = [[PLACEHOLDER]]`.

### Error: "string required, but have tuple"

This means an array value is being passed where a string is expected.

**Fix**: Check your workflow `env-vars` - ensure array values are properly quoted:
```yaml
DATACENTER: '["dc1"]'  # ✅ Correct
DATACENTER: ["dc1"]    # ❌ Wrong (YAML array, not JSON string)
```

### Values show as "null"

Empty GitHub secrets/variables are passed as empty strings, which become `""` in HCL.

**Fix**: Ensure all required secrets/variables are set in GitHub repository settings.

### Numbers are quoted

Your workflow is passing numbers as strings.

**Fix**: Remove quotes in workflow:
```yaml
SERVICE_COUNT: 3       # ✅ Correct
SERVICE_COUNT: "3"     # ❌ Wrong
```
