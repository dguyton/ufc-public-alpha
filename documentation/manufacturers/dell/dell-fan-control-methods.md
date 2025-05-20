# Dell Manual Fan Control Methods
Once you have [decided on a particular Dell server](dell-server-buyers-guide.md) and are familiar with the nuances discussed at length in [Dell Server Fan Control](dell-idrac-fan-control.md), it's time to decide which IPMI fan control method is most appropriate for your circumstances.

## Universal, Direct, and Zoned
All Dell servers with the capability of controlling fans manually via IPMI utilize one (and usually two) of three methods: *Universal*, *Direct*, or *Zoned*.
- Universal: All fans are controlled simultaneously, with a single command.
- Direct: Fan speeds are set independently by Fan ID, with each fan requiring a separate command to alter its current fan speed.
- Zoned: Fan speeds are set according to pre-defined groups called *zones*. Each fan header in the same group has its speed set to the speed assigned to its Zone ID. This method is a hybrid of the other two.

You have no choice in which methods are available for any particular motherboard, but you do have a choice in which of the two are utilized.

## Fan Control Method by Server Gen
All Dell motherboards allowing manual fan control via IPMI support the "universal" fan mode and either the direct or zoned method. Which fan control methods are possible for any given server are directly dependent on the iDRAC controller hardware and firmware present on the server. 
- **Gen 10, 11, 12**
	- Universal
	- Direct
- **Gen 13, 14**
	- Universal
	- Zoned
- **Gen 15+**
	- Universal + Zones via iDRAC web user interface
	- [Downgrading](dell-idrac-swaps.md#idrac-version-downgrades) to [specific iDRAC 9](dell-idrac-fan-control.md#3-goldilocks-idrac-9-v3000000---v3323232) versions may unlock universal + zoned

As you can see from the information above, servers with iDRAC 6 or 7 generally support universal and direct fan control methods, and servers with iDRAC 8 or 9 usually support universal and zoned fan control methods.

## Risks
The reason Dell moved away from allowing manual fan control capabilities, and toward the zoned method is primarily due to risk mitigation. In this case, the risk that a user bricks their server due to inadequate cooling management.

### Universal Fan Control Risks
The universal fan control method is ubiquitous on PowerEdge servers supporting IPMI fan control. While it is the simplest process to control fan speeds, since all fans receive the same instruction, it can be an inherently risky approach under some circumstances. Think about a server that is passively cooled versus a server with active CPU coolers. When this is the case, universal fan control is typically appropriate. Passive CPU cooling dominated most Dell PowerEdge servers up until around gen 13, when the industry tide began shifting toward more demanding cooling requirements for rack servers in particular. This is why especially with iDRAC 8, there is some variation between iDRAC firmware versions in terms of which do or do not allow manual control of fans through IPMI.

Beginning with late gen 14 / early gen 15 server models, active CPU cooling began to become more prevalent (though passive CPU cooling is still quite common even in smaller height newer generation server models). This shift to more servers with dedicated, active CPU fan coolers, and more chassis fans coincided with Dell's efforts to lock down manual fan speed controls rather dramatically (iDRAC 9).

#### Factors to Consider
1. Are CPUs actively cooled by CPU fans?
2. Are CPUs actively cooled by dedicated chassis fans?
3. Do any hardware components require more robust cooling than others?
4. How will internal chassis airflow be impacted by the use of a universal fan speed?

### Individual Fan Control Risks
Granular control over individual fan speeds can be both a blessing and a curse. It can be more challenging to manage ambient temperatures inside the chassis when choosing this targeted fan control method. However, it can also be rewarding in the sense that it allows tweaking fan performance to address specific needs or concerns.

Careful planning is crucial if you choose to adopt this method. It is imperative that you understand your server's ecosystem well, and how each fan's performance influences hardware components and individual temperature sensors. The greatest risk lies in underestimating the cooling needs of hardware components placed near fans you choose to limit to a slower fan speed. However, this potential problem can be successfully mitigated through the intelligent incorporation of temperature sensors into your overall server cooling plan.

### Zoned Fan Control Risks
There really aren't any downside risks to the zoned fan control method. This is why Dell decided to move in this direction beginning with gen 14 servers, and how its automated thermal profiles operate (including in servers prior to gen 14). The challenge in using the zoned fan control method lies simply in figuring out how many fan zones there are on a given server, and which fan headers belong to which fan zone. Unfortunately, this information is a matter of discovery, as Dell has never published such information.

The iDRAC controller and/or firmware determine the composition of each fan zone, which also varies by server model/motherboard configuration. Which fan headers are in which fan zone is hard-coded into the iDRAC controller and cannot be modified. It's also impossible to know ahead of time, though this information can be gleaned through trial-and-error. While connected to the iDRAC graphical user interface (GUI) via a web browser to control fan speeds for each zone, observe the change in each fan's behavior and map which fans belong to which zone.

## Next Steps
After deciding which fan control method you wish to utilize, it's time to implement your strategy with corresponding [IPMI commands](dell-ipmi-commands.md).
