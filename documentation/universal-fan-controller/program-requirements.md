# UFC Program Requirements
Universal Fan Controller (UFC) program requirements.

Related information:
- [Program Goals](program-goals.md)
- [Program Features](program-features.md)
- [Program Architecture and Design](program-design.md)
- [Program Release Notes](release-notes.md)
- [Program Roadmap](roadmap.md)
- [Supported Motherboard Manufacturers](supported-hardware-manufacturers.md)

## Software Requirements
Aside from a Linux environment and the capability to run BaSH (Bourne again SHell), the following software programs must also be installed:
- `ipmitool`: allows [IPMI](/documentation/lexicon.md#ipmi) raw commands and sensor readings
- `sensors`: facilitates hardware temperature sensor readings; also knoown as `lm-sensors`
- `smartctl`: disk S.M.A.R.T. management tool; preferred over `hddtemp`
- `hddtemp`: disk drive temp reader; back-up soluton when `smartctl` is not available

### Special Fan Category Exclusions
_'Special'_ fan categories refers to fan categories requiring special handling.

Special fans must be identified as such during the running of the Builder program. These fans need to be flagged and excluded because they do not fall within the scope of UFC's goals and intended use cases. Examples of special fans include:
- Fans dedicated to cooling power supplies.
- Fans that are part of 3rd party hardware installed in the server and attached to the motherboard, such as PCIe graphics cards.
- Fans managed via an external power modulation (PWM) controller, but which report current fan speed to the BMC (extremely rare).

## Business Rules
These business rules are important in defining UFC's behavior.

### CPU Cooling

#### 1. Above Target Temperature
When any CPU is **above its target temperature**, increase the **CPU fan speeds** and maintain them until the temperature falls to the target level.

#### 2. Below Target Temperature (Normal Operation)
When **all CPUs** are below their **target temperature**, and the **CPU fan duty** is not already set to **LOW**, reduce it to the **LOW** duty level defined for the CPU cooling profile.

#### 3. Urgent Cooling (High Threshold)
When any CPU reaches or exceeds its **high temperature threshold**, immediately increase **all fan speeds** to reduce temperature. Ignore any normal fan control settings.

#### 4. Emergency Cooling (Critical Threshold)
When any CPU reaches or exceeds its **critical temperature threshold**, immediately set **all fans** to **maximum speed**. Ignore all other settings.

#### 5. Never PID
Fans belonging to the `cpu` fan category are managed based on the relationship between pre-defined CPU temperature thresholds and corresponding CPU fan speed duty settings. CPU fan speeds must never be dictated by [P.I.D.-based controller logic](pid-explained.md).

#### 6. `$cpu_fan_group` Declaration
When fan header names or fan zone IDs are specified in the optional configuration variable `$cpu_fan_group`, the indicated fans shall always have their fan duty category assigned to CPU cooling.

#### 7. CPU Associated Fans Not in `$cpu_fan_group`
When fan header names or fan zone IDs are specified in the optional configuration variable `$cpu_fan_group`, and other fan headers are discovered which are not mentioned in `$cpu_fan_group`, but are mentioned in a fan group schema, and the fan group schema is associated with the `cpu` fan duty category, then the latter fans shall also be treated as CPU cooling fans, even though they are not explicitly mentioned in `$cpu_fan_group`.

---

### Disk Cooling

#### 1. Mean Disk Temperature at or Above Target
When the **average temperature** of all disks meets or exceeds the **target disk temperature**, increase the speed of all **disk cooling fans** to reduce it.

#### 2. Single Disk High Temperature
If any individual disk reaches its **high temperature threshold**, increase the speed of fans assigned to **disk cooling**.

#### 3. PID Controller Usage
Use a [PID controller](pid-explained.md) as the **preferred method** for determining fan speeds for **non-CPU cooling** (typically disk fans).

#### 4. Outlier Disk Temperature (PID Override)
If a **single disk** has an **unusually high temperature** (i.e., much higher than the mean), override the PID and set the **disk fan speed** to **one level higher** than the current level-up to the maximum allowed for disk cooling.

#### 5. Disk Cooling Fan Speed Limits
- The PID controller must **not exceed** the **maximum** disk fan duty level.  
- The PID controller must **not drop below** the **minimum** disk fan duty level.

#### 6. Extreme Disk Temperature (Max Override)
If a disk is **overriding** the PID logic due to high temperature and the **disk cooling fans are already at max**, then **set all fans** (regardless of type) to their **maximum speed**.

#### 7. Recovery from Emergency Disk Cooling
Once all previously overheated disks drop below their **critical temperature**, and **PID logic was previously suspended**, **reactivate PID control** to determine the next disk fan duty.

#### 8. Applying PID Recommendation
When PID is in use, set the **disk fan duty** to the **nearest integer** of the PID recommendation, but:  
- Not **below** the disk fan **minimum duty limit**  
- Not **above** the disk fan **maximum duty limit**

#### 9. PID Recommendation Below Minimum
If the PID recommends a duty below the **minimum disk fan duty**, use the **minimum**.

#### 10. PID Recommendation Above Maximum
If the PID recommends a duty above the **maximum disk fan duty**, use the **maximum**.

#### 11. `$cpu_fan_group`
When the `cpu_fan_group` variable is defined in a configuration file, any validated fan header name or fan group/zone ID mentioned in the variable declaration shall be construed as dedicated to CPU fan cooling duty, regardless of how the related fan headers may have been previously been categorized. In other words, this parameter can override other fan duty designations, if they are processed prior to `cpu_fan_group` processing.

This pertains to the Builder program only.

---

### Miscellaneous

#### 1. CPU Priority Over Other Cooling Needs
The current cooling need of any physical CPU or CPU core shall **take precedence** over the cooling needs of any non-CPU device (e.g., disk drives). If a conflict arises, **CPU cooling requirements override** all other fan control logic.

#### 2. Last Declaration Wins
When parsing configuration (.conf) files, multiple configuration files are loaded by the Builder during the setup and runtime program configuration process. When a conflict occurs where an environmental or program operating parameter was previously declared in one config file, and another config file loaded later attempts to overwrite the parameter value, unless stated otherwise, the most recently imported value shall prevail.

For example, if FANA is assigned to Fan Group 1 (Fan Zone 1) via the motherboard model config file, but when the Builder config file (populated by the end user) is imported, FANA is assigned to Fan Group 0 (Fan Zone 0), then the assignment of FANA's fan group (zone) shall be group (zone) 0. The most recent imported value shall prevail. However, when this is the case, the Builder shall warn the user in its program log, when utilized.

---

### Cooling vs. Noise Prioritization
Rules about when cooling or noise reduction take precedence.

#### 1. CPU Cooling Priority
- **CPU cooling** shall always take **precedence over disk cooling**.  
- No scenario may reduce CPU fan performance in favor of disk cooling needs.

#### 2. Cooling Over Noise
- The cooling needs of **CPUs** or **disk devices** shall always **outweigh noise reduction goals**.
- If maintaining safe temperatures requires louder fan speeds, noise minimization shall be deprioritized.

#### 3. Noise Reduction When Feasible
- When cooling is **not a priority** - i.e., CPU and disk temperatures are at or below their respective **set points (target temperatures)** - UFC shall prioritize the reduction of **fan noise** by lowering fan speeds to the **lowest reasonable duty level**, based on current CPU and disk conditions.
- When **CPU and non-CPU fan categories** (e.g., disk cooling fans) belong to **separate fan groups** and are **not jointly managed**, particular attention shall be given to **reducing noise in non-CPU fan groups**, when conditions allow.

---

### PSU Fan Operations
PSU fans are handled as a 'special' fan category.

#### **PSU Definition:**  
A "PSU" refers to either:
- A fan **embedded internally** within a Power Supply Unit (PSU), or  
- A fan that is **external to the PSU** but is **dedicated solely** to PSU cooling.

#### 1. **PSU Fan Ignorance:**  
If a PSU fan is **visible to the Universal Fan Controller (UFC)**, it shall be **explicitly ignored**, and:
- will **not be monitored** for telemetry or status.  
- will **not be assigned** to any cooling duty type.  
- will **not be controlled** by UFC logic, PID or otherwise.

#### 2. **Autonomous Operation Assumption:**  
UFC assumes PSU fans operate **autonomously** under PSU-internal logic and are **responsible for their own thermal management**.

#### 3. **No Participation in System Cooling:**  
PSU fans shall **not participate** in CPU or disk cooling strategies and shall **not influence** global fan duty decisions or overrides.

---

### 3rd Party Add-in Card Fan Rules
Rules concerning how UFC detects and handles fans associated with 3rd party add-in cards, such as PCIe expansion cards or NVMe devices.

There are two types of add-in card–related fans that may be present:
1. **Integrated Add-in Card Fans**: Fans that are embedded directly into the add-in card itself (e.g., a PCIe GPU or NVMe device with a heatsink and dedicated fan).
2. **Chassis-Based Add-in Card Cooling Fans**: Fans built into the system chassis, designed specifically to provide airflow for PCIe cards, riser modules, or blade servers.

#### 1. Default Ignorance of Add-in Card Fans
UFC shall, by default, **ignore all fans associated with 3rd party add-in cards**, regardless of whether the fan is:
- integrated directly into the add-in card (e.g., GPU or NVMe fans), or
- provided as part of the server chassis for the express purpose of cooling add-in cards.

#### 2. Conditional Support for Manufacturer-Specific Fan Categories
In certain manufacturer-specific scenarios - such as with some **Dell PowerEdge servers** - UFC may provide **explicit support** for chassis-based add-in card cooling fans, but only under the following conditions:
- The fan is required to operate at high speeds by default (e.g., full speed constantly), and  
- UFC determines that managing the fan may contribute meaningfully to its **secondary goal of fan noise reduction**, and  
- No risk is introduced to the system’s cooling stability or critical temperature management.

#### 3. Exclusion of Special Ignored Fan Categories
UFC shall **not apply special support logic** to any add-in card fan that belongs to a **known special excluded fan category**, including but not limited to:
- **Power Supply Unit (PSU) fans**, whether internal or external

---

## Default Fan Categories
The default fan categories in UFC are **CPU** and **Disk Device** (`disk`) cooling fans.

> [!NOTE]
> UFC does not natively support additional cooling fan categories _out of the box_.  
> However, it is possible due to UFC's modular design - though _[the process](/documentation/universal-fan-controller/how-to/how-add-new-fan-type.md) is not straightforward_.

---

## Fan Groups
Fans are organized by their cooling responsibility (or fan cooling duty). The responsibility of each fan header may be defined by the user or assigned automatically based on logical filtering rules.

Fans that share a common cooling duty are grouped together, based on fan group schemas. These fan group schemas can and should be defined within a configuration file. This concept is explained in more detail [here](/documentation/universal-fan-controller/how-to/how-add-new-fan-type.md#fan-groups).

1. Fans are organized into groups, which may be defined by the user in a configuration file.
2. When fan headers are discovered which are not found in a pre-defined fan group schema, UFC will attempt to deduce the fan's cooling purpose automatically.
3. Fan header names cannot exist in more than one fan group.
4. Every fan header name that exists must be mentioned in a fan group. If not, it will be treated as an [orphaned fan header].
5. Fan group labels must be unique.
6. If a fan label has no text matching any of the array index values it will be assigned a fan label type of 'unknown' and will be ignored by the fan controller and excluded from manual control.
7. Reserved fan group types consist of the following names. Fan headers assigned to fan groups with these fan labels shall be excluded.
  - exclude
  - ignore
  - psu

---

### Automatic Fan Category Assignment
Users are strongly encouraged to configure their motherboard's fans into logical groups that reflect their specific cooling needs.  
When user configuration is absent or incomplete, UFC will attempt to assign fan categories automatically.

#### 1. **User-Declared Fan Groups Take Priority**
- If a user declares a fan group in the Builder configuration, the Builder will treat the fan group as the designated type.
- UFC will **not attempt to automatically assign or alter** the fan group type specified in the Builder config.
- If an error occurs while validating the user-declared fan group or its associated headers, the Builder will **exit with an error condition** and specify the reason in the log.

#### 2. **Automatic Fan Header Grouping**
- If a fan header is detected via UFC's automatic fan header detection process and is **not included in the Builder config**, UFC will attempt to determine its appropriate fan group.
- If UFC cannot determine a valid fan group for an automatically detected header, it will **exclude the fan header** and log a corresponding note in the Builder program log.

#### 3. **What Is Not a CPU Fan, Is a Device Fan**
The terms **"disk fan"**, **"device fan"**, and **"disk device fan"** all refer to the same type of fan group:

- A fan header **not responsible for CPU cooling**.
- A fan header **not part of a special fan group**.
- A fan header responsible for cooling **disk storage devices**.

If a fan group is **not identified as a CPU cooling group**, it shall **default to a disk cooling fan group**.
