#!/bin/bash

# SYNOPSIS: Deploys the Action Group and Metric Alert rule to monitor the Storage Account.
# USAGE: ./deploy-monitoring.sh -g <ResourceGroup> -s <StorageAccountName> -e <EmailAddress>

set -e

RG_NAME="rg-alerts-demo"
STORAGE_NAME=""
EMAIL="duduyemiolamc@gmail.com"

print_usage() {
    echo "Usage: ./deploy-monitoring.sh -g <ResourceGroup> -s <StorageAccountName> -e <EmailAddress>"
    echo "  -g : Resource Group name (default: rg-alerts-demo)"
    echo "  -s : Storage Account Name (Required)"
    echo "  -e : Notification Email (default: duduyemiolamc@gmail.com)"
}

while getopts "g:s:e:h" opt; do
    case ${opt} in
        g ) RG_NAME=$OPTARG ;;
        s ) STORAGE_NAME=$OPTARG ;;
        e ) EMAIL=$OPTARG ;;
        h ) print_usage; exit 0 ;;
        \? ) print_usage; exit 1 ;;
    esac
done

if [ -z "$STORAGE_NAME" ]; then
    echo "Error: Storage Account Name (-s) is required."
    print_usage
    exit 1
fi

# Ensure logged in
if ! az account show &> /dev/null; then
    echo "Error: Not logged in to Azure CLI. Please run 'az login' first."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AG_TEMPLATE="$SCRIPT_DIR/action-group.json"
MA_TEMPLATE="$SCRIPT_DIR/metric-alert.json"

# 1. Fetch Storage Account resource ID
echo "Fetching resource ID for Storage Account '$STORAGE_NAME' in Resource Group '$RG_NAME'..."
STORAGE_ID=$(az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" --query id -o tsv 2>/dev/null)

if [ -z "$STORAGE_ID" ]; then
    echo "Error: Storage Account '$STORAGE_NAME' not found in Resource Group '$RG_NAME'."
    exit 1
fi
echo "Storage Account ID: $STORAGE_ID"

# 2. Deploy Action Group
echo "Deploying Action Group (Email Receiver: $EMAIL)..."
AG_DEPLOY=$(az deployment group create \
    --resource-group "$RG_NAME" \
    --template-file "$AG_TEMPLATE" \
    --parameters emailAddress="$EMAIL" \
    --query properties.outputs.actionGroupId.value -o tsv)

ACTION_GROUP_ID=$AG_DEPLOY
echo "Action Group deployed successfully. ID: $ACTION_GROUP_ID"

# 3. Deploy Metric Alert
echo "Deploying Metric Alert Rule 'StorageTransactionsAlert'..."
az deployment group create \
    --resource-group "$RG_NAME" \
    --template-file "$MA_TEMPLATE" \
    --parameters storageAccountId="$STORAGE_ID" actionGroupId="$ACTION_GROUP_ID" > /dev/null

echo "Metric Alert Rule deployed successfully!"
echo "It will monitor transaction rates and trigger if they exceed 50 per minute."
