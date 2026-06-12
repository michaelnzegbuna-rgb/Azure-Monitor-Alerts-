# Azure Monitor Alerts Learning Program

This repository contains the templates, automation scripts, and documentation for establishing proactive cloud monitoring using Azure Monitor Alerts and Action Groups.

---

## Observability Architecture

This governance framework implements a closed-loop monitoring cycle:
1.  **Monitored Resource**: A test Storage Account.
2.  **Telemetry Source**: Metric data (`Transactions`) collected in real-time.
3.  **Proactive Evaluation**: A Metric Alert Rule evaluating traffic every minute.
4.  **Actionable Notification**: An Action Group delivering immediate email alerts on threshold breach.
5.  **Lifecycle Tracking**: Alert transitions from *Fired* to *Resolved* once transaction rates drop.

---

## Directory Structure

```text
AzureAlertsMiniProject/
├── README.md                          # Main project instructions
├── alerts/
│   ├── action-group.json              # ARM template for Action Group (Email)
│   ├── metric-alert.json              # ARM template for Metric Alert Rule
│   ├── deploy-monitoring.ps1          # PowerShell deployment helper script
│   └── deploy-monitoring.sh           # Bash deployment helper script
├── scripts/
│   ├── deploy-monitored-resource.ps1  # PowerShell storage provisioner
│   ├── deploy-monitored-resource.sh   # Bash storage provisioner
│   ├── simulate-load.ps1              # PowerShell traffic simulator (stress test)
│   └── log-alert-query.kql            # KQL log-based alert reference query
├── reports/
│   └── monitoring-report.md           # Configuration & threshold report
└── screenshots/
    └── README.md                      # Checklist & instructions for screenshots
```

---

## Step-by-Step Execution Guide

You can run these scripts using **either** **Azure CLI** or **PowerShell** (which calls Azure CLI under the hood, removing the need for the `Az` module).

### Step 1: Login to Azure CLI
Open your terminal and verify your active subscription:
```bash
az login
# If you have multiple subscriptions, select your active one:
az account set --subscription "<subscription-name-or-id>"
```

---

### Step 2: Provision Monitored Storage Resource
Run the script to create the `rg-alerts-demo` resource group and the Storage Account. Note the storage account name outputted by the script.

*   **Azure CLI / Bash**:
    ```bash
    chmod +x scripts/deploy-monitored-resource.sh
    ./scripts/deploy-monitored-resource.sh
    ```
*   **PowerShell**:
    ```powershell
    .\scripts\deploy-monitored-resource.ps1
    ```

---

### Step 3: Deploy Action Group and Alert Rules
Run the deployment script, replacing `<StorageAccountName>` with the name generated in Step 2.

*   **Azure CLI / Bash**:
    ```bash
    chmod +x alerts/deploy-monitoring.sh
    ./alerts/deploy-monitoring.sh -s "<StorageAccountName>" -e "duduyemiolamc@gmail.com"
    ```
*   **PowerShell**:
    ```powershell
    .\alerts\deploy-monitoring.ps1 -StorageAccountName "<StorageAccountName>" -EmailAddress "duduyemiolamc@gmail.com"
    ```

---

### Step 4: Simulate Transaction Traffic
To trigger the alert, run the traffic simulator script. This script executes a loop uploading blobs, creating high API traffic that breaches the 50-transactions-per-minute threshold.

*   **PowerShell**:
    ```powershell
    .\scripts\simulate-load.ps1 -StorageAccountName "<StorageAccountName>"
    ```

---

### Step 5: Capture Screen Artifacts & Manage Alert Lifecycle
1.  **Metric Rule**: Capture a screenshot of the configured alert rule details in the Azure Portal (save as `rule-details.png`).
2.  **Fired Alert**: While the simulation script runs or shortly after, navigate to **Monitor** > **Alerts**. Capture a screenshot of the active alert showing `Fired` (save as `alert-fired.png`).
3.  **Acknowledge**: Click on the fired alert in the console, change its **User Response State** to **Acknowledge** to practice alert lifecycle tracking.
4.  **Check Email**: Verify that you received an email alert notification in your inbox for `duduyemiolamc@gmail.com`. Capture a screenshot of the email header/body (save as `email-notification.png`).
5.  **Resolution**: Once the simulation script completes, wait 3-5 minutes. The alert will transition back to a green `Resolved` state in the console.

---

## Submission Checklist

Before submitting the GitHub link, ensure your repository has:
*   [ ] Complete [Monitoring Report](file:///C:/Users/duduy/OneDrive/Documents/AzureAlertsMiniProject/reports/monitoring-report.md).
*   [ ] Reference [KQL Log Query](file:///C:/Users/duduy/OneDrive/Documents/AzureAlertsMiniProject/scripts/log-alert-query.kql).
*   [ ] Screen verification items in [screenshots/](file:///C:/Users/duduy/OneDrive/Documents/AzureAlertsMiniProject/screenshots):
    *   `screenshots/rule-details.png`
    *   `screenshots/alert-fired.png`
    *   `screenshots/email-notification.png`
