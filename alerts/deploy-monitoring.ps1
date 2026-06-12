<#
.SYNOPSIS
    Deploys the Action Group and Metric Alert rule to monitor the Storage Account using Azure CLI (az).
.DESCRIPTION
    This script is optimized to run in Windows PowerShell using the Azure CLI (az) so that it 
    does not require the Az PowerShell module.
.PARAMETER ResourceGroupName
    The Resource Group containing the storage account (default: 'rg-alerts-demo').
.PARAMETER StorageAccountName
    The name of the Storage Account to monitor (Required).
.PARAMETER EmailAddress
    The email address to receive alerts (default: 'duduyemiolamc@gmail.com').
.EXAMPLE
    .\deploy-monitoring.ps1 -StorageAccountName "alertstore49821"
#>

[CmdletBinding()]
param (
    [string]$ResourceGroupName = "rg-alerts-demo",

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,

    [string]$EmailAddress = "duduyemiolamc@gmail.com"
)

# Check for Azure CLI
$azCheck = Get-Command az -ErrorAction SilentlyContinue
if ($null -eq $azCheck) {
    Write-Error "Azure CLI (az) is not installed or not in PATH."
    exit 1
}

# Verify login status
Write-Host "Verifying Azure CLI login status..." -ForegroundColor Cyan
$account = az account show --output json | ConvertFrom-Json -ErrorAction SilentlyContinue
if ($null -eq $account) {
    Write-Error "Not logged in to Azure CLI. Please run 'az login' first."
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$agTemplate = Join-Path $scriptDir "action-group.json"
$maTemplate = Join-Path $scriptDir "metric-alert.json"

# 1. Fetch Storage Account resource ID
Write-Host "Fetching resource ID for Storage Account '$StorageAccountName'..." -ForegroundColor Cyan
$storageId = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName --query id -o tsv 2>$null
if ([string]::IsNullOrEmpty($storageId)) {
    Write-Error "Storage Account '$StorageAccountName' not found in Resource Group '$ResourceGroupName'."
    exit 1
}
Write-Host "Storage Account ID: $storageId" -ForegroundColor Gray

# 2. Deploy Action Group
Write-Host "Deploying Action Group (Email Receiver: $EmailAddress)..." -ForegroundColor Cyan
$agDeployJson = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file $agTemplate `
    --parameters emailAddress=$EmailAddress `
    --output json | ConvertFrom-Json

$actionGroupId = $agDeployJson.properties.outputs.actionGroupId.value
if ([string]::IsNullOrEmpty($actionGroupId)) {
    Write-Error "Failed to retrieve Action Group resource ID from deployment outputs."
    exit 1
}
Write-Host "Action Group deployed successfully. ID: $actionGroupId" -ForegroundColor Green

# 3. Deploy Metric Alert
Write-Host "Deploying Metric Alert Rule 'StorageTransactionsAlert'..." -ForegroundColor Cyan
$null = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file $maTemplate `
    --parameters storageAccountId=$storageId actionGroupId=$actionGroupId `
    --output json

Write-Host "Metric Alert Rule deployed successfully!" -ForegroundColor Green
Write-Host "It will monitor transaction rates and trigger if they exceed 50 per minute." -ForegroundColor Green
