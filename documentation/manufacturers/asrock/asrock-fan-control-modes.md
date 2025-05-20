# ASRock Rack Motherboard BIOS Fan Modes
Most ASRock Rack motherboards have several fan control modes (or profiles) in the BIOS. These modes control the board's fan behavior on startup in order to ensure that the fans are spinning at some level before the operating system engages. The BIOS takes control of the fans in order to protect and preserve the server. This process is discussed in greater depth in [Who's In Control?](/documentation/bmc-and-server-architecture/whos-in-control.md).

These are the most common (default) ASRock Rack motherboard BIOS fan control modes. Not all will be available on every motherboard. They are sometimes referred to as “profiles” or “fan profiles.” The terminology used doesn’t matter (mode or profile). They perform the same function.
1.	Silent : keeps fan speeds as low as possible, at the expense of higher ambient CPU temperatures
2.	Standard : attempts to strike a balance between ambient noise, fan speed, and CPU temperatures
3.	Performance : opposite of Silent mode; noisiest of the fan modes, but provides the most aggressive CPU cooling

There is always one mode that will be run by default unless the setting has been previously changed in the BIOS. The fan last fan mode is retained in the limited non-volatile memory of the BIOS chip, which allows persistence between server reboots. Generally speaking, the default mode set from the factory will be either the Standard or Performance mode.

If you ever reset a motherboard’s CMOS (such as when replacing its battery), the server will revert to whichever mode is the default for its particular motherboard.
