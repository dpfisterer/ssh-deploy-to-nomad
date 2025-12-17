# Configuration Examples

This directory contains correct examples for configuring your Nomad deployments.

## Files

- **`correct-workflow.yml`**: Example GitHub Actions workflow with proper env-vars formatting
- **`correct-vars.hcl`**: Example variables file with only assignments (no definitions)

## Key Differences from Common Mistakes

### ❌ Common Mistake: Mixing Definitions and Assignments

```hcl
# WRONG - Don't include variable definitions in vars.hcl
variable "document_service_image" {
  type = string
}

document_service_image = [[DOCUMENT_SERVICE_IMAGE]]
```

### ✅ Correct: Only Assignments

```hcl
# CORRECT - Only assignments in vars.hcl
document_service_image = [[DOCUMENT_SERVICE_IMAGE]]
```

Variable definitions should go in your `template.hcl` file instead!

---

### ❌ Common Mistake: Unquoted Array in YAML

```yaml
env-vars: |
  DATACENTER: ["dc1"]  # This becomes the STRING: ["dc1"] without quotes around "dc1"
```

Result: `datacenters = [dc1]` ❌ (invalid HCL - missing quotes)

### ✅ Correct: Quoted Array in YAML

```yaml
env-vars: |
  DATACENTER: '["dc1"]'  # The whole array is a string value
```

Result: `datacenters = ["dc1"]` ✅ (valid HCL - properly quoted)

---

### ❌ Common Mistake: Quoted Numbers

```yaml
env-vars: |
  DOCUMENT_SERVICE_COUNT: "3"  # String "3", not number 3
```

Result: `document_service_count = "3"` ❌ (string instead of number)

### ✅ Correct: Unquoted Numbers

```yaml
env-vars: |
  DOCUMENT_SERVICE_COUNT: 3  # Number 3
```

Result: `document_service_count = 3` ✅ (number)

---

### ❌ Common Mistake: Using Bare Variables

```hcl
# WRONG - Variable name without [[...]]
document_service_count = DOCUMENT_SERVICE_COUNT
```

This will NOT be substituted!

### ✅ Correct: Using Placeholder Syntax

```hcl
# CORRECT - Variable name with [[...]]
document_service_count = [[DOCUMENT_SERVICE_COUNT]]
```

---

### ❌ Common Mistake: Empty Values Cause Errors

```yaml
env-vars: |
  DOCUMENT_SERVICE_S3_BUCKET: ${{ vars.DOCUMENT_SERVICE_S3_BUCKET }}
  # If var not set, this becomes empty and may cause issues
```

### ✅ Correct: Provide Defaults for Optional Values

```yaml
env-vars: |
  DOCUMENT_SERVICE_S3_BUCKET: ${{ vars.DOCUMENT_SERVICE_S3_BUCKET || '' }}
  # Explicitly set to empty string if not defined
```

---

## Testing Your Configuration

Before deploying, you can test locally:

```bash
cd test/
./test.sh
```

This will verify that variable substitution works correctly.

## Need More Help?

See the main [VARIABLE_SUBSTITUTION.md](../VARIABLE_SUBSTITUTION.md) guide for complete documentation.
