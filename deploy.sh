#!/bin/bash
# Nomad deployment script for SSH-based deployments
# This script handles variable substitution and Nomad job operations
# Usage: ./deploy.sh <service-name> <action> [template-file] [vars-file]

set -e

SERVICE_NAME=$1
ACTION=${2:-run}
TEMPLATE_FILE=${3:-"template.nomad.hcl"}
VARS_FILE=${4:-"variables.vars.hcl"}

if [[ -z "$SERVICE_NAME" ]]; then
    echo "Error: Service name is required" >&2
    echo "Usage: $0 <service-name> <action> [template-file] [vars-file]" >&2
    exit 1
fi

# Generate temp file name based on vars file
VARS_FILE_TMP="${VARS_FILE}.tmp"

# Check if required files exist
if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Error: Template file not found: $TEMPLATE_FILE" >&2
    exit 1
fi

if [[ ! -f "$VARS_FILE" ]]; then
    echo "Error: Variables file not found: $VARS_FILE" >&2
    exit 1
fi

# Format value based on type detection
format_value() {
    local value="$1"
    
    # Empty or null values (return empty string quoted)
    if [[ -z "$value" ]] || [[ "$value" == "null" ]]; then
        echo '""'
        return
    fi
    
    # Boolean (unquoted)
    if [[ "$value" =~ ^(true|false)$ ]]; then
        echo "$value"
        return
    fi
    
    # Number (unquoted) - supports integers and floats, including negatives
    if [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        echo "$value"
        return
    fi
    
    # JSON array or object - validate and format for HCL
    # Arrays/objects should NOT be quoted - they're already valid HCL
    if [[ "$value" =~ ^\[.*\]$ ]] || [[ "$value" =~ ^\{.*\}$ ]]; then
        # Unescape any escaped quotes (from YAML/JSON pipeline)
        local unescaped_value="${value//\\\"/\"}"
        
        # Validate it's proper JSON if jq is available
        if command -v jq &>/dev/null; then
            if echo "$unescaped_value" | jq empty 2>/dev/null; then
                # Valid JSON - return unescaped (arrays/objects are not quoted in HCL)
                echo "$unescaped_value"
                return
            fi
        else
            # No jq available - if it looks like JSON, assume it's valid
            # Check for basic JSON array structure: starts with [, ends with ], contains quotes
            if [[ "$unescaped_value" =~ ^\[.*\".*\]$ ]]; then
                echo "$unescaped_value"
                return
            fi
        fi
        
        # If validation failed, treat as string
        value="${value//\"/\\\"}"
        echo "\"$value\""
        return
    fi
    
    # String (quoted and escaped)
    value="${value//\"/\\\"}"
    echo "\"$value\""
}

# Perform variable substitution using [[VAR_NAME]] pattern
echo "[INFO] Performing variable substitution..."

# Create a temporary file for substitution
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Process file line by line
while IFS= read -r line; do
    # Skip comments and empty lines (no substitution needed)
    if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
        echo "$line" >> "$TEMP_FILE"
        continue
    fi
    
    # Detect variable definitions (should not be in vars file)
    if [[ "$line" =~ ^[[:space:]]*variable[[:space:]]+ ]]; then
        echo "[ERROR] Variable definitions found in $VARS_FILE!" >&2
        echo "[ERROR] The vars file should only contain assignments like:" >&2
        echo "[ERROR]   my_var = [[MY_VAR]]" >&2
        echo "[ERROR] NOT variable definitions like:" >&2
        echo "[ERROR]   variable \"my_var\" { ... }" >&2
        echo "[ERROR] See VARIABLE_SUBSTITUTION.md for correct format." >&2
        rm -f "$TEMP_FILE"
        exit 1
    fi
    
    processed_line="$line"
    
    # Find and replace all [[VAR]] or [[VAR-WITH-DASHES]] patterns
    while [[ "$processed_line" =~ \[\[([A-Z_][A-Z0-9_-]*)\]\] ]]; do
        var_name="${BASH_REMATCH[1]}"
        # Convert hyphens to underscores for environment variable lookup
        env_var_name="${var_name//-/_}"
        var_value="${!env_var_name}"
        
        if [[ -z "$var_value" ]]; then
            echo "[WARNING] Variable $var_name (env: $env_var_name) is not set - leaving empty" >&2
            formatted_value="\"\""
        else
            formatted_value=$(format_value "$var_value")
        fi
        
        # Escape special characters for sed
        escaped_value=$(echo "$formatted_value" | sed 's/[\/&]/\\&/g')
        
        # Replace the placeholder (escape hyphens in pattern)
        safe_var_name="${var_name//-/\\-}"
        processed_line=$(echo "$processed_line" | sed "s/\[\[${safe_var_name}\]\]/${escaped_value}/g")
        
        echo "[INFO] Substituted $var_name = $formatted_value"
    done
    
    echo "$processed_line" >> "$TEMP_FILE"
done < "$VARS_FILE"

# Move the processed file to the tmp location
mv "$TEMP_FILE" "$VARS_FILE_TMP"

# Perform the requested action
case "$ACTION" in
    run)
        echo "[INFO] Deploying job: $SERVICE_NAME"
        if nomad job run -var-file="$VARS_FILE_TMP" "$TEMPLATE_FILE"; then
            echo "✅ Successfully deployed $SERVICE_NAME"
        else
            echo "❌ Failed to deploy $SERVICE_NAME" >&2
            exit 1
        fi
        ;;
    
    stop)
        echo "[INFO] Stopping job: $SERVICE_NAME"
        if nomad job stop "$SERVICE_NAME"; then
            echo "✅ Successfully stopped $SERVICE_NAME"
        else
            echo "❌ Failed to stop $SERVICE_NAME" >&2
            exit 1
        fi
        ;;
    
    restart)
        echo "[INFO] Restarting job: $SERVICE_NAME"
        if nomad job stop "$SERVICE_NAME" && sleep 2 && nomad job run -var-file="$VARS_FILE_TMP" "$TEMPLATE_FILE"; then
            echo "✅ Successfully restarted $SERVICE_NAME"
        else
            echo "❌ Failed to restart $SERVICE_NAME" >&2
            exit 1
        fi
        ;;
    
    status)
        echo "[INFO] Checking status of job: $SERVICE_NAME"
        nomad job status "$SERVICE_NAME"
        ;;
    
    *)
        echo "Error: Unknown action: $ACTION" >&2
        echo "Valid actions: run, stop, restart, status" >&2
        exit 1
        ;;
esac

# Cleanup
rm -f "$VARS_FILE_TMP"
