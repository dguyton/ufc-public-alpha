# Sensor Monitoring
**ipmitool** and **lm-sensors** are two tools utilized by the Universal Fan Controller (UFC) to monitor CPU temperatures, disk device temperatures, cooling fan states, and current fan speeds. The output from these tools has a consistent order, lending itself to parsing. 

UFC has been tested with Debian-based operating systems (particularly Ubuntu). However, since it is possible a version of these tools could be slightly different on another operating system, UFC's configuration allows for manual adjustments if the default column settings are not correct for a given implementation. Another possible variance is which metadata is reported. UFC tries to collect the full set of sensor data as it expects it to be reported. However, some motherboards do not report this in its entirety and use an abbreviated data set. For example, instead of six data points for fan speed thresholds, a given board might only report four of them. 

The default columns in UFC conform to the standard used by Supermicro, ASRock, and Tyan motherboards, which are also followed by most other manufacturers and are effectively an informal industry standard. When metadata columns are missing information, that sensor type or threshold is ignored.

For additional information, see these resources:
- [BMC Fan Speed Thresholds](/documentation/bmc-and-server-architecture/bmc-fan-speed-thresholds.md)
- [Server Environment Sensors](/documentation/sensors.md)

## Fan Sensors
Fan sensors report basic current information about each fan, such as:
- Fan name
- Rotational speed in RPM
- Fan state (e.g. normal, ok, no signal, etc.)
