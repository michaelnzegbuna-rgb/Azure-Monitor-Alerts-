#!/bin/bash

# SYNOPSIS: Creates the Resource Group and provisions a test Storage Account.
# USAGE: ./deploy-monitored-resource.sh [optional parameters]

set -e

RG_NAME="rg-alerts-demo"
LOCATION="westeurope"
STORAGE_NAME=""

print_usage() {
    echo "Usage: ./deploy-monitored-resource.sh [options]"
    echo "  -g : Resource Group name (default: rg-alerts-demo)"
    echo "  -l : Azure Location (default: westeurope)"
    echo "  -s : Storage Account Name (Optional, will auto-generate if omitted)"
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

# Ensure logged in
if ! az account show &> /dev/null; then
    echo "Error: Not logged in to Azure CLI. Please run 'az login' first."
    exit 1
fi

# Auto-generate Storage Account name if not provided
if [ -z "$STORAGE_NAME" ]; then
    RAND=$((RANDOM % 90000 + 10000))
    STORAGE_NAME="alertstore$RAND"
fi

# 1. Create Resource Group
echo "Creating Resource Group '$RG_NAME' in location '$LOCATION'..."
az group create --name "$RG_NAME" --location "$LOCATION" -o table

# 2. Create Storage Account
echo "Creating Storage Account '$STORAGE_NAME' (Standard_LRS)..."
az storage account create \
    --name "$STORAGE_NAME" \
    --resource-group "$RG_NAME" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --output json

echo "Storage Account '$STORAGE_NAME' created successfully!"
echo "Use this name for deploying alerts: ./deploy-monitoring.sh -s $STORAGE_NAME"
