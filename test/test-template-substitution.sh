#!/bin/bash
# Test template file variable substitution
# Tests that [[VAR_NAME]] placeholders in template files are correctly substituted

set -e

echo "=== Testing Template File Variable Substitution ==="

# Get script directory before changing to temp dir
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create test directory
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

cd "$TEST_DIR"

# Create a test template with [[VAR]] placeholders
cat > template.nomad.hcl <<'EOF'
# Job definition with variable substitution
job "[[JOB_NAME]]" {
  datacenters = var.datacenters
  type        = "service"
  
  meta {
    environment = "[[ENVIRONMENT]]"
    version     = "[[VERSION]]"
  }

  group "app" {
    count = var.service_count

    task "app" {
      driver = "docker"

      config {
        image = var.service_image
      }

      env {
        ENVIRONMENT = var.environment
      }
    }
  }
}
EOF

# Create a vars file (can also contain [[VAR]] placeholders)
cat > variables.vars.hcl <<'EOF'
datacenters    = var.datacenters
service_count  = [[SERVICE_COUNT]]
service_image  = [[SERVICE_IMAGE]]
environment    = [[ENVIRONMENT]]
EOF

# Set environment variables
export JOB_NAME="my-awesome-service"
export ENVIRONMENT="production"
export VERSION="1.2.3"
export SERVICE_COUNT="5"
export SERVICE_IMAGE="nginx:latest"

# Copy the deploy script
cp "$SCRIPT_DIR/../deploy.sh" .
chmod +x deploy.sh

# Run substitution (use status action to avoid actual Nomad deployment)
echo ""
echo "Running variable substitution..."

# Create mock nomad command that just shows what would be executed
cat > nomad <<'EOF'
#!/bin/bash
echo "[MOCK] nomad $@"
echo "[MOCK] Would execute: nomad job status my-awesome-service"
exit 0
EOF
chmod +x nomad
export PATH="$PWD:$PATH"

# Modify deploy.sh to NOT cleanup temp files for testing
sed -i 's/^rm -f "\$VARS_FILE_TMP" "\$TEMPLATE_FILE_TMP"$/# CLEANUP DISABLED FOR TESTING/' deploy.sh

# Run the deploy script
./deploy.sh my-awesome-service status template.nomad.hcl variables.vars.hcl || true

# Check the processed template file
echo ""
echo "=== Processed Template File ==="
if [[ -f template.nomad.hcl.tmp ]]; then
    cat template.nomad.hcl.tmp
    echo ""
    
    # Verify substitutions
    echo "=== Verification ==="
    
    if grep -q "job \"my-awesome-service\"" template.nomad.hcl.tmp; then
        echo "✅ JOB_NAME substituted correctly"
    else
        echo "❌ JOB_NAME not substituted"
        exit 1
    fi
    
    if grep -q 'environment = "production"' template.nomad.hcl.tmp; then
        echo "✅ ENVIRONMENT substituted correctly in meta"
    else
        echo "❌ ENVIRONMENT not substituted in meta"
        exit 1
    fi
    
    if grep -q 'version     = "1.2.3"' template.nomad.hcl.tmp; then
        echo "✅ VERSION substituted correctly"
    else
        echo "❌ VERSION not substituted"
        exit 1
    fi
    
    # Verify that var. references are NOT substituted (they should remain)
    if grep -q "var.datacenters" template.nomad.hcl.tmp; then
        echo "✅ var.datacenters preserved (not substituted)"
    else
        echo "❌ var.datacenters was incorrectly modified"
        exit 1
    fi
    
    echo ""
    echo "=== Processed Variables File ==="
    cat variables.vars.hcl.tmp
    echo ""
    
    # Verify vars file substitution
    if grep -q "service_count  = 5" variables.vars.hcl.tmp; then
        echo "✅ SERVICE_COUNT substituted correctly in vars file"
    else
        echo "❌ SERVICE_COUNT not substituted correctly"
        exit 1
    fi
    
    if grep -q 'service_image  = "nginx:latest"' variables.vars.hcl.tmp; then
        echo "✅ SERVICE_IMAGE substituted correctly in vars file"
    else
        echo "❌ SERVICE_IMAGE not substituted correctly"
        exit 1
    fi
    
    echo ""
    echo "✅ All template substitution tests passed!"
else
    echo "❌ Processed template file not found"
    exit 1
fi
