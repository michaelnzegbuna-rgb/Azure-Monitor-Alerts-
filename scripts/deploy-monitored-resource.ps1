<#
.SYNOPSIS
    Sets up the Resource Group and provisions a test Storage Account, using the Azure CLI (az).
.DESCRIPTION
    Built to run on Windows PowerShell purely through the Azure CLI, this script avoids any
    dependency on the Az PowerShell module entirely.
.PARAMETER ResourceGroupName
    Resource Group to create. Defaults to 'rg-alerts-demo' if not supplied.
.PARAMETER Location
    Azure region for the deployment. Defaults to 'westeurope' if not supplied.
.PARAMETER StorageAccountName
    A specific name for the Storage Account, if you want one. Leave it out and a name will be generated automatically.
.EXAMPLE
    .\deploy-monitored-resource.ps1
#>
[CmdletBinding()]
param (
    [string]$ResourceGroupName = "rg-alerts-demo",
    [string]$Location = "westeurope",
    [string]$StorageAccountName
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

# Generate a Storage Account name automatically if one wasn't given
if ([string]::IsNullOrEmpty($StorageAccountName)) {
    $rand = Get-Random -Minimum 10000 -Maximum 99999
    $StorageAccountName = "alertstore$rand"
}

# 1. Set up the Resource Group
Write-Host "Setting up Resource Group '$ResourceGroupName' in '$Location'..." -ForegroundColor Cyan
$null = az group create --name $ResourceGroupName --location $Location --output json

# 2. Provision the Storage Account
Write-Host "Provisioning Storage Account '$StorageAccountName' (Standard_LRS)..." -ForegroundColor Cyan
$storageJson = az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --output json

Write-Host "Storage Account '$StorageAccountName' is ready!" -ForegroundColor Green
Write-Host "Next, deploy monitoring by running:" -ForegroundColor Green
Write-Host ".\alerts\deploy-monitoring.ps1 -StorageAccountName $StorageAccountName" -ForegroundColor Yellow
