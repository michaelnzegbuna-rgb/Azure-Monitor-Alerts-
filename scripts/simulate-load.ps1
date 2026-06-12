<#
.SYNOPSIS
    Simulates transaction load on the Storage Account to trigger the Metric Alert rule.
.DESCRIPTION
    This script creates a temporary test container and uploads 100 mock files in a loop
    using Azure CLI. This generates over 100 write transactions in a short window, which
    exceeds the 50-transactions-per-minute threshold and fires the alert.
.PARAMETER ResourceGroupName
    The Resource Group containing the storage account (default: 'rg-alerts-demo').
.PARAMETER StorageAccountName
    The name of the Storage Account to load test (Required).
.EXAMPLE
    .\simulate-load.ps1 -StorageAccountName "alertstore49821"
#>

[CmdletBinding()]
param (
    [string]$ResourceGroupName = "rg-alerts-demo",

    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName
)

# Ensure CLI is available
$azCheck = Get-Command az -ErrorAction SilentlyContinue
if ($null -eq $azCheck) {
    Write-Error "Azure CLI (az) is not installed."
    exit 1
}

Write-Host "Retrieving connection string for Storage Account '$StorageAccountName'..." -ForegroundColor Cyan
$connString = az storage account show-connection-string --name $StorageAccountName --resource-group $ResourceGroupName --query connectionString -o tsv 2>$null

if ([string]::IsNullOrEmpty($connString)) {
    Write-Error "Could not retrieve connection string. Check Storage Account name and Resource Group."
    exit 1
}

$containerName = "loadtestcontainer"
Write-Host "Creating test container '$containerName'..." -ForegroundColor Cyan
$null = az storage container create --name $containerName --connection-string $connString --output json

# Create a local temporary directory and populate with 100 small files
$tempDir = Join-Path $env:TEMP "alerttestload"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
$null = New-Item -ItemType Directory -Path $tempDir -Force

Write-Host "Creating 100 temporary files for batch upload..." -ForegroundColor Cyan
for ($i = 1; $i -le 100; $i++) {
    "Load test data for file $i" | Out-File -FilePath (Join-Path $tempDir "file-$i.txt") -Encoding utf8
}

Write-Host "--------------------------------------------------" -ForegroundColor Gray
Write-Host "Starting batch upload: uploading 100 files in parallel..." -ForegroundColor Yellow
Write-Host "This will generate 100+ write transactions within seconds!" -ForegroundColor Yellow
Write-Host "--------------------------------------------------" -ForegroundColor Gray

$startTime = Get-Date

# Upload using upload-batch (extremely fast parallel upload)
$upload = az storage blob upload-batch --destination $containerName --source $tempDir --connection-string $connString --no-progress --output json
$exitCode = $LASTEXITCODE

$duration = (Get-Date) - $startTime
Write-Host "--------------------------------------------------" -ForegroundColor Gray
if ($exitCode -eq 0) {
    Write-Host "Batch upload complete! Successfully generated 100+ transactions in $($duration.TotalSeconds) seconds." -ForegroundColor Green
} else {
    Write-Warning "Batch upload encountered issues. Please verify the output above."
}

# Clean up local temporary files
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }

Write-Host "`n>>> ACTION REQUIRED: Wait 3-5 minutes for Azure Monitor to evaluate metrics and fire the alert. You should receive an email notification shortly." -ForegroundColor Yellow
