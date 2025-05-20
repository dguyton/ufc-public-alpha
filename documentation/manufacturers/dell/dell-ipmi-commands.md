# Dell IPMI Commands
Determining whether a Dell server allows manual fan speed control via IPMI can be challenging. A plus regarding Dell servers is that the associated IPMI raw commands are consistent across different iDRAC releases. This means the commands described below should work regardless of server model.

## Order of Operations
After determining [which fan control method](dell-fan-control-methods.md) is most appropriate for your use case, it's time to implement IPMI fan controls. The order-of-operations (regardless of fan control method) is:
1. Disable automatic fan control in iDRAC
2. Set fan speed(s)

## Dell Manual Fan Controls Cheat Sheet
Reference tab. All commands are explained below in detail.

| Function | IPMI Command Syntax |
| -------- | ------------------- |
| Disable Auto Fan Control | raw 0x30 0x30 0x01 0x00 |
| Enable Auto Fan Control | raw 0x30 0x30 0x01 0x01 |
| Set All Fans to X% Speed | raw 0x30 0x30 0x02 0xff 0x{hex value} |
| Set Fan X to Y% Speed | raw 0x30 0x30 0x02 0x{fan ID} 0x{hex value} |
| Set Fan Zone X to Y% Speed | raw 0x30 0x30 0x02 0x{zone ID} 0x{hex value} |
| Read All Fan Speeds | raw 0x3a 0x02 |
| Read Fan X Speed | raw 0x3a 0x02 0x{fan ID} |

## Disabling Automatic Fan Controls
On Dell servers, you don't "enable" manual fan speed controls. Rather, you *disable* automatic fan speed controls (which are enabled by default). These automatic controls are also known as *thermal controls* or in some cases, *thermal profiles* when they are visible within the iDRAC web interface. The extent to which automatic fan controls in the iDRAC firmware and BIOS may be defeated varies by iDRAC version and server generation, the nuances of which are discussed [here](dell-idrac-fan-control.md#thermal-profiles). However, regardless of server model, this action is a necessary prerequisite.

Run this IPMI command to disable automatic speed control.<br>
`raw 0x30 0x30 0x01 0x00`

### Enabling Automatic Fan Controls
To enable automatic fan speed controls (i.e. disable manual control), should you ever wish to do so.<br>
`raw 0x30 0x30 0x01 0x01`

## Setting Fan Speeds
Key points to remember when setting fan speeds on Dell servers:
- Commands are the same across all iDRAC releases, all server models
- Fan speed range is 0-100%
	- 0% is not truly zero. It does not mean stopped / not running. The scale is relative. The fan controller will not allow the fan to spin below stall speed.
	- Scale is 0x00 - 0x64 scale, expressed in 2-digit hexadecimal format.
- Some servers enforce a minimum fan speed of 15 or 20%
	- Min speed may be enforced by iDRAC or BIOS
	- You will know this is the case when you attempt to manually assign a given fan speed. The fan may momentarily drop to the speed you requested, and then suddenly increase to its enforced minimum.

## Fan Control Methods
There are three possible methods or styles of manual fan control on Dell servers. They are referred to throughout this document by the following terms:
- 'Universal'
  - All fans are controlled at once.
- 'Direct'
  - Set speed for a specific fan.
  - Each fan header is addressed independently.
  - 1:1 IPMI command to fan ID.
- 'Zoned'
  - Fans are organized in pairs.
  - Each fan pair is typically a pair of identical axial fans designed to be controlled simultaneously. The fans are opposing, which results in increasing their static pressure beyond what either fan would be capable of on its own.
  - Each fan zone is addressed independently. The command appears identical to the 'direct' style, but the command targets both fans in the pair.
  - 1:1 IPMI command to fan zone ID.

### Universal Method
Set speed for all fans.<br>
`raw 0x30 0x30 0x02 0xff 0x{percentage converted to 2-digit hex}`

### Direct Method
Set speed for a specifc fan.<br>
`raw 0x30 0x30 0x02 0x{fan id} 0x{percentage converted to 2-digit hex}`

### Zone Method
Set speed for a specific fan zone (fan group).<br>
`raw 0x30 0x30 0x02 0x{fan zone id} 0x{percentage converted to 2-digit hex}`

> [!WARNING]
> Fan speed settings are not persistent. This means when the server is restarted, it will not remember the prior fan speed settings. They must be re-applied. However, Dell servers DO remember being in manual mode, so that pre-requisite step does not need to be repeated.

## Fans You Can't Control
There are a few potential situations where fans will be reported in the iDRAC web interface, IPMI's fan metadata, or similar hardware sensor tools, and yet there doesn't seem to be any way of managing these fans. What gives? This is by design and occurs when a fan header is locked out from any sort of management, except possibly by the iDRAC controller or BIOS.

Fans may exist that cannot be controlled via the [BMC](/documentation/lexicon.md#bmc)'s fan controller. These are special purpose fans with use cases that fall outside the parameters of normal server chassis and CPU cooling duties. The most common of such scenarios are power supply fans (sometimes referred to as PSU fans, where PSU = Power Supply Unit) and 3rd party graphics card fans. 

### PSU Fans
While nearly all power supplies have built-in fans, most of them do not report their fan status to a motherboard or fan controller. However, some do. For example, the PowerEdge R510 has four (4) primary fans. Depending on the sub-model, a 5th fan may appear to be present in the iDRAC web interface and/or when gathering sensor data via IPMI. When present, the 5th fan is for the power supply unit (PSU).

Under rare occasions (such as with the R510), PSU fans will report their state and possibly other information (such as current fan speed) to the iDRAC controller or BIOS. These fans cannot be directly controlled via IPMI or any other means.

### Add-on Card Fans
Add-on expansion cards - and especially PCI-express cards - may contain their own cooling fans. Graphics cards frequently have dedicated, on-board cooling fans. Ordinarily, these fans are not seen by the motherboard or the BIOS. However, Dell handles things a bit differently than most other server manufacturers.

First, if the add-on card is a *Dell branded card*, it will be seen by and communicate with the iDRAC controller. When that is the case, the card's fans may or may not appear in the iDRAC web interface or IPMI sensor data, just like the PSU fan topic discussed above. That doesn't mean you can control them with IPMI commands like standard fan headers. Most of the time, you won't be able to control them directly, and they will follow their own built-in thermal management profile, which is managed by the iDRAC controller. Dell add-on PCI-e cards have thermal sensors embedded on the card, which report their state to iDRAC. This affords the iDRAC controller an opportunity to take over fan control and ramp-up fan speeds if the card begins over-heating. If and when this occurs, the server will override your manually settings set by IPMI. This is a thermal algorithm you cannot defeat.

#### 3rd Party PCI-Express Response State
On the other hand, when the add-on card is a *third-party branded* PCI-e card, the Dell server will detect the presence of the card and determine it is a non-Dell product. Even if the add-on card has some sort of thermal sensors, iDRAC will not see them. At this point, most Dell servers will trigger what Dell refers to as the, "3rd Party PCI-e Response State." This effectively means the server cannot identify the card, assumes a worst-case scenario, and maximizes fan speeds.

While obviously wholly unnecessary most of the time, one can think of this activity as placing the server into a failsafe mode. Dell's view is it's better to err on the side of running all fans at full speed versus potentially having a PCI-e card meltdown because the server was not aware it was overheating.

Thankfully, it is possible to defeat this onerous feature. The process is explained [here](dell-idrac-graphics-card-max-fan.md).

## Other Dell Nuances
Here are some other things you may encounter or wish to know with regards to using IPMI to control fans on Dell servers. This section is intended for informational purposes only.

### How Missing Fans Are Reported
When reading fan status via IPMI sensors commands, Dell servers may report disabled or missing fans as "ns" in the column for RPM reading, where "ns" means "no signal." They may also appear as "na" (not available).

### Reading Fan Speeds
Reading current fan speeds is also possible via IPMI. This command can be used to request current fan speeds for all fans (universal mode) or a specific fan only (direct mode).

Read and report all fan speeds.<br>
`raw 0x3a 0x02`

Read and report a specific fan speed. This works regardless of whether or not a server supports the direct mode of fan control. For example, when a server supports universal and zoned methods only, this command still reports the current fan speed for the specified fan only.<br>
`raw 0x3a 0x02 0x{fan ID}`

### Fan ID Offsets
When utilizing the *direct* or *zoned* fan control methods, bear the following in mind when crafting your IPMI raw commands:
1. Fan header (Fan ID) numbering starts with 0
	1. Example: A system with 4 fans will have fan IDs from 0-3
		1. Fan # 1 = Fan ID 0 = 0x00
		2. Fan # 2 = Fan ID 1 = 0x01
		3. Fan # 3 = Fan ID 2 = 0x02
		4. Fan # 4 = Fan ID 3 = 0x03
2. Fan zone numbering starts with 0
	1. Same numbering convention as Fan IDs above, but for Zone IDs (group of fans)
	2. Most boards have just one or two zones
3. System fan numbers vary. Dell servers consistently use the "FAN*x*" ID nomenclature, where x = an integer. For example, "FAN1", "FAN2", etc.
4. Fan numbering/names physically imprinted on the motherboard may mimic how iDRAC and IPMI see their names (e.g. "FAN3"), but often will have more useful monikers such as "CPU_FAN1" or "SYS_FAN2."
5. iDRAC and IPMI process fan names only as mentioned above (e.g. "FAN4"). They do not understand, and have no reference to, the names of fans imprinted on the motherboard (e.g. "CPU_FAN0"). This distinction is important when referencing documentation or physical inspection, as the hardware labels may not match how iDRAC indexes the fans.
6. When a server utilizes fan *zones*, its manual may provide insight into which fans are grouped into each fan zone. When this is true, the information indicated in the server manual will correlate to the fan names imprinted on the motherboard. This information is helpful even if it's not clear which fan zone is which. At that point, a bit of experimentation should clarify the situation and allow organizing manual fan control IPMI commands appropriately.
7. Older Dell servers tend to follow a methodical order in terms of how iDRAC associates its internal fan ID to each fan. Typically, FAN0 starts on the left front corner of the server. Fan numbers then increment proceeding backward along the left side, across the back, and forward on the right side, terminating at the right front corner or center front. This may not always the case, but it is a common scenario. IPMI should map the fans in the same order as iDRAC, but again this is not guaranteed to always be true.
8. The majority of Dell servers have at most 7 fans (usually labeled FAN0 - FAN6).

## Estimating PWM Fan Duty vs. RPM
Some people wish to target a particular speed for server fans based on a pre-determined RPM setting. Implementing this strategy typically requires some trial-and-error as what IPMI requires as input is fan duty (percentage of power).

The challenge therein lies with the fact there is no standard formula to correlate the relationship between fan duty and RPMs. The answer is always going to be specific to the server model and fan characteristics (mostly the latter), and depends on the minimum and maximum speeds of any given fan. Other factors, such as slight variances in power delivery between different fan controllers, may also impact the result. 

Below is a list of ballpark values based on observations of a typical server fan with a maximum rated speed of 15k RPM. This will provide a base model for what to expect with similar fans. Bear in mind these figures can vary quite wildly from fan to fan. The same fan in a different server model should behave very closely to the same fan's thresholds in another server.

This chart is for informational purposes only. Note input power percentage does not produce a perfect ratio compared to the maximum fan speed.

| PWM %<br> | Hex  | RPM    |
| :-------: | ---- | ------ |
|    15     | 0x0f | 3,200  |
|    20     | 0x14 | 3,900  |
|    25     | 0x19 | 4,500  |
|    30     | 0x1e | 5,200  |
|    35     | 0x23 | 6,000  |
|    40     | 0x28 | 6,600  |
|    50     | 0x32 | 8,000  |
|    60     | 0x3c | 9,400  |
|    70     | 0x46 | 10,800 |
|    80     | 0x50 | 12,100 |
|    90     | 0x5a | 13,300 |
|    100    | 0x64 | 15,000 |

## Troubleshooting
If IPMI commands fail silently or behave inconsistently, consider checking the following:
1. Ensure IPMI over LAN is enabled, and that your IPMI client is not being blocked by ACLs or VLAN segmentation.
2. BIOS updates or firmware bugs can cause unexpected fan reporting behavior. Check for recent updates. Consider rolling them back in order to experiment and determine if this is the root cause of inconsistent or unexpected fan behavior if your commands were prevously working as expected.
