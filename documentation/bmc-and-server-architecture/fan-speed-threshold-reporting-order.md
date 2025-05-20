# Fan Speed Threshold Reporting Order
The order in which [fan speed thresholds](bmc-fan-speed-thresholds.md) are reported varies by motherboard manufacturer. Some examples are given below.

## ASRock and Supermicro
Two of the most respected server motherboard manufacturers - ASRock Rack (ASRock) and Supermicro - report fan speed thresholds in this order:
Lower: LNC | LCR | LNR
Upper: UNR | UCR | UNC

### Supermicro X9 Series Motherboards
X9 boards have artificially fixed ceilings for upper fan speed thresholds which are independent of logical limitations based on PC architecture. Input values are automatically rounded to nearest multiple of 25, and these boards have an Upper Non-Recoverable (UNR) maximum value of 19,150 RPM. Due to how the BMC rounds, any input value of 19,163 and higher will be rounded up, triggering a rollover condition (value resets at 0 and starts counting up from there, and is also rounded to nearest multiple of 25).

### Tricking BMC Upper Thresholds
On X8 and X9 series Supermicro boards (and possibly also on later generations), the BMC will automatically attempt to adjust the fan speed thresholds so that they are staggered by at least one fan hysteresis deviation between levels. However, most Supermicro boards that support all three Upper fan speed threshold settings can be tricked into setting them to the same value if desired.

> [!WARNING]
> This practice is discouraged. It is strongly recommended to have all Lower/Upper threshold values spaced apart by at least one multiple of the [fan hysteresis](bmc-fan-speed-thresholds.md#fan-hysteresis). The BMC intends / tries to do this on its own in order to scale into a panic condition. By making either Lower or Upper thresholds uniform, there is no opportunity for the BMC to alert prior to engaging its panic mode. In particular, the value of UCR should be lower than UNR as a general rule.

### Supermicro X11 Series Motherboards
Supermicro X11 boards observe a distinctly different approach to threshold variable names. These changes impact how header information in the **lm-sensors** or **ipmi** output displays read results of fan speed thresholds. Instead of following the typical UNC | UCR | etc. nomenclature, these are used instead as headers/threshold names:
- **lo-unrec** = Lower Non-Recoverable
- **lo-crit**  = Lower CRitical
- **lo-noncr** = Lower Non-CRitical
- **hi-noncr** = High Non-CRitical (versus Upper Non-Critical)
- **hi-crit**  = High CRitical (versus Upper Critical)
- **hi-unrec** = High Non-Recoverable (versus Upper Non-Recoverable)

### Supermicro X12 Series Motherboards
Supermicro also changed things up a bit with the X12 generation of motherboards. Just like the X11 boards, these changes impact how header information in the **lm-sensors** or **ipmi** output displays read results of fan speed thresholds. Instead of following the typical UNC | UCR | etc. nomenclature, these are used instead as headers/threshold names:
- Low NR (Lower Non-Recoverable)
- Low CT (Lower Non-Critical)
- High CT (Upper Critical)
- High NR (Upper Non-Recoverable)

> [!WARNING]
> The "ipmitool sensor thresh" command may not work on X12 boards (not confirmed).

## Setting Fan Speed Thresholds
To set lower thresholds using IPMI:
```
ipmitool sensor thresh "*sensor name*" lower *lnr* *lcr* *lnc*
```
Replace *sensor name*, *lnr*, *lcr* and *lnc* with the appropriate values.

> [!TIP]
> The BMC will allow you to set fan thresholds out-of-order. However, doing so is likely to cause unexpected fan behavior.

To set upper thresholds:
```
ipmitool sensor thresh {sensor name} upper *unc* *ucr* *unr*
```

Likewise, replace the placeholders *unc*, *ucr*, and *unr* with corresponding values.

### Byte Order Matters
Specifying illogical values - such as placing the threshold values out-of-order - is possible. The BMC does not perform any validation on the numbers you pass it to store for each threshold. For example, you could set `ipmitool sensor thresh {sensor name} upper 11500 11400 11300` which would be backwards of how they should have been set (presuming order is {LNC} {LCR} {LNR}). It is an illogical pattern because the non-recoverable (LNR) threshold will be reached before either of the others. It will work, but will make the LNC and LCR values irrelevant.

### Maximum Fan Speed
Maximum fan speed settings are obviously only relevant to upper fan speed thresholds, but how do you know what the fan maximum is?

There are three potential fan speed values that serve as a maximum fan speed:
1. Maximum physical fan speed
2. Maximum indicated fan speed
3. Highest value the BMC understands

Let's break down what these are and how they pertain to selecting your upper fan speed threshold values when setting them manually (such as via IPMI).
- The maximum **physical fan speed** is *the maximum speed at which a given fan is physically capable of spinning*. This means its max fan speed if the fan is powered at 100%. This *should* be the same as the fan's maximum logical fan speed, but that is not always the case.
- The maximum **indicated fan speed** is *the maximum speed at which a given fan is expected to spin*, based on the manufacturer's specifications.
- And finally, we have the highest value understood by the BMC. This is a *logical* fan speed limitation. More on this below.

### Choosing Upper Fan Speed Threshold Values
The UCR and UNR fan speed thresholds should normally be set well above the maximum observed physical fan speed for each fan. This is because otherwise, there is a possibility that during normal server operations, the fan's speed will briefly exceed the UCR or UNR limit. Passing either will cause an instantaneous reaction from the BMC, triggering all fans to full speed. Once the fans are ramped up - regardless of the original cause - they will now begin repeatedly piercing the same threshold since they've been powered up to 100% as an emergency solution deployed by the BMC. The server will be stuck with the fans on full blast until it is restarted.

At the same time, care needs to be taken to not exceed the [logical fan speed](bmc-fan-speed-thresholds.md#logical-maximum-fan-speed-limit). This issue is explained next.
