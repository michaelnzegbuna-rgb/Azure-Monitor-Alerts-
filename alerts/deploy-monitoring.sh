#!/bin/bash
# SYNOPSIS: Provisions an Action Group and Metric Alert rule for monitoring a Storage Account.
# USAGE: ./deploy-monitoring.sh -g <ResourceGroup> -s <StorageAccountName> -e <EmailAddress>
set -e

RG_NAME="rg-alerts-demo"
STORAGE_NAME=""
EMAIL="nzemikez@gmail.com"

print_usage() {
    echo "Usage: ./deploy-monitoring.sh -g <ResourceGroup> -s <StorageAccountName> -e <EmailAddress>"
    echo "  -g : Resource Group name (defaults to rg-alerts-demo)"
    echo "  -s : Storage Account name (required)"
    echo "  -e : Email address for alert notifications (defaults to duduyemiolamc@gmail.com)"
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
    echo "Error: a Storage Account name (-s) must be provided."
    print_usage
    exit 1
fi

# Confirm an active Azure session exists
if ! az account show &> /dev/null; then
    echo "Error: no active Azure session found. Run 'az login' before retrying."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AG_TEMPLATE="$SCRIPT_DIR/action-group.json"
MA_TEMPLATE="$SCRIPT_DIR/metric-alert.json"

# 1. Resolve the Storage Account's resource ID
echo "Looking up resource ID for Storage Account '$STORAGE_NAME' in Resource Group '$RG_NAME'..."
STORAGE_ID=$(az storage account show --name "$STORAGE_NAME" --resource-group "$RG_NAME" --query id -o tsv 2>/dev/null)
if [ -z "$STORAGE_ID" ]; then
    echo "Error: could not locate Storage Account '$STORAGE_NAME' inside Resource Group '$RG_NAME'."
    exit 1
fi
echo "Resolved Storage Account ID: $STORAGE_ID"

# 2. Provision the Action Group
echo "Provisioning Action Group with email receiver '$EMAIL'..."
AG_DEPLOY=$(az deployment group create \
    --resource-group "$RG_NAME" \
    --template-file "$AG_TEMPLATE" \
    --parameters emailAddress="$EMAIL" \
    --query properties.outputs.actionGroupId.value -o tsv)
ACTION_GROUP_ID=$AG_DEPLOY
echo "Action Group provisioned. Resource ID: $ACTION_GROUP_ID"

# 3. Provision the Metric Alert rule
echo "Provisioning Metric Alert rule 'StorageTransactionsAlert'..."
az deployment group create \
    --resource-group "$RG_NAME" \
    --template-file "$MA_TEMPLATE" \
    --parameters storageAccountId="$STORAGE_ID" actionGroupId="$ACTION_GROUP_ID" > /dev/null
echo "Metric Alert rule provisioned successfully!"
echo "The alert will track transaction volume and fire once it crosses 50 transactions per minute."
