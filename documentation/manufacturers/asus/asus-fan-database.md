# Asus Model Database
Data set of manual fan speed controllable Asus server motherboards. General information on select Asus motherboards, with an emphasis on server-class motherboards with a BMC chip.

## Asus Motherboards
| Model | Manual Fan<br>Control? | BMC | # Fan<br>Zones | # Fan<br>Headers | CPU<br>Zone | System<br>Fans | Other<br>Fans |
| ----- |:----------------------:| --- |:--------------:|:----------------:|:-----------:|:--------------:|:-------------:|
| A320M Pro4 | ? |  | 2 | 1 | 2 |
| A350M Pro4 | ? |  | 2 | 1 | 2 |
| AB350M-HDV | ? |  | 3 | 1 | 2 |
| AB350M | ? |  | 3 | 1 | 2 |
| A320M-HDV | ? |  | 3 | 1 | 2 |
| A320M | ? |  | 3 | 1 | 2 |
| A320M-DGS | ? |  | 3 | 1 | 2 |
| [C422 PRO/SE](https://dlcdnets.asus.com/pub/ASUS/mb/Socket2066/WS_C422_PRO_SE/E16048_WS_C422_PRO_SE_UM_V4_WEB.pdf) | Yes <sup>1</sup> | ASPEED AST2500 | 2 | 4 | 2 | 2 |
| Fatal1ty AB350 Gaming K4 | ? |  | 2 | 4 | 1 | 3 |
| Fatal1ty AB350 Pro4 | ? |  | 2 | 4 | 1 | 3 |
| Fatal1ty X370 Gaming K4 | ? |  | 3 | 4 | 1 | 3 |
| Fatal1ty X370 Professional Gaming | ? <sup>2</sup> |  | 3 | 6 | 1 | 4 | 1 |
| KGPE-D16 | ? | ASPEED AST2500 |
| KMPP-D32 <sup>3</sup> | Yes <sup>4</sup> | ASPEED AST2600 | 2 | 10 | 2 | 8 |
| P9D-MH/SAS/10G-DUAL | ? | ASPEED AST2400 |
| PRO WS WRX80E-SAGE SE | Yes <sup>5</sup> |  | 3 | 9 | 1 | 6 | 2 |
| PRO WS WRX80E-SAGE SE WIFI | Yes <sup>5</sup> |  | 3 | 9 | 1 | 6 | 2 |
| RS700-E9-RS12V2 | ? | ASPEED AST2500 |
| X370 Killer SLI | ? |  | 2 | 4 | 1 | 3 |
| X370 Killer SLI/ac | ? |  | 4 | 1 | 3 |
| X370 Taichi | No <sup>2</sup> |
| X99-WS/IPMI | Yes <sup>5</sup> |
| Z9PA-D8 | Yes |
| [Z10PE-D8 WSK](https://dlcdnets.asus.com/pub/ASUS/mb/Socket2011-R3/Z10PE-D8_WS/Manuals/E15493_Z10PE-D8_WS_UM_V7_WEB.pdf?model=z10pe-d8%20ws) | Yes | ASPEED AST2400 | 3 | 9 |

<sup>1</sup> Workstation board, but individual fan control is supported.<br>
<sup>2</sup> Optional CPU pump fan is controllable via BIOS only.<br>
<sup>3</sup> 6-pin fan headers. Each is a single logical fan header. This means while you will have two fans physically connected to each header, each reports as and is managed as a single fan header.<br>
<sup>4</sup> This board uses the ASMB10-iKVM chip, which is similar in terms of hardware and firmware to Dell's iDRAC platform. It functions as a bridge between IPMI and the BMC chip, utilizing the AMI MegaRAC SP-X firmware framework.<br>
<sup>5</sup> Works in web based IPMI, not certain of CLI support<br>

## Add-on Server Management Cards
For motherboards that do not have a BMC chip, but for which BMC capabilities are desired, Asus has a line of add-on cards that provide this. The ASMBx product line are effectively add-in BMC modules, allowing ASPEED ASTxxxx line BMC chips to piggyback onto the board.


though their capabilities tend to be a bit restricted as compared to typical on-board BMC chips. These devices provide IPMI integration with motherboards that don't natively support it. On some boards with AMI BIOS, these devices can facilitate remote communication with the BIOS by utilizing the AMI MegaRAC SP-X firmware framework.
- [ASMB8-iKVM](https://dlcdnets.asus.com/pub/ASUS/server/accessory/ASMB8/E10970_ASMB8-iKVM_UM_V2_WEB.pdf) (2015 | ASPEED AST2400)
- ASMB9-iKVM (2020 | ASPEED AST2500)
- ASMB10-iKVM (2024 | ASPEED AST2600)

These server cards have a built-in web interface that allows numerous management functions - similar to what one would expect from a BMC interface - by establishing a private i2C channel. This includes establishing a separate IP address for the server card on the LAN (again acting like a BMC). For example, displaying current hardware temperature readings and fan speeds. The on-board BMC supports IPMI 2.0 and is accessible after the BIOS initializes and before the operating system launches, or even when the operating system crashes or there is none.

Beginning with the ASMB9-iKVM chip, the add-on management firmware is similar in terms of hardware and firmware to Dell's iDRAC platform.
Beginning with the ASMB10-iKVM chip, the [Redfish](/documentation/bmc-and-server-architecture/redfish.md) protocol is supported.

It is not clear whether or not these server cards allow manual fan control over IPMI.
