# Sensor Reporting
Sensor information is read-only. But, how is it reported? How does UFC know how to parse it?

UFC depends on a select group of tools because it has mappings of data columns for these tools. Depending on which is utilized, UFC relies on the Builder's configuration import process to ensure it has the correct column offests such that data read with these tools is parsed correctly.

## Hardware Configuration Changes
Anytime a physical change is made to the fans, the inventory/config program must be re-run. Doing so re-calculates various parameters and refreshes the Launcher's _.init_ file. This may in turn cause adjustments in the Runtime _.init_ files that are created dynamically by the Launcher. The Runtime's _.init_ file is recreated everytime it is launched by the Launcher.

For example, if a user purposefully adds, swaps, or removes fans. Any hardware configuration changes to the fans - including which fan headers are presumed active - will affect how accurately the program runs and how it monitors the system. In short, fan hardware changes will affect the runtime program's benchmarks, and therefore they must be reset under such circumstances.

## Fan Health Monitoring
Both the Builder and Runtime programs perform several steps to ascertain the presence of and overall health of fans in the system. These processes entail the detection of active fan headers, and the subsequent monitoring of those fans initially identified as active. In order to avoid wasting processing cycles and slowing it down needlessly, the Runtime program is designed to skip fan headers flagged as inactive by the setup program. Furthermore, while the runtime program is active, it also periodically reviews which fan headers are active or inactive, and if a determination is made that a fan header has changed states from active to inactive, that fan header will no longer be monitored. However, the next time the runtime program is restarted (e.g. server reboot), the latter process will reset. In other words, the runtime program always starts off with the presumption all active fan headers reported by the setup program are still active.

### Fan Header Inventory
The setup program validates every physical fan header to determine whether a fan is connected and operational. The setup program then creates an inventory of all active and inactive fan headers. This inventory list is further scrubbed, and the active fans are calibrated. The final results are exported to the init file, which is consumed by the runtime program.

This process flow means if a fan header is scanned and marked inactive by the setup program, but subsequently while operating the runtime program the same fan header becomes active, that fan will be ignored by the runtime program. This is because only active fans verified by the setup program will ever be monitored and actively controlled. To reiterate, if you make changes to the active fan headers, you must re-run the setup program, and then restart the runtime program. Failure to do so will cause the runtime program to ignore those fans because it is not aware of their existence, and will treat those fan headers as inactive.

### Adding, Removing, and Hot Swapping Fans
As described above, when a fan is added, removed, or replaced, the setup program should be re-run. There is one exception to this rule. If a fan is replaced with an identical model, attached to the same fan header, then in theory it should be unnecessary to re-run the setup program. However, due to slight variations in performance of fan samples even of the same model, it is recommended that you re-run the setup program when a fan is added, removed, or exchanged under any circumstance.

### Missing or Inactive Fans at Start-up
The Launcher makes an inventory of expected active fan headers. If one or more fan headers marked active reports an inactive status, the fan header will be marked as suspicious and flagged for follow-up. A few minutes later, the fan will be checked again, and if it fails the second time it will be marked bad and taken out of service. If the fan appears to be working on the 2nd check, the suspicious fan flag will be removed.

#### Hot Swapping Fans is Discouraged
The runtime program performs a fan validation periodically. This scan occurs at different time intervals for CPU versus disk device/case fan zones. During these validation phases, the program is attempting to detect failed or failing fans. For this reason, the practice of hot-swapping fans is discouraged, as it is not inherently supported by this program.

If a fan header becomes inactive after the main runtime program begins, it will be marked as suspicious, and if the inactive state remains for very long, the fan will be marked as bad and excluded from further monitoring. The runtime program has no knowledge of hot-swapping fans. Therefore, if your server chassis allows hot swapping fans, ensure you do this either when the server is off or after it is fully up and running. Do not make fan changes during this program's initialization or upredictable consequences may occur and you may need to reboot the server and re-run the setup program.

### Active Fan Monitoring
What happens when an active fan fails to start correctly for some reason when the server is booted or restarted? There are times when a fan fails to start-up correctly with the other fans in a system, or where a fan stops working and then begins working again, for whatever reason. How does the runtime program view and handle these type of situations?

Provided the glitching fan's fan header was marked as active when the setup program was run, the runtime program will expect that fan header to have an active fan. Therefore, that fan header will be scanned at start-up and durign periodic fan header validation processes. In the event an active fan stops working and appears to be inactive suddenly, the runtime program will flag the fan as suspicious and perform additional validation steps. After a short period of time, the program will determine if the fan has failed or if its state has returned to active and if it is operating with expected parameters. If the fan is restored, the suspicious flag is dropped and the program continues running and monitoring the fan normally. If the fan appears inactive during subsequent, consecutive scans, it will be removed from monitoring service and flagged as bad.
