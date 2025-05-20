# Temperature Polling
The most important function of UFC's Runtime program is the regular polling of CPU and disk device temperatures, as this process drives all of its fan management logic.

### CPU vs. Disk Temperature Polling Behavior
The following table outlines key behavioral differences between how UFC monitors CPU and disk temperatures.

| Feature                        | CPU Monitoring                           | Disk Monitoring                                 |
|-------------------------------|-----------------------------------|--------------------------------------------------|
| Polling Priority              | Highest                           | Lower (can be deferred)                          |
| Polling Frequency             | More frequent                     | Less frequent, variable                          |
| Tools Used                    | `sensors` (preferred), `ipmitool` | SMART data via `smartctl` (preferred), `hddtemp` |
| Response Speed                | Fast and immediate                | Smoothed and time-factored                       |
| PID Influence                 | N/A                               | Weighted and time-adaptive                       |
| Fan Control Method            | Linear                            | Curved (PID controller)                          |
| Mean vs. Individual Check     | Either (depends on sampling mode) | Mean temp; hottest disk can override             |
| Outlier Handling              | N/A                               | Highest temp disk can override PID behavior      |

## Sensor Types
There are several different types of temperature sensors. Some are integrated into the motherboard. Others are embedded inside the hardware components themselves.

When fans are controlled automatically (i.e., manual control is disabled for one or more fan headers), it is common for the BMC or especially the BIOS to rely on a wider selection of temperature sensors that may impact fan management. 

Examples of common temperature sensor types include:
- Embedded inside hardware
  - CPU (internal)
  - Storage devices (internal)
  - Embedded in third-party add-in cards (e.g., graphics card built-in temp sensors)
- Sensors built-in to the motherboard
  - RAM (Random Access Memory)
  - PCIe bus (PCI Express add-in card slots)
- Chassis (ambient air temperature measurements inside the server chassis or case)

While others may exist, these represent the most commonly encountered type.

## UFC's Focus on Sensors
The Universal Fan Controller (UFC) monitors these type of temperature sensors:
1. CPU physical (die)
2. CPU cores
3. Disk devices (e.g., Hard Disk Drives - HDDs; or Solid State Drives - SSDs)

All of these sensors are _internal_, meaning the device itself includes a built-in thermometer and reports its readings directly to the operating system through standard interfaces.

## Sensor Polling and Tool Compatibility
**ipmitool** and **lm-sensors** are two tools utilized by the Universal Fan Controller (UFC) to monitor CPU temperatures, disk temperatures, cooling fan states, and current fan speeds. The output from these tools has a consistent order, lending itself to parsing. 

UFC has been tested with Debian-based operating systems (particularly Ubuntu). However, since it is possible a version of these tools could be slightly different on another operating system, UFC's configuration allows for manual adjustments if the default column settings are not correct for a given implementation. Another possible variance is which metadata is reported. 

UFC attempts to collect the full set of expected sensor and threshold metadata from each tool it uses. However, some motherboards do not report this in its entirety and use an abbreviated data set. For example, instead of six data points for fan speed thresholds, a given board might only report four of them. 

The default columns in UFC conform to the standard used by Supermicro, ASRock, and Tyan motherboards, which are also followed by most other manufacturers and are effectively an informal industry standard. When metadata columns are missing information, that sensor type or threshold is ignored.

For additional information, see these resources:
- [BMC Fan Speed Thresholds](/documentation/bmc-and-server-architecture/bmc-fan-speed-thresholds.md)
- [Server Environment Sensors](/documentation/sensors.md)

## CPU Temperature Monitoring
CPU temperatures may be monitored via numerous methods, including the `sensors` program or IPMI utilities such as `ipmitool`. These tools gather various CPU hardware temperature information and display it as columns of text.
- Physical CPU temperature (the entire CPU)
- CPU core temperature (a single physical core)
- CPU high temperature limit
- CPU critical temperature limit

### How UFC Monitors CPU Temps
UFC may use either the **sensors** application (preferred) or [IPMI](/documentation/lexicon.md#ipmi) to monitor CPU temperatures.

Given **ipmitool**'s versatility, why not leverage it for as much as possible? In Ubuntu, **sensors** is significantly faster than ipmitool at temperature polling. Both allow polling CPU temperatures by physical CPU or querying each active logical core per physical CPU. Since UFC was originally written for headless Ubuntu servers, some portions of the code are optimized for it. This is one such instance.
- sensors (physical CPU mode): ~10x faster than IPMI
- sensors (core mode): ~25% faster than IPMI (note IPMI only polls physical CPU temps)
- sensors (core mode): ~7.5x faster than `sensors` run in physical CPU mode

> [!TIP]
> Details on how to configure UFC's temperature monitoring capabilities may be found in the [Builder Configuration](sensor-monitoring) guide.

## Disk Device Temperature Monitoring
UFC's disk temperature polling logic applies several techniques to smooth out temporary disruptions to data collection metrics that can occur based on the timing of device presence, and to ensure changes to the disk array are incorporated into the overall device cooling management plan as soon as possible.

1. disk polling cycles are run only during disk temperature checks. Ideally, the disk polling cycle timer should be a multiple of `$device_temp_check_delay`
2. Any disk with invalid temperature readings is excluded from the average temperature calculation to prevent anomalies from skewing results.
3. This prevents sudden spikes caused by temporary data collection errors, such as may occur due to sensor reading hiccups or when a device has been removed, but the list of devices hasn't been polled yet.
4. UFC performs a device discovery scan before beginning a temperature polling cycle.
  - Helps to ensure all existing disks are being measured, even if a new disk was just recently added (such as a hot swap drive).
  - If a new drive addition is very recent - such that the sensor readings cannot yet poll the drive - the new drive is considered invalid (not tracked yet) until it begins reporting valid temperatures.
5. If `$device_polling_interval` is _less than or equal to_ `$device_temp_check_delay`, or NULL, the disk polling cycle will be run during every disk device temperature poll. For most use cases, this is unnecessary and significantly prolongs the temperature polling process. Under normal circumstances, `$device_polling_interval` should be a multiple of `$device_temp_check_delay`. Setting it too low increases CPU load and delays responses to other sensor types.

For detailed information on device cooling fan controls, see the these reference documents:
- [Builder Configuration guide](sensor-monitoring.md)
- [P.I.D. Explained](pid-explained.md)

## Time Factoring
_Time factoring_ is a practice of analyzing a trend or pattern over time. UFC utilizes time factoring for monitoring temperature sensors, smoothing fan response, validation checks, and adjusting frequency curves of various actions.

UFC heavily relies on time-based trend analysis to moderate its behavior, particularly related to fan control.

### CPU Checks Take Priority
CPU and disk health are polled at different intervals. Polling intervals are skewed toward a faster response rate for CPUs, and CPU health always takes priority over disk health.

How quickly UFC responds to changes in mean temperature depends on system load and use case. One of UFC's [business rules](program-requirements.md#business-rules) states that it is more important to respond quickly to CPU temperature spikes than disk temperature spikes. This edict can cause UFC to delay disk temperature checks under some circumstances, because it is possible for rapid CPU temperatures to short-circuit the disk temperature check cycle. This is a program feature, not a bug. CPUs always receive greater attention and higher priority.

The latter reasoning is four-fold:
1. Many disk temp spikes are brief unless caused by an intensive drive activity lasting more than a few seconds.
2. Disks are unlikely to suffer ill effects from temperature spikes unless they are prolonged.
3. Moderating high disk temperatures requires more cooling effort than moderating a high CPU temperature, presuming the CPUs are cooled by dedicated fans.
4. When chassis fans are only used to cool disks, many users prefer not having them spin up and down constantly, finding such experiences annoying as they tend to be loud.

### PID Influence on Disk Cooling Fan Duty
CPU temperature polling is linear. It always takes precedence over other sensor types and is never delayed. Disk temperature sensor checks on the other hand, can be spread out as hinted at above in the discussion on [time factoring](#time-factoring).

For example, when the mean of all disk temperatures is significantly higher than the target temperature (set point), the case (disk cooling) fan speeds are ramped up, and the time interval to wait until the next disk temperature check increases dramatically. Likewise, the opposite is also true. When mean disk temperature is significantly lower than the target set point, the time until the next disk temperature poll is reduced significantly.

This process is weighted by the [PID controller logic](pid-explained.md) built-in to UFC. While this may seem counter-intuitive at first, consider the benefits of this design:
- This logic presumes if disks are in a state of higher temperature, moving more air across them for a longer period of time is likely necessary to bring the mean disk temperature down closer to the target temperature (set point).
- This methodology has the effect of smoothing out the fan duty cycle changes, so that the server is not constantly ramping the fans up and down rapidly (which would be the case if the time between temperature polling and fan adjustments was shortened).

This approach can be thought of as deliberately overshooting cooling when disk temps exceed the target, then tightening polling intervals as temps normalize.”

When the next disk drive temp reading occurs, if the mean temp has stabilized, and let's say overshot the target temp and is now quite a bit below the target temperature, the next average disk temp reading will occur much sooner.

This will in turn have the effect of being more likely to catch another spike up in drive temps, which may allow the script to ramp the drives up sooner, and at a lower (quieter) fan duty cycle. By forcing more rapid case fan (disk cooling) temperature polling when the current mean temperature is closer to the target temp, the script is more likely to catch temp increases sooner, when the amount of fan force necessary to bring the case temps back down to their desired mean is easier and the fans can be run at a slower and quieter level, versus if the temperature spike is detected later, at which point the case fans will need to be ramped up to a significantly higher speed, in turn creating more noise and using more energy.

In short, the fan logic favors early intervention at lower speeds rather than delayed response at higher noise levels.

### Highest Disk Temperature Override
The mean of all disk temperatures is the main input to the UFC's PID control logic, which drives UFC's disk fan control decisions. However, there is another measurement that can override the PID controller: ambient temperature of the hottest disk.

Under some circumstances, one disk will report a temperature considerably outside the mean temperature of all disks. UFC watches for these outliers, and if they occur they will impact UFC's behavior temporarily until the variance corrects. When this occurs, UFC will override the PID setting and increase disk cooling fan speeds until the hottest disk cools off a bit. The purpose is to prevent any single disk with sustained temperature control issues from being ignored due to the smoothing effect of the mean disk temperature calculation.

This condition is most likely to occur when one or more of the following circumstances are true:
- Many disks in the array
- Uneven disk cooling pattern due to chassis design
- Inadequate number of disk cooling fans

This override protects against PID smoothing that might otherwise ignore disks with critical thermal conditions.
