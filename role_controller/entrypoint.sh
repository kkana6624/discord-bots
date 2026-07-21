#!/bin/sh
set -e

# OCI Vault integration
if [ -n "$VAULT_SECRET_OCID" ]; then
    echo "Fetching secret from OCI Vault using Instance Principal..."
    # Retrieve the secret bundle using Instance Principal authentication
    SECRET_BUNDLE=$(oci secrets secret-bundle get --secret-id ${VAULT_SECRET_OCID} --auth instance_principal)
    
    # Extract the Base64 content from the JSON payload and decode it
    export DISCORD_TOKEN=$(echo "$SECRET_BUNDLE" | jq -r '.data."secret-bundle-content".content' | base64 -d)
    
    if [ -z "$DISCORD_TOKEN" ]; then
        echo "Error: Failed to extract DISCORD_TOKEN from OCI Vault."
        exit 1
    fi
    echo "Secret successfully fetched and exported."
else
    echo "VAULT_SECRET_OCID is not set. Assuming DISCORD_TOKEN is provided via standard ENV."
fi

# Validate required variables before starting
if [ -z "$DISCORD_TOKEN" ] || [ -z "$GUILD_ID" ] || [ -z "$ROLE_A_ID" ] || [ -z "$ROLE_B_ID" ] || [ -z "$TARGET_ROLE_C_ID" ]; then
    echo "Error: Missing one or more required environment variables (DISCORD_TOKEN, GUILD_ID, ROLE_A_ID, ROLE_B_ID, TARGET_ROLE_C_ID)"
    exit 1
fi

echo "Starting Elixir production release..."
# Run the compiled Elixir release
exec /app/bin/role_controller start
