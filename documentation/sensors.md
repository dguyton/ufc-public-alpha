# Server Environment Sensors
Three types of sensory data impact fan speed controls and fan noise in a server:
1.	CPU temperatures
2.	Peripheral device temperatures
3.	Fan rotational speeds

Monitoring and managing these sensor inputs is critical to maintaining a well-functioning server ecosystem. Sensor inputs have a profound impact on managing fan speeds, even when fan cooling is manually controlled.

## Sensory Input Tools
Temperature and fan speed sensor information may be gathered via a variety of tools, depending mostly on which operating system is in use. Within the context of Linux server environments, a few stand out as both versatile and commonly available. The following tools are examined in this article:
1.	sensors (lm-sensors)
2.	The IPMI 'sensor' command
3.	hddtemp

## CPU Temperature Monitoring
CPU temperatures may be monitored via numerous methods, including the `sensors` program or IPMI utilities such as `ipmitool`. These tools gather various CPU hardware temperature information and display it as columns of text.
- Physical CPU temperature (the entire CPU)
- CPU core temperature (a single physical core)
- CPU high temperature limit
- CPU critical temperature limit

### Why use **sensors** instead of IPMI?
Given **ipmitool**'s versatility, why not leverage it for as much as possible? In Ubuntu, **sensors** is significantly faster than ipmitool at temperature polling. Both allow polling CPU temperatures by physical CPU or querying each active logical core per physical CPU.
- sensors run in CPU polling mode is ~10x faster than IPMI CPU temp query
- sensors run in CPU mode is ~7.5x faster than sensors run in core mode
- sensors run in core mode is ~25% faster than IPMI (note that IPMI can query physical CPU temperatures only)

## Monitoring Disk Device Temperatures
As with CPU temperature monitoring, numerous tools are available for this task. Two of those in Ubuntu are `smartctl` and `hddtemp`. Both programs are capable of reporting current disk device temperatures. In spite of its name, **hddtemp** is versatile enough to work with any device that reports itself as a disk-based peripheral (e.g., HDDs, SSDs, NVMe drives, etc.).

## Monitoring Cooling Fans
The [Intelligent Platform Management Interface](ipmi.md) (IPMI) has two modes of reporting sensor data: `sensor` and `sdr`. They more or less report the same information, but gather it in slightly different ways. Processing `sdr` commands tends to be quicker.

The following real-time fan information may be gleaned via this method:
- Fan name
- Current fan speed in RPM
- Current fan state
- Fan hysteresis
- Lower Non-Critical threshold fan speed setting (LNC)
- Lower Critical threshold fan speed setting (LCR)
- Lower Non-Recoverable threshold fan speed setting (LNR)
- Upper Non-Critical threshold fan speed setting (UNC)
- Upper Critical threshold fan speed setting (UCR)
- Upper Non-Recoverable threshold fan speed setting (UNR)

## Gathering Sensor Readings
The server's environmental sensors are read-only. Regardless of the chosen monitoring tool, the same information is available. The question is how to parse it. The answer varies depending on the tool used to read the data.

Either way, it is critical to understand the nuances of how any given reporting tool treats verious conditions. For example, one tool may report a fan header with no fan attached as, "no signal" while another may report the same condition as, "n/s" and yet another may report it as "n/a" or perhaps even no data at all (null). Therefore it is important to fully understand the behavior of any tool chosent to rely on for this type of information, as parsing and interpreting its results correctly is imperative.
