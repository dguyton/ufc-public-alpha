Database of Tyan motherboard characteristics. This information is limited to server-class motherboards with a BMC chip.

Tyan Computer ("Tyan"), a subsidiary of MiTAC International, is one of the largest manufacturers of server-class motherboards. Tyan is the 6th largest worldwide manufacturer by volume (as of early 2025), Tyan produces more server motherboards than Dell/EMC, Lenovo, or HPE.

Manual fan control capability of Tyan server motherboards is largely dependent upon the BMC chip in question.
- Aspeed AST2050: Not compatible
- Aspeed AST2150: Not compatible
- Aspeed AST2300: Likely not compatible
- Aspeed AST2400: Possibly compatible
- Aspeed AST2500: Likely compatible
- Aspeed AST2600: Possibly compatible

Most Tyan server motherboard model numbers start with "S" for "Server." The model line-ups can be broken down by model number and/or socket type.

## Tyan Boards by Model Prefix

| Model Series | CPU Type |
| ------------ | -------- |
| S3xxx | Intel Atom SoC |
| S5xxx | LGA 1151 / LGA 3647 / Intel Xeon SoC |
| S6xxx | LGA 3647 |
| S7xxx | LGA 2011-3 / LGA 3647 |
| S8xxx | AMD SP3 / AMD TR4 |

## Tyan Boards by Model Prefix, CPU Socket and Type
High-level overview of each series.

| Socket | CPU Type | Max # CPUs |
| ------ | -------- |:----------:|
| S3xxx | SoC | Intel Atom C3000 | 1 |
| S5xxx | SoC | Intel Xeon D-2100 | 1 |
| S5xxx | SoC | Intel Xeon D-1500 | 1 |
| S5xxx | LGA 1151 | Intel Xeon E3-1200 v5/v6/v7 | 1 |
| S5xxx | LGA 1151 | Intel Xeon E5-1600 v3/v4 | 1 |
| S5xxx | LGA 1151 | Intel Xeon E5-2600 v3/v4 | 1 |
| S5xxx | LGA 1151 | Intel Xeon Core i3 Gen 6 | 1 |
| S5xxx | LGA 1151 | Intel Xeon E3-2100 / E3-2200 | 1 |
| S5xxx | LGA 1151 | Intel Core i3 Gen 8/Gen 9 | 1 |
| S5xxx | LGA 1151 | Intel Core i3/i5/i7 Gen 8/Gen 9 | 1 |
| S5xxx | LGA 1151 | Intel Core i3/i5/i7 Gen 6/Gen 7 | 1 |
| S6xxx | LGA 3647 | Intel Xeon Scalable / 2nd Gen | 2 |
| S7xxx | LGA 2011-3 | Intel Xeon E5-2600 v3/v4 | 2 |
| S8xxx | SP3 | AMD EPYC 7002 | 2 |
| S8xxx | SP3 | AMD EPYC 7001/7002 | 1 |
| S8xxx | TR4 | AMD Threadripper | 1 |

## Tyan Server Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan<br>Zones | # Fan<br>Headers | 4-pin | 6-pin | 8-pin<br>(4056) |
| ----- |:----------------------:| --- |:--------------:|:----------------:|:-----:|:-----:|:---------------:|
| S3227 | No <sup>1</sup> |
| S5512 | No | ASPEED AST2150 |
| S5512R | No | ASPEED AST2150 |
| S5539 | ? | ASPEED AST2400 |
| S5542 | ? | ASPEED AST2400 |
| S5542-EX | ? | ASPEED AST2400 |
| S5542-UHE | ? | ASPEED AST2400 |
| S5545 | ? | Intel pGFx |
| S5545-HE | ? | Intel pGFx |
| S5547 | ? | Intel pGFx |
| S5548 | ? | ASPEED AST2500 |
| S5549 | ? | ASPEED AST2500 |
| S5550 | ? | ASPEED AST2500 |
| S5550-EX | ? | ASPEED AST2500 |
| S5552 | ? | ASPEED AST2500 |
| S5552-EX | ? | Intel pGFx (DP) |
| S5555 | ? | Intel pGFx |
| S5555-EX | ? | Intel pGFx |
| S5557 | ? | Intel pGFx |
| S5556 | ? | ASPEED AST2500 |
| S5620 | ? | ASPEED AST2400 |
| S7002 | No <sup>2</sup> | ASPEED AST2050 | 3 | 15 | 5 |  | 5 |
| S7012 | No <sup>2</sup> | ASPEED AST2050 | 2 | 15 | 5 |  | 5 |
| S7025 | No | ASPEED AST2050 |
| S8030 | Yes | ASPEED AST2500 |
| S8036 | Yes | ASPEED AST2500 |
| S5630 | ? <sup>3</sup> | ASPEED AST2500 |
| S7100 | ? <sup>3</sup> | ASPEED AST2500 |
| S7100-EX | ? <sup>3</sup> | ASPEED AST2500 |
| S7103 | ? <sup>3</sup> | ASPEED AST2500 |
| S7106 | ? <sup>3</sup> | ASPEED AST2500 |
| S7070 | ? <sup>4</sup> | ASPEED AST2400 |
| S7076 | ? | ASPEED AST2400 |
| S7077 | ? <sup>3</sup> | ASPEED AST2400 |
| S7086 | ? | ASPEED AST2400 |
| S8020 | ? <sup>3</sup> | ASPEED AST2500 |
| S8026 | ? <sup>3</sup> | ASPEED AST2500 |
| S8030 | ? <sup>3</sup> | ASPEED AST2500 | 2 | 13 | 12 |
| S8036 | ? <sup>3</sup> | ASPEED AST2500 |
| S8253 | ? <sup>3</sup> | ASPEED AST2500 |

<sup>1</sup> No BMC chip.<br>
<sup>2</sup> Fans controlled via BIOS only.<br>
<sup>3</sup> Likely works, but not tested.<br>
<sup>4</sup> More than one SKU with this model number. Some have a BMC and some do not.<br>

## Fan Control Methods
Tyan boards support one or more of the following fan control method types:
1. Universal (all fans at once)
2. Direct (fans may be controlled individually)
3. Zoned (fans are controlled by groups called 'zones')

## Example IPMI Command Structure by Model Series
Additional details on select motherboards.

### S8030 (S80xx series)
- Supports direct (individual) manual control of fan headers
- Manual fan control must be pre-enabled in BIOS before IPMI commmands will work
- Minimum fan speeds must be set in BIOS

#### IPMI Command Structure (controlling fans)
- 3rd byte in IPMI command indicates function
  - 0xfd : set fan duty cycle (PWM %, 0-100)
  - 0xfe : get current fan duty cycle (PWM %)
  - oxff : set automatic fan mode

#### Set Fan Speed of Specified Fan Header
`ipmitool raw 0x2e 0x44 0xfd 0x19 0x00 {Fan ID} 0x01 {Duty Cycle}`

Where:
- Fan ID is an integer converted to hex, beginning with 0 (zero), and the CPU fan is fan 0.
- Fan duty cycle is within a range of 0 - 100 expressed as hexadecimal (i.e., 100% = 0x64).

For example, set fan ID 5 to 100% fan speed:

```
ipmitool raw 0x2e 0x44 0xfd 0x19 0x00 0x05 0x01 0x64
```

#### Get Current Fan Duty Cycle
Get current fan duty cycle of a given fan ID.

`ipmitool raw 0x2e 0x44 0xfe 0x19 0x00 {Fan ID} 0x01`

#### Set Automatic Fan Mode
Set automatic (BMC controlled) fan mode for a given fan ID.

`ipmitool raw 0x2e 0x44 0xff 0x19 0x00 {Fan ID} 0x01`
