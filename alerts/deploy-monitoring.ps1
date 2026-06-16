<#
.SYNOPSIS
    Provisions an Action Group and a Metric Alert rule for monitoring a Storage Account, using the Azure CLI (az).
.DESCRIPTION
    Built to run on Windows PowerShell purely through the Azure CLI, this script avoids any
    dependency on the Az PowerShell module entirely.
.PARAMETER ResourceGroupName
    Resource Group hosting the target storage account. Defaults to 'rg-alerts-demo' if not supplied.
.PARAMETER StorageAccountName
    Name of the Storage Account that should be monitored. This parameter is required.
.PARAMETER EmailAddress
    Destination email for alert notifications. Defaults to 'duduyemiolamc@gmail.com' if not supplied.
.EXAMPLE
    .\deploy-monitoring.ps1 -StorageAccountName "alertstore49821"
#>
[CmdletBinding()]
param (
    [string]$ResourceGroupName = "rg-alerts-demo",
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    [string]$EmailAddress = "nzemikez@gmail.com"
)

# Confirm Azure CLI is installed
$azCheck = Get-Command az -ErrorAction SilentlyContinue
if ($null -eq $azCheck) {
    Write-Error "Azure CLI (az) was not found. Make sure it's installed and available on PATH."
    exit 1
}

# Confirm an active Azure session exists
Write-Host "Checking current Azure CLI session..." -ForegroundColor Cyan
$account = az account show --output json | ConvertFrom-Json -ErrorAction SilentlyContinue
if ($null -eq $account) {
    Write-Error "No active Azure session detected. Run 'az login' before retrying."
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$agTemplate = Join-Path $scriptDir "action-group.json"
$maTemplate = Join-Path $scriptDir "metric-alert.json"

# 1. Resolve the Storage Account's resource ID
Write-Host "Looking up resource ID for Storage Account '$StorageAccountName'..." -ForegroundColor Cyan
$storageId = az storage account show --name $StorageAccountName --resource-group $ResourceGroupName --query id -o tsv 2>$null
if ([string]::IsNullOrEmpty($storageId)) {
    Write-Error "Could not locate Storage Account '$StorageAccountName' inside Resource Group '$ResourceGroupName'."
    exit 1
}
Write-Host "Resolved Storage Account ID: $storageId" -ForegroundColor Gray

# 2. Provision the Action Group
Write-Host "Provisioning Action Group with email receiver '$EmailAddress'..." -ForegroundColor Cyan
$agDeployJson = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file $agTemplate `
    --parameters emailAddress=$EmailAddress `
    --output json | ConvertFrom-Json
$actionGroupId = $agDeployJson.properties.outputs.actionGroupId.value
if ([string]::IsNullOrEmpty($actionGroupId)) {
    Write-Error "Action Group deployment did not return a resource ID — check the deployment output for errors."
    exit 1
}
Write-Host "Action Group provisioned. Resource ID: $actionGroupId" -ForegroundColor Green

# 3. Provision the Metric Alert rule
Write-Host "Provisioning Metric Alert rule 'StorageTransactionsAlert'..." -ForegroundColor Cyan
$null = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file $maTemplate `
    --parameters storageAccountId=$storageId actionGroupId=$actionGroupId `
    --output json
Write-Host "Metric Alert rule provisioned successfully!" -ForegroundColor Green
Write-Host "The alert will track transaction volume and fire once it crosses 50 transactions per minute." -ForegroundColor Green
