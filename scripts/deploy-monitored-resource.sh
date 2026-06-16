#!/bin/bash
# SYNOPSIS: Sets up the Resource Group and provisions a test Storage Account.
# USAGE: ./deploy-monitored-resource.sh [optional parameters]
set -e

RG_NAME="rg-alerts-demo"
LOCATION="westeurope"
STORAGE_NAME=""

print_usage() {
    echo "Usage: ./deploy-monitored-resource.sh [options]"
    echo "  -g : Resource Group name (defaults to rg-alerts-demo)"
    echo "  -l : Azure region (defaults to westeurope)"
    echo "  -s : Storage Account name (optional — auto-generated if left out)"
}

while getopts "g:l:s:h" opt; do
    case ${opt} in
        g ) RG_NAME=$OPTARG ;;
        l ) LOCATION=$OPTARG ;;
        s ) STORAGE_NAME=$OPTARG ;;
        h ) print_usage; exit 0 ;;
        \? ) print_usage; exit 1 ;;
    esac
done

# Confirm an active Azure session exists
if ! az account show &> /dev/null; then
    echo "Error: no active Azure session found. Run 'az login' before retrying."
    exit 1
fi

# Generate a Storage Account name automatically if one wasn't given
if [ -z "$STORAGE_NAME" ]; then
    RAND=$((RANDOM % 90000 + 10000))
    STORAGE_NAME="alertstore$RAND"
fi

# 1. Set up the Resource Group
echo "Setting up Resource Group '$RG_NAME' in location '$LOCATION'..."
az group create --name "$RG_NAME" --location "$LOCATION" -o table

# 2. Provision the Storage Account
echo "Provisioning Storage Account '$STORAGE_NAME' (Standard_LRS)..."
az storage account create \
    --name "$STORAGE_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --output json

echo "Storage Account '$STORAGE_NAME' is ready!"
echo "Next, deploy monitoring by running: ./deploy-monitoring.sh -s $STORAGE_NAME"
