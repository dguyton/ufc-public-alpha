# IPMI Guidance for Dell by Server Gen/Model
General guidance related to applying IPMI commands on Dell servers to control fan speeds.

## Dell's iDRAC Shenanigans
Dell server discussions almost always relate to the Dell PowerEdge server line. The ability to control fan speed manually on these servers is directly depending on the server generation and especially which version of [iDRAC](dell-idrac.md) is present. iDRAC (integrated Dell Remote Access Controller) is sort of a cross between a BMC and a BIOS. Not truly either, but with characteristics of both. iDRAC most closely resembles a typical [Baseboard Management Controller](/documentation/bmc-and-server-architecture/bmc.md) (BMC). It is a proprietary hardware and software (firmware) platform for managing low-level remote connections to the server, allowing a remote user to access server hardware outside the operating system.

Dell removed the abiility of IPMI to adjust fan speed as of iDRAC 9 version 3.34.34.34, which was released by Dell on 24 June 2019 as firmware update iDRAC 3.34.34.34 A00. The last version of iDRAC that allows manual fan speed changes is iDRAC 9 version 3.32.32.32, released in April 2019. Some sources caution that on some servers, the last version allowing manual fan control is even earlier (iDRAC 9 version 3.30.30.30). An example of such is the PowerEdge R330 model. I am not able to confirm this information directly. Unless proven otherwise, users should expect iDRAC 9 3.32.32.32 to work.

You may read more details on the history and implications of this change in the following articles:
- [iDRAC History](dell-idrac-fan-control.md#idrac-history)
- [Dell Servers to Avoid](dell-servers-to-avoid.md)
- [Dell Server Buyer's Guide](dell-server-buyers-guide.md)

Another option is to peruse the [Dell iDRAC Limits](dell-idrac-limits.md) comprehensive list of PowerEdge servers and their minimum/maximum supported iDRAC versions. This will give you an idea of which servers are viable for manual fan control and Home Lab usage. If a given server model does not support manual fan control based on its possible range of iDRAC versions the server is capable of, then don't purchase one. It is possible to change iDRAC versions, but there are numerous caveats. If you're considering this route, be sure to consult the [Swapping iDRAC Versions](dell-idrac-swaps.md) article before you make a final decision.

### Basic iDRAC Navigation
How to find your version? iDRAC has a Web-based interface. The default iDRAC IP address 192.168.0.120.
Upon login, the version is displayed at the upper left of the iDRAC along with the iDRAC license level.

## Consistency in IPMI Raw Commands
One highly positive attribute of Dell is that the IPMI raw commands to control fans are generally consistent across server generations and models. For most PE servers, the following guidelines will work. This presumes a suitable version of iDRAC is in use that supports manual fan control in the first place.

1. All numbers are hexadecimal for the RAW command.
2. Fan duty speed range is either 0-255 or 0-100 depending on board. When the 0-255 range is applicable, this means 0 = 0% PWM and 255 (0xFF) = 100% PWM. You must calculate the ratio in order to determine the correct hex value. For example, 50% PWM would equate to 0x80. If the server uses the 0-100 range (most newer gens), then the 10-base integer to hex conversion is direct (i.e. no factoring, e.g., 25% PWM = 0x19).
3. Fans may be managed either individually or all together.
4. When reading fan status, Dell may report a fan as "disabled" in the RPM column with "ns" indicated as the fan's state. "ns" means "no signal." This is iDRAC telling you it believes the fan header in question has no fan connected to it.

## Manual Fan Speed Controls
Most Dell server-class motherboards follow the same basic IPMI command syntax in terms of setting fan speeds manually.

First, before manual fan speed controls will function, it must be explicitly enabled via a separate command. This involves a bit of reverse-logic thinking. Rather than enabling manual fan control, one must disable automatic fan control. If you fail to follow this procedure first, subsequent manual fan speed commands will be ignored.

### Disabling Automatic Fan Speed Control
By default on boot-up, all fans are set to automatic fan speed control, meaning all fans are controlled by the BMC's built-in algorithms (thermal curves).

To enable manual fan speed control, auto mode must first be disabled for all fans:
```
raw 0x30 0x30 0x01 0x00
```

To enable automatic fan speed control for all fans:
```
raw 0x30 0x30 0x01 0x01
```

### Speed 0 = Auto
To enable automatic fan speed control *for a particular fan ID only*, set its fan speed to zero (0). This instructs iDRAC to set that fan to *Smart Fan Mode*, which is Dell's term for automatic fan speed control.
```
raw 0x30 0x30 0x02 0x{fan_id} 0x00
```

### Setting Fan Duty Speeds
```
raw 0x30 0x30 0x02 0x{fan_id} 0x{fan_speed}
```

This command has been verified directly on PowerEdge models T630, R230, R720XD, R630, and RX40. By extension, it should also work on all of the following PE models:
- R210 II
- R410/R420
- R510/R520
- R610/R620/R630
- R710/R720/R720xd/R730
- R820/R830
- T230/T320/T330/T630

To set the speed for all fans simultaneously, substitute "0xff" for the fan ID.

```
raw 0x30 0x30 0x02 0xff {speed in hex}
```

### Fan Naming Conventions
Most Dell PowerEdge servers stick with a simple fan nomenclature system. The most common is the atypical "FAN{x}" model. For example, PE models R220II, T620, and T330 all have three (3) fans with IDs FAN 1, FAN 2, and FAN 3 respectively. However, this model is not universal. As an example of a non-conforming PE server, the R330 bucks the trend with fans named FAN1A | FAN1B | FAN2A | FAN2B | FAN3A | FAN3B | FAN4A | FAN4B.

## Dell PowerEdge Gen 12, Gen 13
PowerEdge generations 12 and 13 are some of the most reliable and consistent PE servers that Dell produced. Most models fall into the "sweet spot" for Home Lab useage where the cost, form factor, reliability, and flexibility of these servers is likely to align nicely.

## PowerEdge R710/R720/T130 Quirks
PowerEdge server models R710, R720, and T130 have an additional fan module dedicated to cooling third-party PCIe cards. This separate fan module is addressed independently of the CPU and system fans. A detailed explanation of how to manage this fan can be found [here](dell-idrac-graphics-card-max-fan.md).

### PowerEdge R710
The R710 is rather finicky. Some potential issues you may encounter, related to cooling fans:
- BMC may not report CPU temps (at all)
- iDRAC may prevent the server from completing post-boot when the following conditions are true:
  - Two (2) CPUs are installed; and
  - All five (5) fan headers do not have a fan present (status = OK)
