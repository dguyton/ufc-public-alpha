# Bibliography (References) - Motherboard or Server Manufacturer
References by motherboard manufacturer or server manufacturer.

## ASRock
- https://forums.unraid.net/topic/38108-plugin-ipmi-for-unraid-61/page/54/?tab=comments
- https://forums.servethehome.com/index.php?threads/asrock-rack-bmc-fan-control.26941
- https://www.asrockrack.com/support/faq.asp?id=41
- https://www.asrockrack.com/support/faq.asp?k=fan
- https://www.asrockrack.com/support/IPMI.pdf

#### ASRock fan duty commands
- https://www.asrockrack.com/support/faq.asp?id=63

#### ASRock BMC Schemas
- https://forums.servethehome.com/index.php?threads/asrock-rack-bmc-fan-control.26941/post-353763
- https://github.com/lethargynavigator/ast2500-fan-control/blob/master/fancontrol.py

#### Dummy Byte Input
ASRock 6x4-pin fans with dummy bytes at end of 8-byte string, no override bytes:
- https://git.deck.sh/shark/asrock-pwm-ipmi

#### ASRock ASPEED AST2400 BMC
Most of these boards have limited (if any) manual fan control support:
- https://www.asrockrack.com/support/faq.cn.asp?id=38

## Dell / EMC
#### PowerEdge Servers
- https://www.reddit.com/r/homelab/comments/t9pa13/dell_poweredge_fan_control_with_ipmitool<br>
- https://www.reddit.com/r/homelab/comments/7xqb11/dell_fan_noise_control_silence_your_poweredge<br>
- https://forums.unraid.net/topic/37560-fan-speed-control-trouble-on-asrock-e3c226d2i/page/2/#comment-516157

#### Enabling/Disabling 3rd party PCIe card fan on Dell PowerEdge gen-13 servers
- https://www.dell.com/support/kbdoc/en-ca/000135682/how-to-disable-the-third-party-pcie-card-default-cooling-response-on-poweredge-13g-servers

## Gigabyte
#### GIGABYTE Server Management (GSM) Fan Speed Mapping
How to input the three temperature triggers for each fan:
- https://www.reddit.com/r/homelab/comments/mxmmkx/gigabyte_wrx80su8ipmi_ipmi_fancontrol/

## Intel
- https://www.intel.com/content/dam/www/public/us/en/documents/guides/bios-bmc-technical-guide-v2-1.pdf
- https://www.intel.com/content/dam/support/us/en/documents/motherboards/server/sb/g37830002_servermanagementguide_r3_1.pdf

## Quanta
- http://www.staroceans.org/e-book/S2B%20IPMI%20Commands.pdf

## Supermicro
#### Supermicro reference for ASPEED AST versions
- https://www.supermicro.com/en/solutions/management-software/bmc-resources

#### Nuvoton WPCM450 / Winbond WPCM450 Boards
- Some gen X8 and X9

#### X13 Boards
- https://github.com/petersulyok/smfc/issues/33

## Tyan
- https://ftp1.tyan.com/pub/doc/S7012_UG_v1.1_06212012.pdf
