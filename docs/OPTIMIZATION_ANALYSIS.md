# Cost Optimization Analysis

All figures are USD per month, West Europe, taken from the `Optimization Scenarios` sheet of the workbook. The pay-as-you-go baseline for the full architecture is **$679.58/month**, and the web-tier VMs alone account for $302.22 of it (44%). That concentration is the first lesson: optimize compute before anything else, because nothing else in this stack comes close.

## Scenario 1: Pay-as-you-go vs Reserved Instances

The two D2s_v5 Windows VMs run 24/7, which makes them ideal reservation candidates. A reservation discounts the compute meter only; the Windows license meter keeps ticking at $0.092/hour per VM unless Hybrid Benefit removes it (scenario 3).

| Billing option | Cost/month (2 VMs) | Saving vs PAYG |
|---|---|---|
| Pay-as-you-go | $302.22 | — |
| 1-year Reserved Instance | $233.45 | $68.77 (22.8%) |
| 3-year Reserved Instance | $199.00 | $103.22 (34.2%) |

The 3-year term saves an extra $34/month over the 1-year, but locks the SKU choice for three years. For a young product whose traffic profile might change, the 1-year reservation is usually the saner bet; you give up some discount for the option to re-size in twelve months.

## Scenario 2: LRS vs GRS storage redundancy

Geo-redundant blob storage costs exactly double locally redundant ($40.14 vs $20.07 for 1 TB Hot). GRS buys survival of a full regional outage. For this workload the blob container holds static assets and database exports, and the SQL database already has its own backup story, so LRS is defensible and halves the line item. If the container held the only copy of customer data, the $20 would be cheap insurance and the answer would flip.

## Scenario 3: Azure Hybrid Benefit

Applying existing Windows Server licenses (with Software Assurance) zeroes out the OS license meter on both VMs:

| Option | Cost/month (2 VMs) | Saving vs PAYG |
|---|---|---|
| PAYG + Hybrid Benefit | $167.90 | $134.32 (44.4%) |
| 3-year RI + Hybrid Benefit | $64.68 | $237.54 (78.6%) |

Two things stand out. Hybrid Benefit alone beats a 3-year reservation, which surprises most people pricing Windows VMs for the first time. And the levers stack, because they discount different meters: the reservation cuts compute, the license benefit cuts licensing. Stacked, the web tier drops from $302 to $65. Hybrid Benefit also applies to Azure SQL, but only in the vCore model; our S2 DTU tier bundles the license invisibly, which is a real argument for switching to vCore once SQL spend gets big enough to matter.

## Scenario 4: IaaS vs PaaS for the web tier

Replacing the two VMs, their managed disks, and the load balancer with an App Service plan (2× P1v3 instances, same 2 vCPU / 8 GiB shape) gives a result worth staring at:

| Web tier option | Cost/month | vs IaaS baseline ($371.51) |
|---|---|---|
| App Service P1v3, Windows, 2 instances | $530.00 | +$158.49 (43% more) |
| App Service P1v3, Linux, 2 instances | $274.00 | −$97.51 (26% less) |

Windows PaaS costs more than self-managed Windows VMs at list price. Linux PaaS costs less than the VM setup while also absorbing the load balancer, OS patching, autoscaling, and deployment slots. So "is PaaS cheaper?" has no single answer; the OS choice dominates. The honest comparison also counts the hours nobody bills: with VMs, someone patches Windows at 2am after a CVE drops. App Service makes that Microsoft's problem.

## Putting it together

| Scenario | Total/month | Saving vs baseline |
|---|---|---|
| Baseline: PAYG Windows VMs + GRS blob | $679.58 | — |
| Optimized: 3-yr RI + Hybrid Benefit + LRS blob | $421.96 | $257.61 (37.9%) |

Same architecture, same performance, same SLAs. The 38% reduction comes entirely from how the resources are paid for, not from cutting anything users would notice. A further step (Linux App Service for the web tier, vCore SQL with Hybrid Benefit) could push beyond that, at the cost of a re-platforming effort this analysis treats as out of scope.

## Regional footnote

The identical SKUs priced in East US instead of West Europe come out roughly 9–20% cheaper depending on the service (compute carries the biggest premium). Region choice is a cost lever too, but data residency and latency usually decide it before price gets a vote.
