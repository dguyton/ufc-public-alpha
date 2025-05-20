# Disk Inventory Management
There are two key components to disk inventory management in UFC:
1. The Builder's snapshot of initial disk inventory.
2. The Runtime's periodic inventory polls.

UFC disk inventories are not exhaustive - they simply record the device names used by the operating system to reference each disk (e.g., `/dev/sda`, `/dev/sdc1`). This minimal approach is sufficient for UFC to determine whether disks are present - and if so, which ones. This matters not only for monitoring purposes, but also for cooling logic: if no disks are present, UFC has no need to assign any fan groups to storage device cooling.

## Builder Inventory Process
The Builder establishes the initial disk inventory benchmark. This snapshot becomes the baseline against which all future inventory checks are compared.

## Launcher Init Disk Scan
Each time the Launcher initializes, it performs a fresh disk scan and compares the results against the baseline set by the Builder.

If they match, the Launcher:
1. Passes the baseline inventory to the Runtime program.

If they don't match, the Launcher:
1. Inserts a warning into the program log or system log (depending on configuration).
2. Discards the original baseline and adopts the current disk list as the new baseline.
3. Passes the updated baseline inventory to the Runtime program.

## Runtime Periodic Disk Scans
Once initialized, the Runtime script conducts periodic disk scans to detect any disks that have been added, removed, or failed. Since many servers have hot-swap bays, device changes are expected and not treated as errors - though they are still important events.

When this occurs, the Runtime program behaves similarly to the Launcher:
1. Inserts a warning into the program log or system log (based on configuration).
2. Updates the baseline to reflect the current inventory.

## Best Practice: Re-run the Builder After Permanent Disk Inventory Changes
If disk inventory changes are made intentionally and expected to be permanent, the Builder should be re-run. This action resets the baseline.

Failing to do so can result in misleading alerts. Each time the server restarts, the Launcher will detect a discrepancy between its `.init` file and the actual inventory, triggering alerts (including emails, if enabled).

Although it may seem tedious to re-run the Builder, doing so ensures disk alerts remain meaningful. For example, if a disk fails and the baseline is never updated, UFC will issue a warning only once - upon first detection. If that warning is missed or forgotten, the failure may go unnoticed indefinitely.

Persistent warnings serve an important purpose: they remind the user that the issue remains unresolved.

The correct way to silence them is not to ignore them, but to explicitly acknowledge an intentional change by re-running the Builder. This regenerates the `.init` file used by the Launcher - including the updated disk inventory baseline - and prevents false alerts while maintaining the integrity of the monitoring system.

Remaining disciplined with respect to updating the Builder ensures UFC's disk monitoring remains both accurate and useful over time.
