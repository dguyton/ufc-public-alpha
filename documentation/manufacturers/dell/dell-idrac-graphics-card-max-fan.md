# Dell Server Forced Max Cooling with Add-on Cards

All Dell [iDRAC](/documentation/lexicon.md#idrac) releases include logic that boosts chassis fans to maximum cooling when the iDRAC controller detects the presence of a non-Dell add-in PCIe card. Dell seems to presume these cards are likely graphics cards, and since iDRAC cannot interrogate 3rd party hardware as it can with Dell hardware, errs on the side of too much cooling is better than too little. This is understandable from Dell's perspective, as modern graphics cards to tend to put out a lot of heat. And since the majority of server motherboards place PCIe slots toward one edge of the board, it stands to reason that venting all that hot air out of the server chassis is probably a good idea.

This creates a somewhat unique, but reproducible problem for home lab users who would like to have a server that doesn't sound like a jet airplane taking off 24/7. Fortunately, there is a solution, though it is not universally supported by iDRAC firmware. It is known to work with most implementations of iDRAC 7 that support IPMI fan control commands, nearly universally with iDRAC 8 and iDRAC 9 up to and including version 3.32.32.32. Beyond that, however (iDRAC 9 3.34.34.34 and later versions), it is unlikely to work, though this author has not tested it. Whether or not the latter is true depends on how strictly iDRAC blocks communication by IPMI with the BMC, and especially with regards to the fan controller (NetFunction 0x30).

> [!CAUTION]
> Make sure to verify your version of iDRAC supports manual fan controls. Also, please be advised that iDRAC 9 in particular requires explicit pre-enablement before attempting manual fan control. See [this page](dell-idrac-fan-control.md) for more information on determining iDRAC version compatibility.

## PowerEdge Servers with Aux PCI-e Fan
Certain PowerEdge model servers have built-in auxiliary fans dedicated to cooling add-in PCIe cards. In particular, the PowerEdge **R710, R720, and T150** are known to have these aux fans. When present, managing this fan must be handled separately from the CPU and system chassis fans. It is controlled in a completely independent way by iDRAC. The normal fan controlling IPMI commands will not affect it.

When this fan exists, by default it will be activated when iDRAC detects the presence of an installed PCIe card. When that is true, "on" will be the 3rd-party fan's default state.

### Checking Status
To check the current status/setting of the 3rd-party PCI-e fan on R710/R720 boards:

`raw 0x30 0xce 0x01 0x16 0x05 0x00 0x00 0x00`

When checking status, the response data from IPMI will look like this:

#### Enabled
`16 05 00 00 00 05 00 00 00 00`

#### Disabled
`16 05 00 00 00 05 00 01 00 00`

### Enabling
To enable the 3rd-party PCI-e cooling profile:

```
ipmitool -I lanplus -H $IP -U $USER -P $PASS raw 0x30 0xce 0x00 0x16 0x05 0x00 0x00 0x00 0x05 0x00 0x00 0x00 0x00
```

### Disabling
To disable the 3rd-party PCI-e cooling profile:

```
ipmitool -I lanplus -H $IP -U $USER -P $PASS raw 0x30 0xce 0x00 0x16 0x05 0x00 0x00 0x00 0x05 0x00 0x01 0x00 0x00
```

NOTE: This setting is **not** persistent between reboots, and always defaults to "on" after system boot. In order to consistently disable it when it auto-activates, you will need to setup a script that runs after the boot sequence to shut it down.
