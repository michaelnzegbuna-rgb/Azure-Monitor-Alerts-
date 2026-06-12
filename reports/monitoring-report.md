# Azure Monitor Alerts Configuration Report

This report outlines the technical design, configuration details, and threshold justifications for the proactive monitoring framework implemented in Azure.

---

## 1. Monitoring Scope & Metric Selection

### Monitored Resource
*   **Resource Type**: Azure Storage Account (General Purpose v2)
*   **Target Scope**: `rg-alerts-demo` resource group.
*   **Resource Name**: Automatically generated (e.g., `alertstore12345`) to ensure global uniqueness.

### Key Performance Indicator (KPI)
*   **Metric Name**: `Transactions` (Total Transactions)
*   **Namespace**: `Microsoft.Storage/storageAccounts`
*   **Aggregation Type**: `Total`
*   **Description**: Monitors the rate of API calls made to the Storage Account (e.g., upload blob, download blob, list blobs, delete container).

### Rationale
Storage Accounts form the baseline storage layer for many cloud architectures. An unexpected spike in transaction count can indicate:
1.  **Application Looping/Bugs**: A code loop continuously requesting storage files.
2.  **DDoS / Unauthorized Scan**: External attackers attempting brute-force authorization or scanning blobs.
3.  **Traffic Spikes**: Normal but rapid business transaction increases that require scaling reviews.

---

## 2. Notification Preferences (Action Group)

Observability must be coupled with notifications to achieve "closed-loop" monitoring.

*   **Action Group Name**: `EmailAlertsGroup`
*   **Short Name**: `email-alerts`
*   **Notification Channel**: Email (multi-channel ready)
*   **Configured Receiver**: `duduyemiolamc@gmail.com`
*   **Common Alert Schema**: Enabled (standardizes the payload format for easy parsing by downstream webhooks or IT systems).

---

## 3. Metric Alert Rule Design

| Setting | Value | Justification |
| :--- | :--- | :--- |
| **Rule Name** | `StorageTransactionsAlert` | Identifies the alert purpose clearly. |
| **Severity** | `Sev 3` (Informational) | Sizable traffic is noteworthy but doesn't immediately indicate a down outage. |
| **Threshold Type** | **Static** | Predictable limits are preferred for baseline performance APIs. |
| **Operator** | `GreaterThan` | Triggers when activity rises above the baseline limit. |
| **Threshold Value** | `50` | An arbitrary low threshold chosen specifically to make it easy to trigger during testing. |
| **Evaluation Granularity** | `1 Minute` | Aggregates transactions in 1-minute blocks to capture immediate spikes. |
| **Evaluation Frequency** | `1 Minute` | Evaluates the rule every minute to ensure quick, sub-minute alert firing. |

### Static vs. Dynamic Thresholds
*   **Static Thresholds** (Used here): Ideal for resources with a known, fixed threshold (e.g., CPU > 90%, Disk Space < 10%, or strict rate limiting of 50 operations). They are simple to configure and leave no ambiguity.
*   **Dynamic Thresholds**: Recommended for metrics with hourly, daily, or weekly patterns (e.g., user traffic to a web portal). Azure Monitor uses machine learning to build a baseline and alerts on outliers (e.g., an unexpected drop in traffic on a Tuesday afternoon).

---

## 4. Log Alert Query (KQL)

In addition to metric alerts, log-based alert rules monitor detailed diagnostic events. The following Kusto Query Language (KQL) query is configured in Log Analytics to detect client/server errors:

```kql
StorageBlobLogs
| where TimeGenerated > ago(1h)
| where StatusCode >= 400
| project TimeGenerated, AccountName, OperationName, StatusCode, StatusText, Uri, CallerIpAddress
| summarize ErrorCount = count() by AccountName, OperationName, StatusCode
| where ErrorCount > 5
| order by ErrorCount desc
```

### Log Alert Logic
*   **Scope**: Scans the `StorageBlobLogs` table, which collects resource diagnostics.
*   **Filter**: Filters for `StatusCode >= 400` to catch client-side authentication errors (e.g., `403 Forbidden`) or missing resources (e.g., `404 Not Found`).
*   **Threshold**: Summarizes errors and alerts if the volume of API errors exceeds 5 occurrences in a 5-minute evaluation window. This prevents single-user issues from firing false alarms, while flagging system-wide failures.
