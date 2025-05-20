# ASRock Server Motherboards and Manual Fan Control
ASRock (more specifically, the company's server division: ASRock Rack) is one of the most transparent and straight-forward manufacturers of mainstream and popular server motherboards. While most such companies attempt to conceal any capabilities of their products' to allow end users to manually control cooling fans, ASRock at least tends to be more forthcoming when bluntly asked to answer related questions.

## General Information

## ASRock Variations of Fan Control
ASRock motherboards almost exclusively utilize ASPEED BMC chips and typically use one of the following:
- ASPEED AST2300
- ASPEED AST2310
- ASPEED AST2400
- ASPEED AST2500
- ASPEED AST2510
- ASPEED AST2600

### Minimum fan speed
-	Beginning in ~2019, some motherboards enforce a minimum fan speed of 20%
-	A few boards have a minimum fan speed of 30%
-	ASRock boards not subject to the 20% or 30% minimum enforce a minimum fan speed of 4%

### Fan Control Iterations
Every motherboard manufacturer is able to make some customizations to how the BMC works on any given board. Most choose a consistent path in order to make the process of programming the customizable portion of the BMC's firmware a simpler and easily repeatable task. However, this is not the case with ASRock. There are several variations of ASRock's implementation of fan control, even when different motherboards have the same BMC chipset. Therefore, the presence of a particular BMC chipset on a board in and of itself is not a reliable indicator of which IPMI command schema will work, if any. For example:
- There are four (4) different implementations by ASRock of managing fans with the ASPEED AST2300 BMC chipset.
- There ae multiple implementations of the ASPEED AST2500 BMC chipset.

A factor that *is* consistent is that ASRock BMC logic *expects* fan control commands addressing fans to include every fan header, *regardless of whether each fan header has a fan physically present or not*. For most ASRock boards this means sending a command to all possibly existing fan header positions at once; all 16 of them. However, in reality one can ignore the trailing bytes pertaining to non-existing fan headers as motherboards without the maximum possible 16 fan headers will ignore command bytes addressed to non-existent positions.

For example, regardless of how many fan headers are physically present on the board, to set all existing fan headers to "manual" mode, one would address the command to all 16 possible fan headers, like so:

```
ipmitool raw 0x3a 0xd8 0x1 0x1 0x1 0x1 0x1 0x1 0x1 0x1 0x1 0x1 0x1 0x1 0x1 0x1 0x1 0x1
```

And to enable "automatic" mode for all 16 fan headers:

```
ipmitool raw 0x3a 0xd8 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
```

An upside to this approach is these commands can be applied universally to boards that understand them, without concern for how many fan headers there actually are.

### Zones???
Some ASRock literature refers to fan "zones," however this is not the same zoned concept used by Supermicro and other brands to control fans in groups. In ASRock parlance it refers to a group of fans that share something in common, such as intended to cool the CPU(s), front or rear fans, etc. Generally speaking, such terminology from ASRock should be ignored when it comes to fan control, as their boards do not control fans by zone.

## Not All BMC Implementations are Equal
Not all ASRock BMC implementations support manual fan speed controls. Some allow limited fan control via the BIOS, but no IPMI based control. Some do not allow either. However, most do permit a wide range of manual fan control. Which do or do not is typically restricted based on the BMC chipset of any given motherboard. For example, ASPEED AST2310 BMC chips generally allow only the BIOS to control fan speeds, while AST2300 and AST2400 (released before and after the AST2310) typically allow at least limited manual fan controls. Therefore, the ability or lack of for users to control system fans is usually predicated by ASRock’s decision regarding which BMC chip to incorporate into a given motherboard model.

## ASRock Fan Header Nomenclature
ASRock boards utilize one of several naming conventions for fan headers, depending on the generation of the motherboard and its BMC chipset. The following are the most common groups of fan name formats.

> [!NOTE]
> A fan name/ID with "_x" or "x_y" nomenclature indicates x of y individually controllable fan headers sharing the same physical fan header. These are normally 6-pin fan headers, where "FAN_1" is the first fan connection and "FAN_2" is the 2nd fan connection on the same physical connector, plugged into the motherboard.

### CPU Fan Headers
- CPU1_FAN1
- CPU2_FAN1
- CPU1_FAN1_2
- CPU1_FAN1_2

### Front Fan Headers
- FRNT_FAN1
- FRNT_FAN2
- FRNT_FAN3
- FRNT_FAN4
- FRNT_FAN1_2
- FRNT_FAN2_2
- FRNT_FAN3_2
- FRNT_FAN4_2

### Rear Fan Headers
- REAR_FAN1
- REAR_FAN2
- REAR_FAN1_2
- REAR_FAN2_2

### Numeric Fan Headers
- FAN1
- FAN2
- FAN3
- FAN4_1
- FAN4_2
- FAN5_1
- FAN5_2
- FAN6_1
- FAN6_2
