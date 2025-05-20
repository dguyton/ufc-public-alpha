# BMC Fan Speed Thresholds Explained
BMC ([Baseboard Management Controller](bmc.md)) fan speed thresholds are pre-defined RPM (Revolutions Per Minute) values that determine one manner in which the BMC controls and monitors fan speeds in a server.

These thresholds serve several purposes:
- Ensure proper cooling: By maintaining fan speeds within acceptable ranges, the BMC helps prevent overheating of system components.
- Detect fan failures: If a fan's speed is too low or too high, it may indicate a failure or impending failure.
- Trigger alerts: When fan speeds exceed or fall below certain thresholds, the BMC can generate warnings or alerts for system administrators.

There are a few variations on the names of BMC fan speed thresholds, though they all capture the same type of information. Let's dive into what information is monitored, and then how it may be presented slightly differently by motherboard and/or BMC manufacturers.

## Threshold Naming Convention
There are six common fan speed threshold levels, organized into two groups.
- Lower Fan Speed Thresholds
  - **LNC**: Lower Non-Critical
  - **LCR**: Lower Critical
  - **LNR**: Lower Non-Recoverable
- Upper Fan Speed Thresholds
  - **UNR**: Upper Non-Recoverable
  - **UCR**: Upper CRitical
  - **UNC**: Upper Non-Critical

These are standard threshold levels supported by every mainstream BMC chip. However, it is possible for system manufacturers to tweak their use in the customizable portion of the BMC firmware. As a result, not every motherboard utilizes all six, though most do. Some motherboards forgeo one pair of thresholds and only utilize four instead of six. When this is the case, the most frequently removed are the non-critical thresholds (LNC and UNC), as they are informational only and do not impact server behavior.

> [!NOTE]
> Though rare, some server manufacturers program the BMC to use slightly different names and abbreviations, such as adding the word "Threshold" to the end of a fan speed threshold. For example, "Lower Non-Critical" or "LNC" may be shown as "LNCT" which stands for, "Lower Non-Critical Threshold."

These threshold values are stored independently for each fan header. Even if there is a mix of fans with different characteristics in a server, each fan may have its own set of lower and upper critical fan speed thresholds. This is useful as it prevents the system from panicking when one fan is slower or faster than others when this may be a normal operating condition for the given fan.

### Lower Critical Fan Speed Thresholds
There are three LOWER fan speed thresholds stored in the BMC for each fan header. These values indicate a fan's speed is too slow, and appears to be operating out-of-bounds of the fan's normal operating speed range in RPMs. When a given fan falls below one of these values, it triggers an alert in the BMC. Depending on which alert threshold is violated, the BMC may decide the system is in danger and it is necessary to override the current fan speed programming and push all fans in all fan zones to maximum speed in order to protect the system hardware from potential heat-related damage. This may be thought of as an "emergency mode" or "fan panic mode" of the BMC.

#### Lower Non-Recoverable (LNR)
The _Lower Non-Recoverable_ or **LNR** value is the lowest of the lower speed thresholds. When a fan's speed reaches this speed or lower, it is considered _non-recoverable_, meaning the fan has failed. If the given fan's speed breaches this level, the BMC will enter into panic mode.

#### Lower CRitical (LCR)
The _Lower CRitical_ or **LCR** value is the middle of the lower speed thresholds. When a fan's speed reaches this speed or lower, it is considered _critical_, meaning for some reason the fan has slowed to the point of endangering the system, and the fan may be failing. If the given fan's speed breaches this level, the BMC will enter into panic mode.

#### Lower Non-Critical (LNC)
The _Lower Non-Critical_ or **LNC** value is the highest of the lower speed thresholds. When a fan's speed reaches this speed or lower, it is considered _at risk, but not yet critical_, meaning for some reason the fan is exhibiting unusually slow speed behavior, but not quite to the point of potentially endangering the system. If the given fan's speed breaches this level, the BMC's panic mode will _not_ be triggered.

### Upper Critical Fan Speed Thresholds
There are three UPPER fan speed thresholds stored in the BMC for each fan header. These values indicate a fan's speed is too fast, and appears to be operating out-of-bounds of the fan's normal operating speed range in RPMs. When a given fan rises above one of these values, it triggers alerting software in the BMC. Depending on which alert threshold is violated, the BMC may decide the system is in danger and it is necessary to override the current fan speed programming and push all fans in all fan zones to maximum speed, in order to protect the system hardware from potential heat-related damage. This may be thought of as an "emergency mode" or "fan panic mode" of the BMC.

This may seem counter-intuitive. Why would the BMC attempt to push all fans to their highest duty level if one ore more fans are spinning too quickly? The BMC views fans in one of two states: active or inactive. With regards to _active_ fan headers, the BMC sees each fan header as either operating within an acceptable range, or not. The "acceptable range" from the perspective of the BMC is any speed between the lower critical (LCR) and upper critical (UCR) values. As soon as any fan crosses either line, the BMC considers the fan to have failed, and takes evasive action to protect the system.

#### Upper Non-Critical (UNC)
The _Upper Non-Critical_ or **UNC** value is the lowest of the higher speed thresholds. When a fan's speed exceeds this speed or higher, it is considered _at risk, but not yet critical_, meaning for some reason the fan is exhibiting unusually fast speed behavior, but not quite to the point of potentially endangering the system. If the given fan's speed breaches this level, the BMC's panic mode will _not_ be triggered.

#### Upper CRitical (UCR)
The _Upper CRitical_ or **UCR** value is the middle of the upper speed thresholds. When a fan's speed exceeds this speed or higher, it is considered _critical_, meaning for some reason the fan speed has increased to the point of endangering the system, and the fan may be failing. If the given fan's speed breaches this level, the BMC will enter into panic mode.

#### Upper Non-Recoverable (UNR)
The _Upper Non-Recoverable_ or **UNR** value is the lowest of the lower speed thresholds. When a fan's speed exceeds this speed or higher, it is considered _non-recoverable_, meaning the fan is spinning out of control and has presumably failed. If the given fan's speed breaches this level, the BMC will enter into panic mode.

### Threshold Meanings
What do these threshold names mean?
- **Lower Non-Critical (LNC)**: A speed slightly above the LCR, which may trigger a warning but not an immediate action.
- **Lower CRitical (LCR)**: The minimum RPM at which a fan can operate safely. If the fan speed drops below this value, it triggers an alert and an emergency response.
- **Lower Non-Recoverable (LNR)**: The minimum RPM at which a fan has completely failed and cannot be recovered. Triggers an emergency response.

- **Upper Non-Citical (UNC)**: A speed above which the fan may be considered to be running faster than expected, but not critically so.
- **Upper CRitical (UCR)**: The maximum RPM at which a fan can operate safely. If the fan speed goes above this value, it triggers an alert and an emergency response.
- **Upper Non-Recoverable (UNR)**: Beyond this maximum RPM, a fan is considered to have completely failed and cannot be recovered. Triggers an emergency response.

### "Critical" vs. "Non-Recoverable" Thresholds
At first glance, it may seem redundant to include both a "Critical" and a "Non-Recoverable" threshold for either the lower or upper stage thresholds. Exactly how are they distinguished? Is there truly a need for both? If so, why?

This is a topic of some debate within the community of system designers, and this is why you will find not all servers support all six (6) thresholds. Some BMC implementations exclude the LNR and UNR values, or the LCR and UCR. The columns may still print when the BMC thresholds are polled, but they do not report any information. The logic here is that there isn't really any point in having both the LCR and LNR, and the their counter-parties the UCR and UNR. After all, transgressing any of them typically results in the same behavior from the BMC: an alert is reported and all server fans are instantly ramped up to 100% speed.

The difference between the two is subtle, but there is a nuance between their behaviors. The difference lies in whether or not after a reaction by the server upon hitting a trigger, can the server recover and go back to its normal/prior operating mode when it comes to fan control? When a CRitical trigger level is breached, normally the BMC will force all fans to full power in order to compensate for the issue with any particular fan. However, if the errant fan's condition pivots back to a normal operating (fan speed) range, then the condition has resolved and the BMC reverts the fans back to their prior speeds. The Non-Recoverable threshold behavior on the other hand is permanent until the server is restarted. Namely, the fan speed is considered to be so far outside the norm that even if it appears to recover back to a normal operating (fan speed) range, the BMC will not let up on forcing all fans to full speed. So, even if the errant condition corrects itself, the fans don't back down from full force. At least not until the server is restarted.

When it comes to system design and whether or not both LCR/UCR and LNR/UNR thresholds are implemented, the matter is simply whether or not a system designer chooses to utilize both behaviors and use all six thresholds, or consolidate the behavior of the critical triggers such that only four triggers are employed. To re-cap, below is a breakdown of the possible server reactions based on this decision.

#### Effects of Enabling LNR, UNR, LCR, and UCR (Default)
This is the default state. All four reactive triggers are active.

#### Effects of Enabling LCR + UCR, but Not LNR + UNR
Lower and Upper CRitical thresholds are active, but Lower Non-Recoverable and Upper Non-Recoverable are not. This means if a fan violating one of the Critical thresholds recovers, the BMC will let go of controlling the fan speeds.

#### Effects of Enabling LNR + UNR, but Not LCR + UCR
Lower and Upper CRitical thresholds are not active, but the Lower Non-Recoverable and Upper Non-Recoverable are. This means if a fan violating one of the Critical thresholds recovers, the BMC will ignore that fact and continue forcing all fans to 100% power, until such time that the BMC is reset (i.e., on server restart).

## How the BMC Reports Fan Speeds
Most BMCs use a 16-bit register for each fan header. Some older models only have an 8-bit register, which makes granular fan speed tracking impossible. Knowing which you are dealing with may or may not be important. It depends on your overall strategy in planning and setting fan speed thresholds, which is discussed in detail a bit deeper into this document, below.

> See the sections [Maximum Fan Speed](#maximum-fan-speed) and [Fan Hysteresis](#fan-hysteresis) if you want to look ahead.

The BMC tracks each fan's current tachometer value independently, based on pulse signals reported by the [Fan Controller](whos-in-control#the-fan-controller.md). The BMC converts the signal it receives from the fan controller to a 16-bit signed integer. The calculated value is within the range of 0 - 32767. This value is reported for each fan header. Negative values are presumed to be an error, and are not reported (instead you'll some other data such as, "n/a" or the filed in the table may just be empty). 8-bit BMCs use a slightly different method that is more generalized, but the end result is the same in terms of reported fan speed (you may read ahead on this topic - see [Hysteresis as a Scaling Factor](#Hysteresis as a Scaling Factor) - if you are so inclined).

So, the first point to note here is that regarding the *logical* maximum fan speed limit for any given fan header, itis 32,767. However, it gets more complicated from here, and most of the time if you enter a value of 32767 in your IPMI command, it will get altered before being stored in the BMC. This is another scenario that can lead to unexpected fan threshold behavior due to how the BMC processes the input and stores it. This process is explained below.

Every fan has a maximum physical fan speed and a maximum logical fan speed. Physical fan speed maximum is obviously determined by the fan hardware itself, and it will always be less than the logical fan speed limit, which is a function of the BMC. Specifically, it is a function of the BMC’s data storage process, and what level of significance it is capable of storing.

The vast majority of BMC chips are limited to 16-bit numbers. This includes one of those bits reserved for the sign of the number (positive or negative). Thus, for the purpose of fan speed reporting or setting, it is limited to 15-bits, which works out to a range of 0 – 32767. As you can see, this is a much higher number than any system fan is capable of spinning.

### Negative Numbers
The sign bit is not used when tracking fan speed and is not affected by the BMC's logic that handles RPM calculations. Those numbers are always positive. However, the sign bit is still used in edge cases. It is treated as a status flag, which can be triggered by other processes responsible for monitoring for signs of fan failure. If an anomaly is detected, for some circumstances the sign bit gets set (to negative), and this in turn signals downstream processes within the BMC that there may be something wrong with the fan. This process will eventually trigger whatever the protocols in the BMC are for handling suspicious fans, but at a minimum it will cause the fan status to be polled as a sub-optimal status (i.e., not OK / not normal).

## Threshold Values are User Configurable
These thresholds can often be customized by system administrators to better suit specific hardware configurations or cooling requirements. Adjusting these thresholds can help optimize system performance and reduce unnecessary noise or power consumption.

## Threshold Values are Persistent
A somewhat unique characteristic of the BMC's fan threshold settings is they are persistent across server reboots, meaning their values are stored in non-volatile memory and retained between system restarts. Thus, contrary to most fan controls - such as setting current fan speed duties through IPMI - establishing these thresholds can be a single shot, "fire and forget" process.

## Logical Maximum Fan Speed Limit
As mentioned above, there is such a thing as the maximum *logical* fan speed. This refers to the highest value the BMC is capable of reporting as a current fan's speed.

> [!NOTE]
> The logical maximum fan speed is a single value that applies to all fan headers.
> 
> Its value does not change, and is not influenced by fan characteristics.

Here is where things get a bit tricky, especially for upper thresholds. When a new fan speed threshold value is stored, if the value is greater than the BMC's logical maximum fan speed, the BMC will rollover the counter. Meaning, it will subtract the maximum value from the value provided, minus one.
- Most BMCs use a signed 16-bit integer to store each fan header's calculated current fan speed.
- This equates to a range of positive numbers from 0 - 32767, as we must allow a value of 0 as a possible legitimate value.

This is easier to visualize with an example. If you were to enter a command such as:

```
ipmitool sensor thresh {sensor name} upper 32000 32500 33000
```

The result is the last value (33000) would be converted to 233 (33000 - 32767 = 233), making the command above equivalent to entering:

```
ipmitool sensor thresh {sensor name} upper 32000 32500 233
```

However, as you'll see below, this still isn't the exact value that will be stored as it will be massaged even further by the BMC.

## How the BMC Calculates Fan Speed in RPM
Now, we get into the nitty-gritty of how to determine the maximum logical fan speed your BMC is capable of handling. Above, we explored how very large input values will rollover when the integer size exceeds the capacity of the BMC's register value limit for any given fan header (i.e. input is > 32767). But, there is yet another important factor that determines the value actually stored in the BMC: the _Fan Hysteresis_.

There are several reasons why this topic is very important:
1. It will serve as a guide when looking at the range between your fan's highest possible *physical* or *indicated* speed and the maximum possible *logical* fan speed.
2. In theory, you should be able to safely choose any fan speed value for an upper threshold that is between the physical/indicated (whichever is higher) and the logical fan speeds.
3. Understanding that regardless of what inputs you provide for fan speed, it will be influenced by the fan hysteresis and potential rollover if a value is too high.

## Fan Hysteresis
Fan hysteresis is a control mechanism used in cooling systems to prevent rapid fluctuations in fan speed. It smoothes out fan speed changes such that very minor adjustments are ignored. For example, when calculating a fan's current speed, the BMC might convert 499 to 500 or convert 501 to 500. And it might convert 549 to 500 and 550 to 600. Thus, it would only report either 500 or 600. It would not report the values in between. Now think of the BMC applying this same type of behavior when setting speeds. The fan controller needs to know the power modulation level it should set a fan to; it does not understand RPMs. So, the BMC has to first convert a PWM value to the fan duty percentage or PWM %, and then it sends that request to the fan controller when it wants to alter a fan's speed.

Now, imagine the BMC is trying to tell the fan controller to adjust power from 499 RPM to 501 RPM. If the fan's maximum physical speed is 9,000 RPM, then this becomes an exceptionally small percentage of PWM difference. In fact, one can argue it would be imperceptible to a user. It's also incredibly difficult to quantify such a small change in a meaningful or logical way for the fan controller. Therefore, that approach just doesn't make sense. Even if the BMC understood floating point precision and could convey that to the fan controller in terms of extremely minute fan speed differences, it is a pointless endeavour, especially when one looks at this from the perspective of the fan motor, which is an analog system.

As you can see, getting too granular and specific with regards to fan speeds - especially when writing or setting new fan speeds - is just not worth it. The juice is not worth the squeeze. Other considerations underscore the fact that such an approach would be unrealistic and undesirable. To wit:
1. Legacy Compatibility: While 16-bit is the current standard, some older BMCs have only 8-bit registers (0-255). Since they cannot store actual target values, these BMCs leverage fan hysteresis to translate fan speeds to multiples of the fan hysteresis. Naturally, this produces can wide RPM ranges by definition.
2. Control Stability: Comparing current versus expected fan speed against hysteresis-rounded values avoids overcorrecting and redundancy.
3. Noise Reduction: Hysteresis prevents rapid reporting fluctuations (e.g., updates of 400 → 500 versus 499 → 501 RPM).

### Hysteresis as a Scaling Factor
Here's a breakdown of how fan hysteresis works:

1. A raw pulse input is received from the fan controller. The BMC counts the number of pulses (P) it receives over a fixed time period.
2. A Scaling Factor (SF) is used to convert the raw pulse count to RPM.
3. This number is then rounded up or down to the closest hysteresis multiple (± Hysteresis).

BMCs convert raw tachometer pulses (received from the fan controller) to RPM using this formula:
> Calculated RPM = ROUND ( Raw Pulse Count × Scaling Factor ) to nearest Fan Hysteresis multiple

or

> C = ( P * SF ) / H ) * H

> P=48 | SF=120 | H=100

Solve for C.

For example, presume inputs are: *P*ulses per time interval = 48; *S*caling *F*actor = 120 intervals per minute; Fan *H*ysteresis interval = 100 RPM
> C = ( P * SF ) / H ) * H
> C = ( 48 * 120 ) / 100 ) * 100
> C = ( 5760 / 100 ) * 100
> C = ( 576 ) * 100
> C = 5760

The full process looks like this:
1. Tachometer generates pulses (2 per revolution is typical).
2. 16-bit counter accumulates pulses over 1-2 seconds.
3. BMC calculates RPM using pulse-to-RPM formula (using Scaling Factor).
4. Error checks compare against thresholds.

> How does the BMC count the pulses if it is limited to an 8-bit counter?
> It uses either a 2x 8-bit strategy to combine them in order to mimic a 16-bit counter, or
> uses a slightly different method to make broader (less precise) generalizations about the fan speed.

## Reasonable Fan Threshold Limits
Now, taking into consideration the above information, decide on your strategy.

### Upper Thresholds: Finding the *Real* Maximum Fan Speed
We're not done yet in terms of figuring the *real* maximum speed of a given fan. In practice, there's a bit more too it. The final step is to calculate the absolute true maximum logical fan speed by finding the highest multiple of the fan hysteresis that will not trigger a rollover. This last step is relatively simple. There are two possible formulas, depending on the BMC's architecture.
- 8-bit limited BMC registers
  - The formula is straightforward as it is impossible to create a rollover condition using this method.
  - Maximum logical fan speed is `{Maximum Fan Hysteresis Multiple} x {Fan Hysteresis}` or simply `255 * H`
  - So, if your fan hysteresis is 100, the maximum logical fan speed becomes 25,500 (255 * 100 = 25500).
  - Example
    - Set the upper speed thresholds for a fan to their maximum possible values for a BMC with an 8-bit register.
    - This equates to values of {253 * H} {254 * H} {255 * H}.
    - For example, where *H = 100*:
```
ipmitool sensor thresh {sensor name} upper 25300 25400 25500
```

- 16-bit BMC registers
  - Calculate highest multiple of the fan hysteresis closest to the maximum logical fan speed (32,767) without exceeding it.
  - Since the fan hysteresis is static, the 8-bit method will usually also work, bearing in mind the absolute (32,767) ceiling limit.
  - Forgoing the 8-bit method and setting the UNR to the highest possible value, the formula is effectivey `32767 - {Fan Hysteresis}` then rounded to the nearest fan hysteresis multiple.
    - For example, if fan hysteresis = 100, then the highest possible value to set without creating a rollover would be 32,700, calculated like so: `32767 / 100 = 327.67 = 327 * 100 = 32700`
    - Expressed as an IPMI command, it could look like this:
```
ipmitool sensor thresh {sensor name} upper 32500 32600 32700
```

### Lower Thresholds: Determining Appropriate Minimum Fan Speed Thresholds
Determining lower fan speed threshold settings is much simpler than their upper counterparts.

First, decide on your goals. This is usually easier to settle on for the upper fan speed thresholds, because generally speaking a fan spinning too fast is not a safety problem for a server. However, when a fan is spinning too slowly, that's normally a bad thing. This makes the lower thresholds especially important to get right.

What should the goal be of your lower fan speed thresholds? Do you want your fans to kick in to an emergency mode and blast all fans at 100% if one or more of them have speeds that fall below their expected operating speed range? Perhaps your fans are not all the same model, or you may have different concerns for different fans. For example, it's not uncommon to be more concerned about a CPU fan versus chassis fans.

Regardless of your overall strategy, _LCR and LNR values should always be set at least two (2) fan hysteresis below the slowest normal operating speed_ of any given fan. Failure to follow this rule will create a high likelihood of inadvertent triggering of the BMC's emergency fan mode. At the very least, this rule should be applied to values for LCR and LNR.

The LNC value is more or less insignificant and can be arbitrary. However, it still make sense to follow the above rule for it when feasible, as violating the LNC speed may trigger notification alerts, which can be misleading or annoying when they occur frequently and essentially for no reason.

### Repeating the Same Value is OK
It is perfectly acceptable to use the same threshold value for more than one threshold for the same fan. For example, you could set the LNC, LCR, and LNR all to say, 500 RPM. And likewise with the upper thresholds. However, sequential alert levels must be structured such that the less severe alert type is closer to the normal operating speed of the fan. In other words, don't short-circuit your most important alerts. This concept is easier to visualize with specific guidance:
- UNC < UCR < UNR
- LNC > LCR > LNR

### Potential Lower Threshold Strategies
Examples of common strategies for lower fan speed threshold settings.

#### Absolute Lowest
This plan makes sense when either of these circumstances are true:
1. Your fans naturally operate at very low RPMs; or
2. You do not want emergency mode to ever kick in unless a fan fails completely (i.e., dead, 0 RPM reported)

The concept is that you do not want your fans to trigger emergency mode if at all possible. Ideally, it will never happen, and the only time it should happen is if a fan suddenly stops spinning at all for some reason.

Presuming an order of: *lnr* *lcr* *lnc*

```
ipmitool sensor thresh {sensor name} lower 32500 32600 32700
```

#### Trap Slow or Dying Fans
This plan makes sense when you want potentially degraded fans to trigger the fan emergency mode. The idea is to set lower fan speed thresholds to as close as possible to the low end of each fan's normal operating range.

Presuming an order of: *lnr* *lcr* *lnc*
- LS = Lowest Speed (operating, normal)
- FH = Fan Hysteresis
```
ipmitool sensor thresh {sensor name} lower {LS - 3x FH} {LS - 2x FH} {LS - 1x FH}
```
or
```
ipmitool sensor thresh {sensor name} lower {LS - 2x FH} {LS - 2x FH} {LS - 1x FH}
```

For example, for a fan with a lowest observed normal operating speed of 1,500 RPM and a fan hysteresis of 75:
```
ipmitool sensor thresh {sensor name} lower 1275 1350 1425
```

## Avoiding the 'Yo-Yo' Effect
The BMC monitors all active fan speeds in real-time. This can lead to a 'yo-yo' or roller coaster effect occurring when fan speed thresholds are set inappropriately. 

This will occur when a fan's thresholds in the BMC are set too closely to the low or high end of its normal operating range. A typical use case when this occurs goes something like this:
1. The server is placed into a low speed fan mode.
2. The lower fan speed thresholds are set too high.
3. As the fan speeds drop after the boot-up sequence, one or more of their RPM speeds fall below the Lower Critical threshold.
4. The BMC goes into fan panic mode and sets all fans to 100% fan speed.
5. The BMC determines the state that caused the panic mode (fan speed too low) has now resolved, and discontinues panic mode, going back to its previous fan programming.
6. The cycle repeats at step 3.

> Note if the condition that caused the BMC to go into fan "panic" mode resolves, the BMC exits panic mode and returns the fans to their prior control state.
 
The scenario described above is more likely to occur when the server fans have a relatively low operating rotational speed range. For example, if the user has replaced the stock server fans with after-market fans that run slower and quieter. If the BMC thresholds were not adjusted at the same time, there is a distinct possibility this 'yo-yo' effect will occur at some point.
