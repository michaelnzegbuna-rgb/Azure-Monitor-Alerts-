# Observability & Alerting Screenshots Guide

To complete your project submission, you must capture three screenshots and place them in this folder. These act as the visual proof of your proactive monitoring implementation.

---

## Required Screenshots

### 1. **`rule-details.png`**
*   **Description**: Visual proof that the Metric Alert rule is configured correctly in Azure.
*   **How to capture**:
    1. Open the Azure Portal.
    2. Go to **Monitor** > **Alerts**.
    3. Click on **Alert rules** in the top navigation bar.
    4. Find and click on your alert rule: `StorageTransactionsAlert`.
    5. Take a screenshot showing the rule conditions, scope (your Storage Account), and action group.

### 2. **`alert-fired.png`**
*   **Description**: Proof that your load simulation successfully triggered the alert, showing it in the "Fired" state.
*   **How to capture**:
    1. During or immediately after running `simulate-load.ps1`, navigate to **Monitor** > **Alerts** in the Azure Portal.
    2. Review the Alerts console dashboard.
    3. Take a screenshot showing `StorageTransactionsAlert` with a status of **Fired** (with a red/yellow warning icon).

### 3. **`email-notification.png`**
*   **Description**: Proof that the Action Group works and delivered the email notification.
*   **How to capture**:
    1. Log in to the email inbox for `duduyemiolamc@gmail.com`.
    2. Find the email sent by Microsoft Azure Alerts (sender: `azure-noreply@microsoft.com`) with the subject line similar to: *Azure Alert: Fired Sev3 StorageTransactionsAlert*.
    3. Capture a screenshot of the email body showing the metric breach details.
