# Configuring Supermicro Boards for Manual Fan Control
After setting custom fan speeds, when rebooting the motherboard it loses your settings. Why is this true when many motherboards don't behavie in this manner when their fans are operated via built-in fan modes? And why do Supermicro boards almost always require the BIOS be placed into "FULL" speed fan mode before IPMI is allowed to make fan speed changes?

## Why You Must Set BIOS Fan Mode to "FULL" Setting
The reason lies in how Supermicro motherboards are designed to control fan speeds automatically. If you think about it, in order to prevent your board components (especially CPUs) from frying shortly after turning on your computer or server for the first time, there has to be a way for the motherboard to always ensure the fans are running in order to prevent this from happening. Although the BMC chip directly controls the on-board fan controller, the BIOS on Supermicro boards issues fan speed controls to the BMC controller under certain circumstances. One of those is when the motherboard is booted or restarted.

Most Supermicro BIOS versions have a repertoire of between two and four fan "modes." Each modes is a pre-defined fan control pattern that includes a thermal fan speed curve. Their main differences are in the starting speed of the fans. 

By default, the BIOS will send frequent fan speed command updates to the BMC, using preset values. These commands instruct the BMC to set each fan zone's PWM fan headers to a particular speed setting, ranging from 0 - 100% power. Each board will have three or four of these built-in modes:
- FULL - 100% fan power
- OPTIMAL - behavior dependent on BIOS default and temperature sensor readings, typically striving to keep the fan speed close to ~30%
- HEAVY I/O - hybrid using Optimal mode for CPU fan zone(s) and  a typical range of 50-70% fan speed for case fan zone(s)
- STANDARD - power fluctuates between 30-70% on most boards, most of the time, with a typical target speed of ~50%

Not all boards support all four modes. Some boards do not support the "Heavy I/O" mode, and some also do not support the "Standard" mode.

## Why "FULL" Mode is REQUIRED to Tweak Fan Speeds via IPMI
Not all Supermicro motherboards allow direct manipulation of fan speeds via IPMI (or Redfish), but many do. When this is the case, these motherboards require the BIOS to be set to a particular fan mode. In the vast majority of cases, the BIOS fan mode must first be set to the FULL setting before tweaking the fan speeds via IPMI. Under a few rare circumstances, a different fan mode is required. Why does this work? The answer lies in understanding the relationship between the BIOS and the BMC on Supermicro motherboards. 

The fan mode dictates when the BIOS sends fan speed commands to the fan controller. The reason it is almost always the "FULL" fan mode that unlocks the ability to control the fans via IPMI or Redfish is because when the BIOS enters the Full fan mode, it instructs the BMC to set all fans to 100% power, and **it then stops sending fan control commands to the BMC**. At this point, the user is free to implement manual fan control without fear of the BIOS constantly overriding their commands.

The BIOS must always be in *some* fan mode. When the BIOS is is any fan mode *other than FULL*, it is constantly sending fan speed updates to the BMC based on the BIOS' fan control and temperature thermal profiles, which are in turn based on the current fan mode. The Full fan mode is the only exception to this rule. The BIOS takes a "fire and forget" approach with the Full mode. It presumes the fans will remain at 100% fan speed, and since there is no need to make any fan speed deviations, it doesn't try to.

## Fan Speed Threshold Violations Overrule
There is an exception of sorts to this rule. If a [fan speed threshold](/documentation/bmc-and-server-architecture/bmc-fan-speed-thresholds.md) stored in the BMC is violated, the BMC will force all fans to 100% power as it enters panic mode in attempt to protect the server. Since the BMC is constantly guarding against this risk, it is important to ensure these fan speed thresholds are set appropriately *before* issuing manual fan speed commands to the BMC. This practice will prevent unwanted surprises in fan speed fluctuations.

## Risks
The bottom line is when configuring a Supermicro motherboard for manual fan speed control, you must first ensure the BIOS is set to "FULL" fan mode and you must be willing to deal with a brief period of time during system startup where you won't have direct control over the fans. Furthermore, there are four circumstances which could trigger an "all fans to 100%" event command from the BIOS or BMC controller after the boot-up process.
1.	Certain temperature sensor critical thresholds are exceeded.
2.	Upper critical fan speed threshold is exceeded for one or more fans.
3.	Lower critical fan speed threshold is exceeded for one or more fans.
4.	BIOS fan mode is set to any mode other than Full, and the BIOS detects any fan speed is outside its expected range, based on the thermal algorithm associated with the BIOS fan mode.

## Examples
This [article](/documentation/bmc-and-server-architecture/fan-speed-threshold-reporting-order.md) explaining fan speed threshold settings on some Supermicro motherboards may be informative.
