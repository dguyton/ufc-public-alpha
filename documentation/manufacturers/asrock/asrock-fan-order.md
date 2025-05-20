# Mapping Fan Header IDs Correctly in IPMI (ASRock)
How do you know what the order is of the fan headers is, for an IPMI raw write command, with an ASRock Rack motherboard?

ASRock server motherboards almost always use what I refer to as the 'group' method of fan control via IPMI. This means that in order to set the fan speed of any fan, you must send an IPMI command that encompasses ALL fan headers (the entire group). There's no way to only pick out one of them or isolate the others so their command bytes are ignored. It's an all-or-nothing affair.

Therefore, unless you're planning to always set all the fans to the same speed with every fan speed change, this presents a formidable problem. Of course, you could use trial-and-error to figure it out. And that might be what you have to do ultimately. However, there is somewhat of a method to the madness, so even if you are going to run some manual tests, it's possible to start out with a good idea of what ought to work or be very close to your board's design.

## Default Design
Generally speaking, the order in which IPMI commands are applied to fan headers on ASRock boards is based on the position of the header on the board and how many CPUs there are.

The default ordering methodology presumes there is only one CPU. If your board has more than one, skip down to the [Dual CPUs](#dual-cpus) section.

1. CPU fan is first. The first fan header will have a name denoting the first CPU cooler, such as "CPU1" or "CPU_FAN1" or something similar.
2. Next, orient the motherboard toward you such that the engraved board name is upright/legible.
3. Start with the fan header(s) toward the *bottom left* corner of the board. You want to find the lowest position fan header in that corner or near it. This will be your first fan header ID after the CPU fan header. In other words, in your IPMI command, the first data payload byte will be the CPU cooling fan. And this fan header you are focused on currently, will be the second data payload byte.
4. Moving your eyes *from left to right*, identify any other fan headers on the same horizontal pane (or nearly) as the fan header you started with. Add those fan header names to your IPMI data payload in the order you discover them. These will be your 3rd data byte, etc. If there are none, that's ok and proceed to the next step.
5. Move *upward* along the board to the next fan header you see. Imagine there is an invisible horizontal plane on the board at the level of this fan header.
5. Moving from *from left to right* along the imaginary horizontal plane, add any fan headers you see - in order - to the data payload sequence.
6. Continue moving from the *bottom to the top* of the board, *left to right*, as described in steps 5 and 6 above. Repeat steps 5 and 6 until you have assigned a placeholder in the IPMI payload to all fan headers you physically see on the board.

You should now have identified the default order for write commands via IPMI to all of your fan headers. Double check to be sure the number of bytes you've identified for the data payload equals the number of physical fan headers on the board. At this point it does not matter if the fan headers are 4-pin or 6-pin.

Don't forget the [final step](#final-step), below.

## Exceptions
The following boards are known partial exceptions to these rules. Namely, the handling of their CPU fans differs from the norm.
- EP2C606-4L/D16
- EP2C602-4L/D16
- EP2C602/D16
- EP2C606-4L
- EP2C602-4L
- EP2C602

### Exception/Anomaly Descriptions
The board models mentioned above may have one or more of the following unusual features:
- CPU_FAN1_2	non-addressable 3-pin header
- CPU_FAN2_2	non-addressable 3-pin header
- CPU_FAN1_2 = 3-pin so cannot address in ipmi command, but is labeled on mobo
- CPU_FAN2_2 = 3-pin so cannot address in ipmi command, but is labeled on mobo

## When All Fan Headers are 6-pin
When you have a board with only has 6-pin fan headers, there may be a single fan header marked with some type of "CPU" designation in its name. 

### Single CPU
It may be difficult to determine which fan header pair manages cooling the CPU. There are several possible permutations of how the CPU is cooled via the fan headers.
1. A pair of fans - likely chassis fans - cool a passively cooled CPU. The fan header should be labeled as CPU_FAN_1 and CPU_FAN_2 or something similar.
2. A single traditional CPU fan. In the case the 6-pin fan header it belongs to should be treating both branches of the 6-pin wiring as supporting two independent 4-pin fans. The CPU fan will be one of these, and may be represented as something like, "FAN1" or "SYS_FAN_1" or possibly a more obvious name, such as "CPU_FAN."

Remember that when it comes to writing/setting/sending a command to the CPU fan headers, there will be only one write address in the IPMI command. This command will set fan speeds for both fans attached to the same fan header to the same fan duty level, simultaneously.

### Dual CPUs
Does the board have two CPU slots? When the board is a dual CPU slotted board, one of the six-pin fan headers is nearly always dedicated to both CPU fans. The corresponding fan header pair should be labeled as something like CPU_FAN_1 and CPU_FAN_2, or CPU_1 and CPU_2, etc. Remember that when it comes to writing/setting/sending a command to the CPU fan headers, there will be only one write address in the IPMI command. This command will set fan speeds for both fans attached to the same fan header to the same fan duty level, simultaneously.

## When Some or All Fan Headers are 4-pin
When you have a board with only 4-pin fan headers or a mixture of 4-pin and 6-pin fan headers, 

Read over the [All Fan Headers are 6-pin](#when-all-fan-headers-are-6-pin) section above. Does that narrative apply to your board even though it also contains 4-pin fan headers? If so, then that information should guide you. If not, you will need to first determine whether or not there appear to be one or more dedicated 4-pin fan headers responsible for CPU cooling. This may be obvious, or it may require some detective work. If it is not obvious and the fan names are all something generic such as, "FAN1" or "SYS_FAN2" etc., and absent any other indicator, presume the CPU fan is the first chronological fan name in the series.

## No 'CPU' Named Fan Headers
When there are no obvious "CPU" fan headers, and there is only one CPU, presume the CPU fan is the first chronological fan name in the series. If there are two CPUs, determining the proper order becomes more complicated. If the BMC supports a data payload of at least 16 bytes, and/or there is only one IPMI command line issued to control all of the fans, then the presumption should be that the first two fan header names correlate to the two CPU cooling fans. If the BMC is older and less sophisticated, then start from a position of presuming that if the data payload has to be split into more than one IPMI command, then the CPU fans are likely the first fan header of each independent IPMI command.

## Final Step
The final step in determining your IPMI fan header data payload order is to add the dummy/reserved bytes at the end of the IPMI command as necessary. If you identified less than 16 physical fan headers, then you may need to pad your IPMI data payload with dummy/reserve bytes.

## Double-Check Your Command Line(s)
The final IPMI command line will vary depending on which BMC chip your motherboard has, and can vary to some extent based on particular model. The latter is especially true when a board is an early adopter of a newer BMC as ASRock was transitioning (e.g. from AST2400 to AST2500).

### Boards with ASPEED AST2500, AST2600, or Later BMC
must have a total of 16 data bytes.

### Boards with ASPEED AST2400 BMC
might need 16 bytes
might need 8 bytes

### Earlier BMC Versions (e.g. AST2300, AST2350)
might need 8 bytes
might not matter
