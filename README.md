# Azure Monitor Alerting Strategy — Configuration Report

This report walks through the design decisions, configuration values, and threshold reasoning behind the proactive monitoring setup deployed in Azure.

---

## 1. Scope of Monitoring & Metric Choice

### Resource Under Monitoring
*   **Resource Type**: Azure Storage Account (General Purpose v2)
*   **Scope**: Lives within the `rg-alerts-demo` resource group
*   **Naming**: Generated automatically (e.g., `alertstore12345`) to satisfy Azure's global uniqueness requirement for storage account names

### Core Metric Tracked
*   **Metric**: `Transactions` (Total Transactions)
*   **Namespace**: `Microsoft.Storage/storageAccounts`
*   **Aggregation**: `Total`
*   **What it captures**: The volume of API operations hitting the Storage Account — uploads, downloads, listing blobs, deleting containers, and similar calls

### Why This Metric Was Chosen
Storage Accounts sit underneath most cloud architectures as a foundational layer. A sudden jump in transaction volume can point to a few different things:
1.  **A runaway application or bug** — code stuck in a loop repeatedly hitting storage
2.  **Suspicious or malicious activity** — scanning attempts or brute-force authorization tries from outside actors
3.  **Genuine growth in usage** — a legitimate increase in business traffic that may warrant a scaling conversation

---

## 2. How Alerts Get Delivered (Action Group)

Monitoring only has value if someone is actually notified when something happens — this is the "closed-loop" half of the setup.

*   **Action Group**: `EmailAlertsGroup`
*   **Short Name**: `email-alerts`
*   **Channel**: Email (the configuration supports adding other channels later)
*   **Recipient**: `nzemikez@gmail.com`
*   **Common Alert Schema**: Turned on — this gives every alert a consistent payload structure, which makes it easier to parse downstream by webhooks or other systems

---

## 3. How the Metric Alert Rule Was Built

| Setting | Value | Why |
| :--- | :--- | :--- |
| **Name** | `StorageTransactionsAlert` | Makes the alert's purpose obvious at a glance |
| **Severity** | `Sev 3` (Informational) | A traffic spike is worth flagging but isn't on its own evidence of an outage |
| **Threshold Type** | **Static** | A fixed, predictable limit suits a baseline API metric like this one |
| **Operator** | `GreaterThan` | Fires once activity climbs past the set limit |
| **Threshold** | `50` | Deliberately set low so the alert is easy to trigger while testing |
| **Granularity** | `1 Minute` | Buckets transactions into 1-minute windows to catch sudden spikes quickly |
| **Frequency** | `1 Minute` | Re-checks the rule every minute, keeping the alert responsive |

### Choosing Static Over Dynamic Thresholds
*   **Static** (what's used here): A good fit when the acceptable limit is already known and fixed — things like "CPU over 90%", "disk space under 10%", or a hard cap of 50 operations. Easy to set up and leaves no room for guesswork.
*   **Dynamic**: Better suited to metrics that naturally rise and fall with time-of-day or day-of-week patterns — web portal traffic, for instance. Azure Monitor learns the normal pattern using machine learning and flags anything that deviates from it, such as an unusual traffic dip on a weekday afternoon.

---

## 4. Log-Based Alert Query (KQL)

Beyond the metric alert, a log-based rule was also set up to catch detailed diagnostic events. The Kusto query below runs against Log Analytics to surface client and server errors:

```kql
StorageBlobLogs
| where TimeGenerated > ago(1h)
| where StatusCode >= 400
| project TimeGenerated, AccountName, OperationName, StatusCode, StatusText, Uri, CallerIpAddress
| summarize ErrorCount = count() by AccountName, OperationName, StatusCode
| where ErrorCount > 5
| order by ErrorCount desc
```

### How the Query Works
*   **Source table**: Pulls from `StorageBlobLogs`, where diagnostic logs for the storage resource are collected
*   **Filtering**: Narrows results to `StatusCode >= 400`, catching things like authorization failures (`403 Forbidden`) or missing resource errors (`404 Not Found`)
*   **Alert condition**: Groups and counts errors, only firing when more than 5 occur within the 5-minute evaluation window — this avoids noisy alerts from a single isolated failure while still catching broader, system-level problems
