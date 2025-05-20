# UFC Program Charter (Goals)

The Universal Fan Controller (UFC) is a **project related to the intelligent management of cooling fans in computer servers**. While the target audience is the Home (network) Laboratory enthusiast group, there is ample potential for other user types to benefit from it as well, such as system administrators.

UFC's **primary purpose is to minimize the background acoustics from computer server cooling fans, while simultaneously providing active thermal management** to the server's ecosystem. This is accomplished through intelligent fan monitoring and active, graduated fan speed adjustments of cooling fans directly connected to a server motherboard. The typical example is a rack-mount chassis with server-grade components and multiple cooling fans installed inside the chassis. Historically, these devices have a tendency to be very loud. Inside a data center this is not a concern, however this tends to be a detractor for their use in a Home Lab environment.

## UFC Project Primary Goals
1. Limit noise produced by cooling fans as much as possible, while protecting hardware components.
2. Protect hardware components from over-heating, with a bias toward protecting CPUs, then disk devices.
3. Support multiple motherboard manufacturers.
4. Fire-and-Forget (starts automatically on server boot-up).
5. No human interaction (runs in the background).

Further information and technical details may be found [here](program-design.md).

<<>>

IPMI only

Redfish not supported

## Redfish
While popular with professional sysadmins, [Redfish](/documentation/bmc-and-server-architecture/redfish.md) has limited usefulness in Home Labs, and its presence may complicate matters for such users. As IPMI is more ubiquitous, it was selected as the protocol of choice for UFC. For now, Redfish falls outside the scope of UFC's mission. If you wish to use the Redfish API instead of IPMI, this series of guides will not help you, as it is geared towards IPMI usage only.
