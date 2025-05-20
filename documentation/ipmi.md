# What is IPMI?
IPMI (Intelligent Platform Management Interface) is a hardware-based, out-of-band system for remote server management and monitoring. It allows system administrators to remotely monitor and control servers independently of any operating system. It bypasses the CPU and BIOS, and works even when the server is powered off.

"Out-of-band" in this context means IPMI has a separate, dedicated network communication channel directly to the server over a network connection. This connection can travel along or be physically independent of the main (i.e. local) network. In other words, IPMI connections can be made across a LAN (Local Access Network) or use a dedicated network connection that only handles out-of-band connections such as IPMI. In both cases, some sort of network device and cabling are required, such as CAT5/CAT6/etc., DAC, or fiber. The most common physical IPMI interface is standard network cable, making it very versatile.

"Out-of-band" connections are particularly adept at troubleshooting unresponsive servers and monitoring certain hardware functions as they bypass all of the traditional paths of accessing the server's hardware.

From the standpoint of server cooling fan monitorng and control, IPMI is ideal due to its ability to bypass any restrictions at the operating level or imposed by the BIOS. That said, it still requires cooperation from the [Baseboard Management Controller](/bmc-and-server-architecture/bmc.md) (BMC) in order to control the fans. This means the following conditions must be true:

1. The server supports IPMI
2. The BMC chip supports IPMI
3. The version of IPMI in use by the user is supported
4. The BMC allows IPMI commands from the user

## Implementation
- if by local --> ipmitool raw 0x3a 0x06 0x01 0x00
- if by win OS local --> ipmitool -I ms raw 0x3a 0x06 0x01 0x00
- if by remote --> ipmitool -H -U admin -P admin raw 0x3a 0x06 0x01 0x00
