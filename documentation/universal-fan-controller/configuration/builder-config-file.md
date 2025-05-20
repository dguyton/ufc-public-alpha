# Builder Config Breakdown and Walk-thru
A detailed walk-through of the Builder configuration file. Much of this information is also present in the Builder configuration file itself.

## Builder Config Filename
The Builder's configuration filename must follow a specific filename format: `universal_fan_controller_v{version}.conf`

For example, if the current UFC program version is 2.0, the filename would be: `universal_fan_controller_v2.0.conf`

## Operating Variables
User-configurable parameters that impact the operating structure of the Universal Fan Controller (UFC).

### 📝 Operating Variables Cheat Sheet

| Parameter                         | Required | Default               | Description |
|-----------------------------------|----------|-----------------------|-------------|
| `program_version`                 | Yes      | (none)                | Must match across Builder, Launcher, and Runtime |
| `program_name`                    | Yes      | (none)                | Human-readable name shown in logs |
| `service_name`                    | Yes      | (none)                | Base name for `systemd` services (no spaces) |
| `fan_header_binary_length`        | No       | 16                    | Max number of trackable physical fan headers |
| `fan_zone_binary_length`          | Yes      | 8                     | Max number of logical fan zones |
| `service_username`                | No       | (blank = root)        | Username that runs the Service programs |
| `server_id`                       | No       | (none)                | Server identifier shown in alert emails |
| `target_dir`                      | No       | `/usr/local/bin/ufc`  | Destination for runtime programs and logs |
| `cpu_temp_method`                 | Yes      | `cpu`                 | Scanning mode: `cpu` or `core` |
| `cpu_temp_high`                   | Yes      | (user-defined)        | CPU temp to trigger high fan duty |
| `cpu_temp_med`                    | Yes      | (user-defined)        | CPU temp to trigger medium fan duty |
| `cpu_temp_low`                    | Yes      | (user-defined)        | CPU temp to trigger low fan duty |
| `auto_detect_cpu_high_temp`       | No       | `false`               | Auto-detect CPU high temp via `lm-sensors` |
| `auto_detect_cpu_critical_temp`   | No       | `true`                | Auto-detect critical CPU temp |
| `cpu_temp_override`               | No       | 0 / (blank)           | Manual override for critical temp threshold |
| `include_ssd`                     | No       | `false`               | Monitor SSD temps (can cause false alarms) |
| `device_temp_polling_interval`    | Yes      | (user-defined)        | Delay (seconds) between device temp checks |
| `device_polling_interval`         | No       | 3600                  | Delay (seconds) for detecting disk changes |

> [!TIP]
> Fields with no defaults must be explicitly set in the config.

### Program Name and Versioning
Parameters that impact the name and versioning of one or more of UFC's core executable programs, which are the:
1. Builder
2. Service Launcher
3. Service Runtime

#### Program Version
Required field? **Yes**

Ensure the program version matches your expectations. `$program_version` will set the tone for program version compatibility across the spectrum of files. The Builder and both Service programs (Launcher and Runtime) must have matching program version numbers. Both the Builder and Service Launcher will abort if a mis-match is detected.

```
program_version="2.0"
```

> [!TIP]
> It's OK to have an empty version number (blank). What's important is that all three programs have the same version (or lack of any).

#### Program Name
Required field? **Yes**

Human-readable name of all Builder and Service programs. Logs will mention either this description or the "Service Name" depending on the log in question. When suitable, the Program Name will be displayed instead of or in addition to the Service Name.

```
program_name="Universal Fan Controller"
```

#### Service Name
Required field? **Yes**

This is the base name for the **systemd** daemon services that will be created and that will trigger the Service Launcher and Runtime programs. Be conscientious of naming syntax. Invalid service names may cause the name provided here to be modified.

Spaces are not allowed.

```
service_name="universal-fan-controller"
```

### Binary String Lengths
In UFC parlance, "_binaries_" or "_binary strings_" are terms for tracking variables. Their usage and how they work are explained [here](/documentation/universal-fan-controller/binary-strings.md).

The length of each _binary_ string must be equal to the maximum number of fan headers or fan zones which may be _physically_ (with respect to fan headers) or _logically_ (with respect to fan zones) available. These string values should be set to **theoretical** limits and not actual limits in order to retain flexibility.

#### Fan Header Binary Length
Required field? **No** (optional)

Maximum number of physical fan headers that can be tracked by any fan header binary.

Default is 16.

```
fan_header_binary_length=16
```

#### Fan Zone Binaries Length
Required field? **Yes**

Maximum number of logical fan zones that can be tracked by any fan zone binary.

Default is 8.

```
fan_zone_binary_length=8
```

#### Service Programs Username
Required field? **No**

Username responsible for running both the Launcher and Runtime Service programs.

```
service_username=""
```

Username that will run both Service programs (Launcher and Runtime). This user must have permission rights to run **systemd** daemon services in the background.

Leave blank (empty) to invoke default setting (_root_ user). 

#### Unique Server ID
Required field? **No**

Unique name of server the fan controller is running on. Purpose is to allow end user to clearly identify which server generated any given email alert (if email alerts are active). Human-readable strings are recommended (e.g. 'Office server'). This setting is optional and may be empty. Spaces are allowed.

```
server_id="Transcoding Server"
```

#### Service Program Working Directory
Required field? **No**

Top-level destination directory for Builder to copy service (runtime) program and log files to. Pointing to root directory is discouraged, but to do so its value would be `/`

Default is `/usr/local/bin`
 
```
target_dir="/usr/local/bin/ufc"
```

---

## CPU Temperature Controls
Parameters related to CPU temperature monitoring.

### 📝 CPU Temperature Variables Cheat Sheet

| Parameter                         | Required | Default               | Description |
|-----------------------------------|----------|-----------------------|-------------|
| `cpu_temp_method`                 | Yes      | `cpu`                 | Scanning mode: `cpu` or `core` |
| `cpu_temp_high`                   | Yes      | (user-defined)        | CPU temp to trigger high fan duty |
| `cpu_temp_med`                    | Yes      | (user-defined)        | CPU temp to trigger medium fan duty |
| `cpu_temp_low`                    | Yes      | (user-defined)        | CPU temp to trigger low fan duty |
| `auto_detect_cpu_high_temp`       | No       | `false`               | Auto-detect CPU high temp via `lm-sensors` |
| `auto_detect_cpu_critical_temp`   | No       | `true`                | Auto-detect critical CPU temp |
| `cpu_temp_override`               | No       | 0 / (blank)           | Manual override for critical temp threshold |

| `include_ssd`                     | No       | `false`               | Monitor SSD temps (can cause false alarms) |
| `device_temp_polling_interval`    | Yes      | (user-defined)        | Delay (seconds) between device temp checks |
| `device_polling_interval`         | No       | 3600                  | Delay (seconds) for detecting disk changes |

> [!TIP]
> Fields with no defaults must be explicitly set in the config.

### CPU Temperature Scanning Model
Required field? **Yes**

Choices are `cpu` or `core` (default is `cpu`).

> The `lm-sensors` program is required and must be installed on the server to run in 'core' mode. Otherwise, 'cpu' mode will be adopted by default.

- `cpu` means "scan for physical cpu temperature only"
- `core` means "scan all cpu cores"
- Empty (blank) value defaults to `cpu` mode

```
cpu_temp_method=cpu
```

### CPU Threshold Temps
Required fields? **Yes**

CPU fan duty cycles are based on average reported CPU temperature, in Celsius/Centigrade.

Closely aligned with corresponding CPU fan duty cycle names (e.g., `cpu_temp_high` to `cpu_fan_duty_high`).

```
cpu_temp_high=65
cpu_temp_med=50
cpu_temp_low=40
```

#### `cpu_temp_high` (integer)
When CPU temperature exceeds this value, set CPU fan duty cycle to HIGH.

#### `cpu_temp_med` (integer)
When CPU temperature exceeds this value, set CPU fan duty cycle to MEDIUM.

#### `cpu_temp_low` (integer)
When CPU temperature exceeds this value, set CPU fan duty cycle to LOW.

### Auto-detect CPU High Temperature Threshold
Required field? **No**

Auto-detect high CPU temperature threshold. True/False flag. When `true`, UFC will attempt to discern each CPU's reported "high" temperature threshold.

```
auto_detect_cpu_high_temp=false
```

> Requires `lm-sensors` program. If this switch is true, but **lm-sensors** program is not available, then it will be ignored and `cpu_temp_override` value will be used, if specified.
> The **lm-sensors** program reports 'high' and 'critical' CPU temperature thresholds based on an internal database hardware profile for each CPU.

### Auto-detect CPU Critical Temperature Threshold
Required field? **No**

Auto-detect critical CPU temperature threshold. True/False flag. When `true`, UFC will attempt to discern each CPU's reported "critical" temperature threshold.

> Requires `lm-sensors` program. If this switch is true, but **lm-sensors** program is not available, then it will be ignored and `cpu_temp_override` value will be used, if specified.
> The **lm-sensors** program reports 'high' and 'critical' CPU temperature thresholds based on an internal database hardware profile for each CPU.

Auto-detected values will supercede `cpu_temp_override` value.

> When more than one CPU is present, auto detect will choose the lowest temperature threshold.

When this flag = `true`, if the variable `cpu_temp_override` is assigned a value in this config file, it will be validated and may be overwritten. Therefore, if you wish to specify a specific temperature value for `cpu_temp_override`, it may be wise to leave this flag set to `false`.

This decision depends on your intent (i.e., whether or not you want your manually declared value to be validated or not). For example, if you specify a value in `cpu_temp_override` that is lower than the actual critical temp value because you wish for UFC's failsafe behavior pattern to engage at a lower temperature than the actual (hardware reported) CPU critical temp, you should ensure this flag is set to `false`. Otherwise, your manual setting may be overwritten.

```
auto_detect_cpu_critical_temp=true
```

### CPU Override Temperature
Required field? **No**

CPU temperature threshold at which disk device fan duty cycle will be increased to help cool CPU. When the CPU reaches this temperature, and separate disk device cooling fans exist, if the current disk cooling fan duty level is less than maximum, it will be increased to maximum in order to help cool the CPU(s). The device fans will remain in this state until the average CPU temperature drops below the critical threshold, at which point they will revert to their prior fan duty level.

To disable, set `=0` or leave empty (blank).

> [!NOTE]
> Ignored when `auto_detect_cpu_critical_temp=true`, **unless** auto-attempt to detect critical temperature fails.

```
cpu_temp_override=72
```

---

## Disk Device Temperature Controls
Optional parameters related to disk device monitoring.

SSDs are not supported by default. For guidance on whether or not to change this and allow monitoring non-HDD disk support, see the [UFC How-to Guide](/documentation/universal-fan-controller/best-practices.md#how-to-override-default-activating-non-hdd-support).

### 📝 Disk Device Temperature Variables Cheat Sheet

| Parameter                         | Required | Default               | Description |
|-----------------------------------|----------|-----------------------|-------------|
| `include_ssd`                     | No       | `false`               | Monitor SSD temps (can cause false alarms) |
| `device_temp_polling_interval`    | Yes      | (user-defined)        | Delay (seconds) between device temp checks |
| `device_polling_interval`         | No       | 3600                  | Delay (seconds) for detecting disk changes |

> [!TIP]
> Fields with no defaults must be explicitly set in the config.

### SSD Temperature Monitoring
Required field? **No**

Include SSDs as disk devices only when true. Otherwise, they will be ignored since their temperature profiles differ from hard drives.

Recommended setting is `false` unless only SSDs are utilized as storage devices. Most SSDs have normal operating temperatures in a range that would be considered too hot for hard drives.

If your server contains both drive types, consider that optimizing your temperature settings for hard drives, while setting this flag = `true` will tend to result in elevated fan speeds since the SSDs will consistently report temperature readings higher than if they were hard drives.

```
include_ssd=false
```

### Disk Device Polling Intervals
Time delay in seconds between polling of the operating system to inquire how many disk devices exist. This allows the Runtime program to compensate for removed, failed, and hot-swapped disk devices. If a device is suddenly missing or has just been added, the Runtime program adjusts. This is important for certain calculations, such as temperature averages, which require an accurate picture of the current storage array composition.

Disk device polling interval should be a multiple of `device_temp_polling_interval`.
- Device inventory polling only runs during disk temperature check cycles. Therefore, device polling interval should be a multiple of the device temperature check delay.
- Disk devices with invalid temperature readings are excluded from average device temperature calculations.
- When disk device poll cycle is triggered, it runs prior to disk temperature poll cycle. This ensures changes in disk array are incorporated into overall device cooling management plan as soon as possible.

#### Disk Device Temperature Polling Interval
Required field? **Yes**

The time (in seconds) between disk device temperature checks. Timing for disks is normally much less critical than for CPU(s), and should be set to a value greater than cpu_temp_polling_interval.

```
device_temp_polling_interval=120
```

#### Disk Device Inventory Polling Interval
Required field? **No**

Poll the operating system to inquire how many disk devices exist.

Time delay **in seconds**, this value determines the frequency of checking for when a disk device has been added or removed from the system. This allows the program to compensate for added, removed, failed, and hot-swapped disk devices.

Set by Builder, used by Service Runtime program. 

Should be a multiple of 60 (when not empty or `0`). A minimum value of 300 (5 minutes) is recommended. For most use cases, much higher values (i.e. infrequent checks) are preferred, or set to 0 or leave empty (blank) to skip checks altogether (e.g. for systems that do not have hot swappable drives or are not expected to ever need a device list change).

If a device is suddenly missing or has just been added, the program adjusts. This is important for certain calculations (such as temperature averaging) which rely on maintaining an accurate perspective of the current storage array composition. Recommended setting is 600 (10 minutes). Value must be an integer.

> [!NOTE]
> Even when deemed unnecessary, this feature can help to identify failed drives.
>
> When a change in present disk devices is detected, an email will be sent to the user (provided email alerting options are configured appropriately).

Ignored (not checked) when = `0` or empty (blank).

When a value is provided, the minimum is `300` (5 minutes). If specified value < 300, the program will revert it to 300 seconds.

```
device_polling_interval=3600
```

---

## CPU Fan Controls
User configurable parameters that impact how UFC controls fans related to CPU cooling. These controls relate to active, constant adjustment of CPU fan speeds, and differ from the [CPU temperature](#cpu-temperature-settings) threshold settings.

### 🔧 CPU Fan Controls Cheat Sheet

| Parameter                   | Required | Description                                                                |
| Parameter                   | Required | Default        | Description |
|-----------------------------|----------|----------------|-------------|
| `cpu_fan_control`           | No       | `true`         | Enables active fan speed control for CPU cooling                          |
| `cpu_fan_duty_min`          | Yes      | (user-defined) | Absolute minimum duty cycle. Avoid too low-can trigger BMC panic          |
| `cpu_fan_duty_low`          | Yes      | (user-defined) |  "Low" fan duty level; normal floor for fan speeds                         |
| `cpu_fan_duty_med`          | Yes      | (user-defined) |  "Medium" fan speed                                                        |
| `cpu_fan_duty_high`         | Yes      | (user-defined) |  Highest fan speed under normal conditions                                 |
| `cpu_fan_duty_max`          | Yes      | (user-defined) |  Absolute max fan speed; used in CPU panic mode                            |
| `cpu_fan_duty_start`        | Yes      | (user-defined) |  Initial CPU fan duty cycle on program start                               |
| `cpu_fan_speed_min`         | No       | 0 / (blank)      | Minimum acceptable CPU fan RPM. Used for tuning alerts/failure detection   |

### CPU Fan Active Management
Required field? **No**

Should this program moderate CPU fan speeds to control cpu temperature? When `false`, UFC relinquishes CPU fan control, and the BMC (or system firmware) may resume automatic fan control if supported. When `true`, CPU fan speeds will be controlled based on CPU temperature and other parameters defined in this config file and other parameters detected automatically or defined in this config file.

```
cpu_fan_control=true
```

### CPU Fan Duty Levels
Required fields? **Yes**

Standardized CPU fan duty cycle controls (percentage of full power). Possible range is 0-100.

Closely aligned with corresponding CPU temperature thresholds (e.g., `cpu_fan_duty_high` to `cpu_temp_high`).

```
cpu_fan_duty_min=30
cpu_fan_duty_low=40
cpu_fan_duty_med=70
cpu_fan_duty_high=100
cpu_fan_duty_max=100
```

#### `cpu_fan_duty_min`

Minimum CPU fan duty cycle percentage. CPU fan duty cycle will never be allowed to fall below this level.

> [!WARNING]
> Setting minimum cpu duty cycle percentage too low will cause BMC to go into panic mode and/or may damage CPU(s).

#### `cpu_fan_duty_low`
Required fields? **Yes**

CPU low speed fan duty cycle percentage. This will normally be the lowest possible fan duty cycle of the CPU fans. While it is possible the fan speeds could go lower due to PID adjustments, under normal operating circumstances the LOW level will be the fan speed floor.

#### `cpu_fan_duty_med`
Required fields? **Yes**

CPU medium speed fan duty cycle percentage.

#### `cpu_fan_duty_high`
Required fields? **Yes**

CPU high speed fan duty cycle percentage. Highest CPU fan speed under normal conditions. Not used during panic mode.

#### `cpu_fan_duty_max`
Required fields? **Yes**

Maximum CPU speed fan duty cycle percentage. CPU fan duty cycle will never be allowed to exceed this level, regardless of current fan duty cycle variables.

When excessive CPU temperature triggers panic mode, CPU fans will be set to this level.

### CPU Fan Duty Cycle on Program Start
Required field? **Yes**

Baseline fan duty level (percentage) fans should be set to when Runtime program initializes.

When `cpu_fan_control=false` requests to set CPU fan speeds will be ignored.

> The `set_fan_duty_cycle` function is responsible for setting fan speeds and will ignore such requests for CPU fans when `cpu_fan_control` flag `!= true`

Default = 30

```
cpu_fan_duty_start=30
```

### CPU Fan Minimum Rotational Fan Speed
Required field? **No**

Optional, global minimum operating fan rotational speed of CPU fans (RPMs).

This can be useful when the server fans have a normal operating speed range that may seem particularly slow or fast. For example, it's not uncommon for an active CPU fan installed on top of or beside the CPU heatsink to run at much lower RPMs than chassis fans as part of their normal operation. On the other hand, if CPUs are cooled passively, it may be necessary to rely on chassis mounted cooling fans that are some distance from the CPU(s), and this may in turn foster a need for fast spinning fans. In the case of the latter scenario, it may be advantageous to set the minimum CPU fan speed higher as this can assist with earlier identification of weakening or failing fans.

```
cpu_fan_speed_min=450
```

---

## Disk Device Fan Controls
All temperatures are measured in Celsius/Centigrade. Targets are desired or preferred temperature state. The Service Runtime program will attempt to keep temperatures as close to the target value as possible, by manipulating fan settings and monitoring the affect of fan speed changes on actual values.

### 🔧 Disk Device Fan Controls Cheat Sheet

| Parameter                    | Required | Description                                                              |
|------------------------------|----------|--------------------------------------------------------------------------|
| `device_avg_temp_target`     | Yes      | Target avg temperature for disk devices                                 |
| `device_max_allowed_temp`    | Yes      | Max temp before all fans go to 100% and PID is suspended                |
| `device_fan_duty_min`        | Yes      | Absolute minimum fan duty for disk cooling fans                         |
| `device_fan_duty_low`        | Yes      | "Low" fan speed level. Avoid stall zone for large fans                  |
| `device_fan_duty_med`        | Yes      | "Medium" speed level for disk fans                                      |
| `device_fan_duty_high`       | Yes      | Normal high speed level; must be ≤ `device_fan_duty_max`                |
| `device_fan_duty_max`        | Yes      | Max allowed speed for disk fans                                         |
| `device_fan_duty_start`      | Yes      | Initial disk fan duty on program start (used before PID kicks in)       |

### Average Disk Device Temperature Target
Required field? **Yes**

Disk device cooling is goal-seeked; meaning the Service Runtime program will attempt to keep disk devices as close to this target temperature as possible by regulating the fans responsible for disk device cooling.

The target value represents the _average_ of all disk device temperatures.

```
device_avg_temp_target=35
```

### Max Disk Temp
Required field? **Yes**

Maximum allowed operational disk temperature.

When any disk device reaches this temperature, the PID control algorithm is abandoned and all fans are set to maximum. When the disk temperature(s) fall below this threshold, PID control is restored.

```
device_max_allowed_temp=50
```

### Disk Device Fan Duty Levels
Required fields? **Yes**

Disk device fan duty cycle controls (percentage of full power). These values are mapped to corresponding disk temperature triggers. When a given disk temperature level is reached, its corresponding fan duty cycle level is activated (e.g., 'low' temperature corresponds to 'low' fan duty level).

- Must be an **integer**.
- Must be within the range of 0-100 or 1-100.

> Some motherboards / BMC's allow the lowest setting to be 0% power/speed percentage, but many set the minimum at 1% or higher.
> 
> UFC expects integers within the range of 0-100. When a particular motherboard does not allow fan speed settings below a particular value, UFC handles this logic separately from the integer range validation (0-100).

Assigns a specific fan duty level (percentage) to each disk device fan duty threshold.

```
device_fan_duty_min=0
device_fan_duty_low=20
device_fan_duty_med=30
device_fan_duty_high=50
device_fan_duty_max=100
```

##### `device_fan_duty_max`
The maximum allowed fan duty cycle speed (percentage).

Must be equal to or greater than high fan duty level.

##### `device_fan_duty_low`
Must be greater than or equal to minimum fan duty level.

> [!CAUTION]
> Some 120mm fans stall below 30% duty cycle. Exercise caution when setting low and minimum values for large, slow fans.
>
> If a fan stalls, it stops spinning entirely despite power being applied, potentially leading to rapid thermal rise. Always test fan behavior at low power levels before finalizing values.

##### `device_fan_duty_min`
Absolute minimum allowed fan speed (percentage of full power) of fans responsible for cooling disk devices.

> [!WARNING]
> Setting minimum too low may result in accidentally triggering BMC fan panic mode.

### Starting Disk Cooling Fan Duty
Required field? **Yes**

This parameter sets the initial cooling fan duty level of fans responsible for cooling disk devices. It is applicable only on server start-up.

When the program begins, there are no PID values. PID control requires historical temperature vs. fan duty data, UFC needs a predefined initial fan speed to begin measurements. Therefore, a starting fan duty value must be pre-established for disk device cooling fans. After some time, the PID process will kick in and make adjustments to the current disk device fan duty cycle. Those adjustments will be based on the current fan duty cycle at the time. Therefore, it is necessary to manually prime the process when the Runtime program begins.

This value is ignored after the first program loop cycle.

Acceptable range is 0-100. Must be an integer.

```
device_fan_duty_start=10
```

### PID Constants
Required fields? **Yes**

| Constant | Role         | Typical Value | Notes                                 |
|----------|--------------|---------------|---------------------------------------|
| `Kp`     | Proportional | 4–6           | Controls how aggressively the fan responds to temp changes. Larger values = faster response. |
| `Ki`     | Integral     | 0             | Adjusts based on accumulated temperature error. Usually left at 0 to avoid overreaction. |
| `Kd`     | Derivative   | 10× Kp        | Dampens response by considering the rate of temperature change. Helps prevent oscillations. |

Constants that influence the PID settings. The P.I.D. algorithm and methodology is explained [here](/documentation/universal-fan-controller/pid-explained.md). These constants amplify the effect of the raw PID calculations.

> [!TIP]
> You can technically ignore this section if your server has no device cooling fans, but this practice is discouraged.

**Kp** is _proportional gain per interval (one minute)_

**Ki** amplifies the cumulative deviation of temperatures compared over time. Ki is typically left at 0 because larger values tend to exacerbate the senstivity of PID adjustments. If your application heavily favors rapid cooling response over noise mitigation, Ki may be useful. However, it is generally wiser to first experiment with it set to the default of 0.

**Kd** influences the slope of temperature delta over time calculation. It basically influences how frequently adjustments are made based on Kp and Ki.

Values may be integer or floating point (latter must be enclosed in quotes).

Set any constant to `0` in order to ignore its corresponding PID value.

### Recommended Settings
- Set Ki = 0 ; you will probably never need it
- Set Kp >= 4
	- lower for fewer drives
	- higher for more drives
- Set Kd at 10x Kp
- If Ki > 0, keep it small (e.g. 0.1 or less)

```
pid_Kp="5.3"
pid_Ki=0
pid_Kd=120
```

## Global Fan Control Adjustments
Optional flags and RPM based fan speed limiters.

### 🔧 Global Fan Controls Cheat Sheet
| Parameter                    | Required | Default | Description                                                               |
|------------------------------|----------|-------------|-----------------------------------------------------------------------|
| `fan_duty_limit`             | No       | 100         | Global fan duty ceiling (applies to CPU, disk, etc.)                  |
| `low_duty_cycle_threshold`   | No       | 25          | % of max RPM below which offset is added for RPM calc accuracy        |
| `low_duty_cycle_offset`      | No       | 10          | % offset added when below threshold; helps avoid false low-RPM alerts |
| `bmc_threshold_buffer_mode`  | No       | `loose`     | Skew upper fan thresholds towards max fan speed or max BMC capability | 
| `auto_bmc_fan_thresholds`    | No       | `true`      | Automatically set BMC lower and upper fan speed thresholds            |
| `bmc_threshold_interval`     | No       | 0 / (blank) | Lowest common denominator of fan speed understood by the BMC          |

### Maximum Fan Duty
Required field? **No**

Maximum allowed fan duty of any fan.
Global cap on fan duty cycle for all fans (CPU, disk, chassis). Overrides individual `{cooling type}_fan_duty_max` values if lower.

```
fan_duty_limit=100
```

### Low Fan Duty Cycle RPM Offsets
Required fields? **No**

Most fan speed functions in UFC are based on fan duty levels (PWM percentage). However, accurately predicting actual fan speeds (RPMs) at different duty levels is crucial for system stability. This is because fans must operate within expected speed ranges to maintain proper cooling and avoid unnecessary alerts. UFC applies an algorithm to help achieve this that estimates RPM values when fans are first inventoried. UFC periodically compares these stored values against real-time fan speeds to detect potential anomalies in fan behavior.

To fulfill this requirement, UFC employs a **linear algorithm** to estimate the expected mean RPM for specific fan duty milestones (e.g., Low fan duty, Medium fan duty, etc.). It then calculates a standard deviation around each mean to define an acceptable RPM range. This allows the system to monitor fan performance and detect potential failures before they become critical issues.

#### Challenges in Low-End RPM Accuracy
Accurately estimating fan speeds at low duty cycles is challenging due to several factors:

- **Fan Model Variability**: Different fan models within the same server may respond differently to the same power input, leading to inconsistent RPM readings.
- **CPU Fan Constraints**: CPU fans must not stop completely, as this could cause overheating. To mitigate this, their maximum fan speed is used as a reference for estimating rotational speed ranges.
- **Reliance on Maximum Fan Speed**: The algorithm uses a fan’s maximum RPM as a baseline, making it difficult to accurately predict lower speeds.
- **Unknown Stall Thresholds**: Each fan has a stall point-the minimum power needed to keep it spinning-which UFC cannot directly account for.

These factors often cause the algorithm to **underestimate** fan RPMs at very low duty cycles, leading to unnecessary alerts. To address this, UFC allows users to apply an automatic offset to artificially raise the lower threshold for fan speed ranges, which is the subject of this section.

#### Adjusting Expected Fan Speed
To improve accuracy, UFC provides two user-adjustable variables that modify low-end fan speed calculations:

| Variable                    | Function                                                                                             |
| --------------------------- | ---------------------------------------------------------------------------------------------------- |
| `low_duty_cycle_threshold` | Defines the minimum percentage of maximum fan speed used to calculate the absolute lowest fan speed. |
| `low_duty_cycle_offset`    | Adds a positive offset to the calculated fan duty when it falls below `$low_duty_cycle_threshold`.   |

When UFC converts a fan duty percentage (PWM %) to an RPM value, if the duty percentage is below `low_duty_cycle_threshold`, the input is increased by `low_duty_cycle_offset` before the calculation runs.

**Example Calculation:**
1. `low_duty_cycle_threshold=20`
2. `low_duty_cycle_offset=10`
3. Given an input fan duty of 15
4. Since 15% is below the threshold of 20%, UFC applies the offset: **15 + 10 = 25%**
5. The adjusted duty cycle of 25% is then used for RPM calculations.

This prevents low fan duty values from being interpreted as unrealistically low RPMs, preventing false alerts.

#### Default Behavior (Recommended)
Most users will not need to adjust these settings. The default values are:

- **Minimum fan duty**: 25%
- **Offset when below threshold**: 10%

For example, if an input fan duty of 20% is below the 25% threshold, the algorithm increases it to 30% (20 + 10) before calculating RPM. If the fan’s maximum speed is 8,000 RPM, this results in a minimum expected speed of 2,400 RPM (30% of 8,000).

#### Disabling the Low-End Adjustment (Not Recommended)
Users can deactivate this adjustment by setting both `low_duty_cycle_threshold` and `low_duty_cycle_offset` to `1`. However, this is **strongly discouraged**, as it may cause unrealistic low-speed calculations, leading to excessive false alerts.

> [!WARNING]
> Disabling this adjustment can cause UFC to set unrealistic alert levels, leading to frequent false alerts. For example, an 8,000 RPM fan could theoretically have a minimum fan speed as low as 80 RPM if the lowest fan duty cycle is set to 1%. This is far below any realistic operational range for such a fan. To avoid this, set `low_duty_cycle_threshold` no lower than 10, with 15-25 recommended.
> 
> Modify these settings only if you have a deep understanding of the server’s fan behavior and find the default values do not provide accurate results for your specific hardware.
> 
> Setting fan speed thresholds too low can still lead to unnecessary alerts, especially at low or medium duty levels.

### Upper BMC Fan Speed Threshold Method
Required field? **No**

Specify how wide the safety margin is between the observed upper fan speeds of any fan, versus the maximum fan speed the BMC is capable of processing. This only applies when automatic BMC fan threshold detection is active (i.e. when auto_bmc_fan_threshold=true) and determines whether upper BMC fan speed limits are moved as high as possible to avoid false positive triggering of BMC induced panic mode, or if a more conservative approach is preferred where the upper BMC fan speed thresholds are set close to the known highest fan speed, which leaves less room for anomalies and makes it more likely a fan could trigger upper BMC fan speed thresholds and potentially trigger BMC fan panic mode, in the event something causes any fan to spin at higher RPMs than expected.

There are two (2) possible settings:
1. strict = sets BMC upper fan speed thresholds at a narrow margin above known max fan speeds
2. loose = highest speed any existing fan is capable of attaining under normal operating conditions

> loose = sets BMC upper fan speed thresholds to their absolute maximum, which is normally much higher than the fans are capable of ever attaining

When not specified, default value = `loose`

```
bmc_threshold_buffer_mode="loose"
```

### Automatic Fan Hysteresis Detection
Required field? **No**

When `=true`, automatically sets BMC lower and upper fan speed thresholds based on validated fan speed ranges.

This takes the guesswork out of a process most people find confusing. When `true`, the Builder will calculate sensible boundaries for upper and lower fan speed thresholds, based on confirmed maximum fan speeds and best-guess effort of estimating sensible lower fan speed thresholds.

The lower fan speed thresholds have some margin of error due to the fact the CPU lower boundaries must be estimated versus measured. They are not measured with accuracy because doing so could potentially cause damage to the CPUs. The setup program contains an algorithm used to make a good estimate of the real-world lower thresholds, and is designed to set them at a point where normal low speed fan operations will not trigger a BMC false alert and send the BMC into panic mode due to low RPM alerts.

Final values are padded and distributed across the lower/upper ranges.

By default, this automatic setting will take the highest detected fan speed and pad it based on a multiple of the fan speed interval, and will use that calculated figure as the fan speed ceiling, which will in turn be used to establish upper BMC fan threshold limits that will be hard-coded into the BMC (will survive cold reboots).

Should generally be set `=true` especially when not declaring fan speed thresholds below. When `true`, fan hysteresis and BMC fan speed thresholds will be set automatically. Upper limits will be established based on whether `bmc_threshold_buffer_mode` is set to `loose` or `strict` mode.

```
auto_bmc_fan_thresholds=true
```

### Multiple of BMC Fan Hysteresis
Required field? **No**

The `bmc_threshold_interval` variable stores the RPM interval by which the motherboard's BMC fan threshold speed settings may be set. The BMC only allows setting RPM thresholds to a multiple of the fan hysteresis value, and therefore `bmc_threshold_interval` is typically equal to the fan hysteresis. However, it does not have to be, though it must be a multiple of the fan hysteresis, and must be an integer.

#### What is the 'fan hysteresis'?
Every BMC has a minimum sized increment between fan speed RPM settings. The BMC will round the actual (raw) fan speed to a multiple of the given increment. These increment values vary based on the BMC chip manufacturer and model, just as the ceiling and floor of fan thresholds vary by BMC.

If this value is not provided or set `=0`, UFC will automatically attempt to detect the fan hysteresis interval and set this variable accordingly.

```
bmc_threshold_interval=75
```

#### Best Practice
Unless the end user is certain of the motherboard's fan hysteresis value, this variable should be left empty and UFC should be allowed to query the board and determine the fan hysteresis automatically.

> [!WARNING]
> If the fan hysteresis is unknown and cannot be detected, the Builder will abort as this information is required to properly configure fan speed thresholds, which the Builder will hard-code in the BMC.

## Fan Category Definitions and Mapping
Configurable data types related to fan headers.

### Possible Fan Duty Categories
Required field? **Yes**

List of valid fan duty categories, stored in an indexed array.

This list defines the universe of possible fan duty categories of fan [binary string](/documentation/universal-fan-controller/binary-strings.md) types. Numerous functions in UFC are correlated to this list. If at any point you wish to add a new fan duty category, the first step is to add a corresponding entry to this array.

The default list is shown below:

```
fan_duty_category[1]="cpu"
fan_duty_category[2]="device"
fan_duty_category[3]="exclude"
```

> [!IMPORTANT]
> Do not alter the fan duty categories unless you are confident in what you are doing.
>
> New fan categories may be added, but when doing so be sure to thoroughly bug-check the entire UFC ecosystem as there are many 'hooks' in the core programs and sub-routines (functions) that rely on consistent fan category usage.
>
> It is critical to align the relationships between
> - fan duty categories (categories),
> - Fan group labels; and
> - Fan schemas
>
> Guidance on the steps required to incorporate additional fan categories into the Universal Fan Controller taking all of this and more into consideration may be found in the guide on [How To Add New fan categories](/documentation/universal-fan-controller/how-to/how-add-new-fan-type.md).

### Fan Group Labels
Required field? **Yes**

Map fan header name prefixes to fan duty category. This is how to inform UFC how you want it to handle each fan header. This section maps fan group labels assigned in motherboard configuration files to their corresponding fan category. The fan category determines how the fan headers in the associated group label are treated by UFC.

For example, you might define a fan group label called 'psu' to represent all PSU (Power Supply Unit) fan headers UFC detects via **lm-sensors**. Since PSU fans should not be (and often cannot be) manually adjusted, mapping them group to the `psu` fan category ensures UFC will ignore them during fan control operations.

> [!TIP]
> This can sound a bit confusing at first, but it is actually relatively straightforward in practice.
>
> Think of it in two stages:
>
> Motherboard config: Map each physical fan header to a group label.
> Builder config: Map each group label to a fan category (e.g., cpu, device, psu, etc.).
>
> This two-stage mapping tells UFC which role each fan serves and how it should be controlled.

Array correlating words that may be found in fan header names and/or fan group/fan zone schema labels. The index of the array consists of names, words, or partial words which may appear as a whole or part fan name or fan group schema label name. The value of each array element is the type of cooling duty associated with the fan name or fan group label.

UFC's stock build and configuration and allows three possible values, shown below. It is possible to add support for additional fan group categories, as discussed [above](#possible-fan-duty-categories).
1. cpu
2. device
3. exclude

`psu` is a special label type. It means 'Power Supply Unit' and is shorthand for a fan that is part of a power supply or specially designated to cooling a power supply device. _PSU has a special, distinctive connotation_.

> [!WARNING]
> **Never attempt to control PSU fans manually.**
>
> Power supply fans are regulated by internal temperature circuits. Manual overrides can interfere with critical cooling functions and may damage the PSU.
>
> Label these fans with type `psu` to ensure UFC ignores them.

They should always be controlled automatically via temperature control circuits embedded in the power supply device. Even if it is possible to control it manually, doing so should never be attempted in order to avoid potentially damaging the power supply unit. Assigning a 'psu' value to a given fan name to be filtered will result in any fan or fan group schema label containing that term being excluded by the fan controller from attempts to control that fan or group of fans.

If a fan label has no text matching any of the array index values it will be assigned a fan label type of 'unknown' and ignored by the fan controller and excluded from manual control.

```
fan_group_category[cpu]="cpu"
fan_group_category[device]="device"
fan_group_category[disc]="device"
fan_group_category[disk]="device"
fan_group_category[drive]="device"
fan_group_category[exhaust]="device"
fan_group_category[fan]="device"
fan_group_category[fr]="device"
fan_group_category[front]="device"
fan_group_category[graphics]="exclude"
fan_group_category[hdd]="device"
fan_group_category[ignore]="exclude"
fan_group_category[intake]="device"
fan_group_category[psu]="exclude"
fan_group_category[rear]="device"
fan_group_category[side]="device"
fan_group_category[ssd]="device"
fan_group_category[sys]="device"
fan_group_category[vent]="device"
```

---

## Program Log File Settings
These parameters control which types of log files UFC will generate (if any), debug mode (verbosity), _syslog_ usage, and log interval management.

| Setting | Description	| Builder | Launcher | Runtime |
| ------- | ----------- |:-------:|:--------:|:-------:|
| `log_to_syslog` | Mirrors critical errors to system log	| ✅ | ✅ | ✅ |
| `debug` | debug verbosity | ✅ | ✅ | ✅ |
| `service_log_dir` | Top-level log directory |  | ✅ | ✅ |
| `log_age_max` | Sets max retention (in days) for program logs |  | ✅ | ✅ |
| `log_hourly_interval` | Interval before rotating log files |  |  | ✅ |
| `log_hourly_alignment` | Aligns log rotation to top of hour |  |  | ✅ |

### _syslog_ (system log) Preference
Required field? **No**

Mirrors critical UFC messages to the system log.

- `true` = mirror messages to syslog (default)
- Any non-true value disables this behavior

```
log_to_syslog=true
```

### Debug Mode
Required field? **No**

Applies to Builder, Launcher, and Runtime. Controls the verbosity of logs for all programs.

```
debug=2
```

When = `debug=0` or empty (blank), all program and JSON debugging is disabled.
- Defaults to level 0 (none)
- Levels 1/2/3/4 gradually increases verbosity (4 = most verbose)

| Debug Level | Description                                        |
|:-----------:| -------------------------------------------------- |
| 0           | No debugging messages                              |
| 1           | Critical messages only                             |
| 2           | Critical + Warning messages                        |
| 3           | Critical + Warning + Important messages            |
| 4           | All messages (Most verbose)                        |

### Service Log File Parent Directory
Required field? **Maybe**

Defines the main log directory used by both the Launcher and Runtime programs. If not set, defaults to `/log/` under the top-level Service programs target directory. If a path is invalid or cannot be created, defaults are used or logging is disabled.

- This is the top-level (or parent level) log directory. The Builder will create sub-directories for each Service program logging type requested if logging is enabled.
- If a Service program determines a logging location is invalid, it will disable logging.
- If a location is specified but does not exist, the Service program will attempt to create it. If that fails, the default location will be attempted. If that fails, logging parameters will be ignored.

If no Service program or metadata logging is requested via related parameters in the Builder configuration file, the Service log directory (even if specified here) will be ignored.

```
service_log_dir="/var/log/"
```

### Maximum Log File Age
Required field? **No**

Specifies maximum number of days to retain Launcher and Runtime log files. When not specified, they are retained indefinitely.

```
log_age_max=15
```

### Program Log Reset Interval
Required field? **No**

Specifies how long the Runtime writes to a log file before starting a new one. Prevents logs from growing too large.
- Expressed in hours
- Default: 12
- No upper limit

```
log_hourly_interval=24
```

### Aligning Log Start Times to Hour
Required field? **No**

```
log_hourly_alignment=true
```

Aligns both program and JSON log file rotation to the top of the hour (based on server time).
- Default: `false`
- When `true`, hourly alignment follows the system (server) local time clock
- Nuanced behavior depending on log type:
  - Runtime logs: The first log starts immediately upon launch. Future logs will align with the hourly interval.
  - JSON logs: The first JSON file will not be created until the start of the next hour (even if `log_hourly_alignment=true`).

> [!NOTE]
> First Runtime log file starts immediately upon launch; future logs follow aligned interval.
>
> For JSON logs, the first file will not be created until the start of the next hour.

## JSON Log File Settings
Verbose system metadata recorded in JSON format, stored as independent log files that are separate from the program logs.

### JSON Metadata
Required field? **No**

Enable optional JSON formatted metadata logs when = true. Impacts Service runtime program behavior only.

These files contain more detailed metrics than the program log, and provide a verbose record of system status. The corresponding JSON files are saved in sub-directory /json under $log_dir directory.

```
log_json_export=true
```

### JSON Log File Age
Required field? **No**

Time interval between when JSON log files are created, in seconds.

Default is 600 (10 minutes).

```
log_json_interval=600
```

> [!NOTE]
> When `log_hourly_alignment=true` JSON logs will be aligned with the top of the hour.
>
> This also means the first JSON log will not be created until the beginning of the next hour. This is contrary to how Runtime program logs are handled.

### Maximum JSON Log File Age
Required field? **No**

Maximum age (number of days) which JSON metadata log files will be retained.

When not specified, they are retained forever.

```
log_json_age_max=31
```

---

## Email Alerts
Configuration parameters related to email.

### Email Settings
Email alerts in UFC are optional. They can be triggered by the following circumstances:
1. Service program failure (Launcher or Runtime).
2. Runtime service program initializes successfully (i.e., on server start-up).
3. UFC deems a fan has gone bad and removes it from service.
4. Disk device added, failed, or removed from service.

The primary purpose is to notify user when the Runtime program starts successfully after server boot-up. This allows a notification method to the user, so that the user knows the fan controller is working. Likewise, if a program failure occurs, as long as both the email criteria are setup correctly and the Failure Notification Handler (FNH) daemon is enabled and active, the user will receive an email with a crash report.

| Setting             | Description                                                    | Example                                    |
|---------------------|----------------------------------------------------------------|--------------------------------------------|
| `email_alerts`       | Enable or disable email alerts. Set `true` to activate.     | `email_alerts=true`                        |
| `email`              | Valid email address to receive alerts. Leave empty to disable alerts. | `email="your_email_address@some_domain.com"` |

#### Prerequisites for Email Alerts
For email alerts to work, the following must be in place:
1. Email alerts set to `true`
2. **sendmail** program installed.
3. Valid email address provided in this config file.

> [!IMPORTANT]
> In most Linux distros, you _must_ have **Postfix** pre-installed on your system. The runtime program uses the legacy version of **sendmail**, which is part of Postfix.
>
> The setup program will check for the presence of both **Postfix** and **sendmail**. If either program is missing, the email settings in the config file will be automatically disqualified. You may still configure these variables, but without Postfix and sendmail, email alerts will not work. If you're unsure whether Postfix is installed, you should verify or manually install it.

### Send Email Alerts
Required field? **No**

Set equal to `true` if you want to receive email alerts. Set equal to `false` or leave the value empty if you do not want to receive email alerts.

When `true`, send certain status updates to end user for certain events, such as at script startup and during certain critical events.

```
email_alerts=true
```

### Email Address
Required field? **No**

A valid email address to which email alerts will be sent.

Leave empty if you do not wish to send email alerts. Leaving either the **email_alerts** value or the **email** value empty will prevent email alerts from triggering.

```
email="your_email_address@some_domain.com"
```

> [!NOTE]
> UFC does not validate email addresses.

---

## Runtime Program Timers
Timers control the frequency of certain actions, prevent excessive and unnecessary processing. There are a number of tasks the Service Runtime program needs to perform periodically, but not constantly on every cycle of its main processing loop.

| Setting                  | Description                                               | Example                                      |
|--------------------------|-----------------------------------------------------------|----------------------------------------------|
| `fan_speed_delay`         | Delay (in seconds) between fan speed checks               | `fan_speed_delay=10`                         |
| `fan_validation_delay`    | Delay (in seconds) between fan header validation cycles   | `fan_validation_delay=21600`                 |
| `cpu_temp_polling_interval`| Time interval (in seconds) between CPU temperature polls  | `cpu_temp_polling_interval=10`               |

- **Fan validation**: CPU and device fans are validated on separate intervals but are influenced by the same base delay.

### Fan Speed Change Delay
Required field? **Yes**

Delay in seconds between fan speed checks. Must be an integer.

Delay in seconds between when a fan speed change command is sent, and when the change is confirmed by re-reading current fan speed. As it takes the fans a few seconds to change speeds, a grace period is prudent before verifying fan speeds have in fact changed. This value is applied as a buffer for various validation checks involving fan speed changes. The purpose is to confirm manual fan speed commands are working as expected.

```
fan_speed_delay=10
```

### Fan Validation Timer
Required field? **Yes**

Base delay (in seconds) between fan header operational check validation cycles (e.g. 3600 = 1 hour; 21600 = 6 hours; 43200 = 12 hours).

Must be an integer.

This timer controls the frequency of the active fan header validation cycles, which include the following tests:
- Analyzing known active fan headers to ensure fans attached to them are continuing to operate within expected parameters.
- If a fan appears suspicious, it is flagged for further scrutiny and follow-up analysis.
- Re-checking fans previously tagged as suspicious.

When a fan previously identified as 'good' repeatedly fails inspection, it is removed from the pool of active fans. See [Suspicous Fans](/documentation/universal-fan-controller/suspicious-fans.md) for more information on this topic.

CPU and disk device (case) fans are monitored via separate scanning cycles. Due to the higher risk of hardware damage from CPU fan failures, this split helps to ensure potential fan failures of a more critical nature are addressed with greater urgency.

> [!NOTE]
> Base delay period sets the frequency for fan validation checks of all fan categories. While CPU fan checks occur first, other fan checks (e.g. device) follow the same cycle interval.
>
> time in seconds (3600 = 1 hour; 21600 = 6 hours; 43200 = 12 hours)

```
fan_validation_delay=21600
```

### CPU Temperature Polling Interval
Required field? **Yes**

Time interval **in seconds** between CPU temperature poll cycles (both physical and/or core temps). Must be an integer.

```
cpu_temp_polling_interval=10
```

---

## _systemd_ Configuration
Parameters related to **systemd** daemon services.

### systemd Services Parent Directory
Required field? **No**

**systemd** service folder. Default is `/etc/systemd/system`

This is the directory where the UFC Builder will copy and configure **systemd** .service files, which includes the following:
- Service Launcher daemon service
- Service Runtime daemon service
- [Failure Notification Handler](/documentation/universal-fan-controller/fnh.md) daemon service

```
daemon_service_dir_default="/etc/systemd/system" # default path used by UFC Builder
```

### _sysctl_ Delay
Required field? **No**

Delay in seconds between multiplexed **sysctl** commands for _systemd_ events. 

If not specified, the Builder uses a default value of 2 seconds.

```
daemon_init_delay=5
```

### Enable Failure Notification Handler
Required field? **No**

The [Failure Notification Handler](/documentation/universal-fan-controller/fnh.md) (FNH) service is automated to send notifications to the designated end user when a failure of any Service program occurs.

When set to `true`, the FNH daemon service is enabled. When set to `false`, the service is disabled.

See [here](/documentation/universal-fan-controller/best-practices.md#2-the-failure-notification-handler-daemon) for guidance deciding whether or not to use the Failure Notification Handler.

```
enable_failure_notification_service=true
```

### Alternate Service Program Daemon Service Names
Required field? **No**

- Optional override for daemon service names (no spaces allowed).
- If left empty (default), Builder will automatically assign default names.

```
launcher_daemon_service_name_default="" # Leave empty to use Builder default
runtime_daemon_service_name_default="" # Leave empty to use Builder default
failure_handler_service_name_default="" # Leave empty to use Builder default
```
