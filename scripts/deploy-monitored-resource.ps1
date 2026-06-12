<#
.SYNOPSIS
    Creates the Resource Group and provisions a test Storage Account using Azure CLI (az).
.DESCRIPTION
    This script is optimized to run in Windows PowerShell using the Azure CLI (az) so that it 
    does not require the Az PowerShell module.
.PARAMETER ResourceGroupName
    The name of the Resource Group to create (default: 'rg-alerts-demo').
.PARAMETER Location
    The Azure region to deploy to (default: 'westeurope').
.PARAMETER StorageAccountName
    Optional specific name for the Storage Account. If omitted, one will be generated.
.EXAMPLE
    .\deploy-monitored-resource.ps1
#>

[CmdletBinding()]
param (
    [string]$ResourceGroupName = "rg-alerts-demo",
    [string]$Location = "westeurope",
    [string]$StorageAccountName
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

# Auto-generate Storage Account name if not provided
if ([string]::IsNullOrEmpty($StorageAccountName)) {
    $rand = Get-Random -Minimum 10000 -Maximum 99999
    $StorageAccountName = "alertstore$rand"
}

# 1. Create Resource Group
Write-Host "Creating Resource Group '$ResourceGroupName' in '$Location'..." -ForegroundColor Cyan
$null = az group create --name $ResourceGroupName --location $Location --output json

# 2. Create Storage Account
Write-Host "Creating Storage Account '$StorageAccountName' (Standard_LRS)..." -ForegroundColor Cyan
$storageJson = az storage account create `
    --name $StorageAccountName `
    --resource-group $ResourceGroupName `
    --location $Location `
    --sku Standard_LRS `
    --kind StorageV2 `
    --output json

Write-Host "Storage Account '$StorageAccountName' created successfully!" -ForegroundColor Green
Write-Host "To deploy monitoring, run:" -ForegroundColor Green
Write-Host ".\alerts\deploy-monitoring.ps1 -StorageAccountName $StorageAccountName" -ForegroundColor Yellow
