# Supermicro's Fan Control Methodology: Zones
[Baseboard Management Controller](/documentation/lexicon.md#bmc) (BMC) chips actively manage server motherboard fans by monitoring and controlling signals sent to and from the Fan Controller (the hardware embedded on the motherboard that does the actual physical manipulation of power and tachometer monitoring of the on-board fan headers). On Supermicro boards, the fan headers are monitored individually, but controlled in groups. Each fan header is batched into a "zone" and it these "zones" to which fan speed requests must be addressed. It doesn't matter if it's a manual fan speed request such as through [IPMI](/documentation/lexicon.md#ipmi) or via the BIOS. The BMC is configured to group the fans into these zones in a pre-determined order that is set by Supermicro at the factory when configuring the BMC on the board.

## Fan Header Naming Conventions
Fan headers are labeled in sequential order based on the Zone they belong to. Zones are almost always identified based on a single integer, with 0 and 1 being the most prolific (i.e., Zone 0, Zone 1). The typical Supermicro server board will have one (1) or two (2) fan zones. The fan headers will be labeled on the motherboard and in its manual with a unique prefix based on the zone the fan header belongs to. Each fan header belonging to the specified zone will be numbered sequentially.

The most common nomenclature is FANx where x = {alpha character}. Fan headers in Zone 0 always have an integer suffix. For example, "FAN5" would be labeled as such on the motherboard itself, but belong to Fan Zone 0.

Fan headers in Zone 1 always have a letter indicating it belongs to Fan Zone 1. For example, "FANA" and "FANB" would represent different fan headers, both of which belong to fan zone 1.

## Fan Header Prefixes
The "FAN" prefix is by far the most common. However, some boards will utilize a combination of one or more of the following prefixes:
- FAN
- SYS_FAN
- CPU_FAN

## CPU Fan Zone Designation
An important factor in the layout of your system is understanding how Supermicro boards tend to perceive the relationship between CPU cooling and their fan zones. It can be challenging to determine which fan headers any given Supermicro motherboard considers to be responsible for cooling the CPU(s). While this is not always true, generally speaking fan zone 0 or fan headers with a numeric suffix are expected to be assigned to CPU fans. If you are operating a Supermicro server and just relying on its [built-in fan modes](supermicro_fan_modes.md) for CPU and chassis cooling, the Optimal and Standard fan modes will adjust fan speeds differently by zone based on the BMC's presumption of which zone is assigned to the CPU cooling fans.

### Only One Fan Zone
When there is only one (1) fan zone, then of course the fan header naming convention and other factors don't matter. It _is_ the CPU fan zone. This means that regardless of what else you'd like your server fans to cool (e.g. disk devices), you must treat all fan headers as if they are cooling the CPU. Thus, the CPU thermals must dictate minimum fan speeds.

### Multiple Fan Zones
An advantage of being able to manually control server fans is that it's often possible to arbitrarily determine which fan headers will be responsible for CPU cooling and which will manage peripheral (device) cooling duties. Having flexibility in controlling fan headers - even only at the zone level - provides system administrators with more options to assign specific fan headers to specific cooling responsibilities.

When you don't have the luxury of manually controlling the fan headers, then it becomes more important to correctly discern which zone the BMC expects to be responsible for CPU cooling duty. When this is not obvious (i.e. there's no fan zone with prefix "CPU") then Zone 0 should be presumed to be the CPU cooling zone.

It is very rare for a Supermicro motherboard to have more than two (2) fan zones, but there are a few exceptions. For example:
- Supermicro model X12DPG-QT6 is a server-class board with three (3) distinct fan zones. One (zone 0) is dedicated to cooling its two (2) CPUs. The other eight (8) of its total ten (10) fan headers are managed by Zone 1 (fan headers FAN1-FAN4) and Zone 2 (fan headers FANA-FAND).
- A sister board - model X12DPG-QR - and the X12DHM-6 also sport three (3) fan zones, but with a slight nuance. The latter boards are interesting as their fan header numbering is non-linear.
- On the X12DPG-QR and X12DHM-6, they have a total of 10 fan headers, and the CPU fan headers are labeled FAN9 and FAN10. However, the other eight (8) fan header names are split into FAN1-4 and FANA-D. Thus, the fan zones equate to groupings of 4, 4, and 2 fan headers.

Other similar exceptions also exist, under other model numbers, but again these are very rare. They also appear to be limited to the X12 and H12 generations of server boards.
