# Fan Hysteresis
Fan hysteresis is explained here, because it pertains to particular functions of the PID Fan Controller program, including certain automated and manual parameters that directly impact the accuracy and efficiency of the program to monitor for failed or failing fans.

Without a thorough baseline understanding of what fan hysteresis is, how it works, and how BMC's typically utilize it, some program functions may not work as expected. This is especially true with regards to the upper and lower fan speed thresholds, which when exceeded will cause the BMC to panic and drive all of your fans at 100% power. One of the critical goals of this program is to prevent that from happening, and to offer an automated method of setting those values to prevent such conditions from occurring.

## What is 'hysteresis'?
If you've spent any time reading BMC fan speed sensor readings, you've noticed they are always multiples of some number. They are never very granular. This is true for several reasons. Notably, the actual raw fan speeds of PWM fans naturally fluctuate. And given this fact, and given what the BMC fan sensors endeavour to accomplish, there isn't any point in trying to track exact fan RPM speeds down to the integer level. This is because that information is not very important.

What is important is the ability to monitor fan speeds such that a fan that is failing or operating outside of an expected range is likely either faulty or in the process of failing. Furthermore, when comparing similar fans and monitoring their operation, it makes sense to acknowledge the fact those fans can and will fluctuate within their own sends of normal operating range and with respect to one another.

Thus, the concept of relative fan speeds becomes more significant than exact fan speeds.

On the other hand, there is also a need to monitor fan speeds for consistency, and there are good reasons to want those fan speeds to remain relatively consistent and within a more-or-less narrow operating range, to the extent that range allows some wiggle room while also making it easier to identify faults.

_Hysteresis_ is simply a target RPM range of this _wobble, per se_ of fan speed fluctuations, which is normal. The fan hysteresis is the range of one interval of this variation.

There is also an added benefit to the use of fan hysteresis as a fan speed range variable. By applying it as a multiplier, the BMC is able to monitor a very wide range of potential operating speeds of any fan. In addition to leveraging multiples of the hysteresis to calculate hardware-constrained upper fan speed limits, multiples of the fan hysteresis introduce practical discipline by preventing setting fan speed thresholds that are too close together, for the purpose of allowing normal fan speed deviations to occur without triggering a panic attack by the BMC.

In short, by understanding what any given BMC's fan hysteresis is, it becomes possible to segment upper and lower fan speed thresholds an appropriate distance from their hardware limits as defined by the BMC firmware, and to utilize appropriate gaps between individual levels of BMC fan speed thresholds (both upper and lower ranges).

## Relationship to Fan Hardware
It is important to bear in mind that fan hysteresis pertains only to the BMC. It has nothing to do with the physical capabilities of the fans themselves. 

The fans do not care what the fan hysteresis is. They spin within a given range of RPMs, and that is all that they do. Each fan has a physical lower limit, below which it will stall. Likewise, it has an upper physical limit. The fan's speed will never exceed this upper limit no matter how much power is applied to the fan, because the fan's motor cannot spin the blades any faster.

The fan hysteresis is simply a ruler used by the BMC to approximate the maximum fan speed the BMC _expects_ any given fan to be capable of, but more importantly it is simply a means for the BMC to leverage a range of values with a multiplier, which makes monitoring and reporting of the speed of the fan a simpler affair.

## Fan Hysteresis Limits
The lower limit is 0. Depending on the BMC, the attempted use of negative numbers may cause the BMC to ignore the number as invalid, and treat it as 0 (zero). Or, it may count backwards from its maximum value, subtracting the input from the max. Either way, the end result of the validated figure the BMC will use becomes somewhat unpredictable. Therefore, this practice is strongly discouraged.

The theoretical maximum of any known BMC is 32767, which represents the highest unsigned 16-bit value possible. However, most BMC's are further limited to a maximum value of
>`255 * fan hysteresis`

How do you know what the fan hysteresis is, and thus calculate the maximum possible 10-base integer value?

BMC's typically use a multiple of 25 as their hysteresis value; i.e. 25 | 50 | 75 | 100 | 150 are common. 75, 100, or 150 are most common.

For example, a BMC fan hysteresis of 75 would yield a maximum upper limit of 19,125.

Attempting to input a value higher than 19,125 in this case, things get a bit tricky. The actual formulary limits are a bit more complex than simply factoring the 255x multipler. Most BMCs also round down these type of figures. This means the true upper limit is actually

```
( 255 * fan hysteresis ) + ( 0.5 * fan hysteresis )
```

In other words, up to the mid-point between the maximum upper limit of 255x fan hysteresis and 256x fan hysteresis will be rounded down to the 255x limit. So, in the case of the aformentioned example, the actual limit turns out to be 19,162.

Interestingly, the BMC will accept 19,162 as input, but this figure will be rounded down and converted to the true maximum (255x) of 19,125. When the stored value is later read from the BMC, it will be reported as 19,125 and not the 19,162 input that was saved to the BMC (since the BMC would have rounded that down to an actual multiple of the fan hysteresis of 75).

Likewise, a BMC with a fan hysteresis interval of 100 would permit a maximum upper fan speed threshold of 25,550 RPM. This figure is derived by this formula:

```
( 255 * 100 ) + ( 0.5 * 100 )
```

Note that when the value is stored in the BMC, it will be rounded down to 255x or 25,500.

## Mid-Point Calculations, and Rolling Over the Limit
Some BMCs will roll over a value larger than their maximum, and reset it beginning with number 1 or the number 0.

For example, if the highest number the BMC can count is 16383, then if a threshold value is applied of 16384,

Presume a BMC with an unusual fan hysteresis interval of 64. It's maximium upper limit is 255 * 64 or 16,320. It's maximum input without rolling over would be the mid-point between 255x and 256x fan hysteresis, or 16,320 + 32 (1/2 of 64), or 16352. Any value between 255x fan hysteresis - 31 and 255x fan hysteresis + 32 will be treated as 255x fan hysteresis; i.e. in this example, any input value between 16,289 and 16,352 gets treated as 16,320.

Why is the lower range in this example not 16,288 (255x - 32)? As the BMC rounds down 10-base values falling between fan hysteresis interval multiples, the decimal value must place it past the mid-point between two hysteresis multiples in order for the multiplier to get incremented one more higher.

Rollover calculations are tricky because the BMC may reset a rollover figure to start as either 0 or 1. Practically speaking, it doesn't matter, as the end result is the hysteresis interval multiplier gets reset to 0 regardless of the decimal figure. Even if the value rolls over to 1 during the re-calculation process, it will be reset down to 0 when stored in the BMC, since it will represent a 0x multipler, and the zero (0) is what will be recorded. To get to a stored multiplier of 1, the roll-over figure would have to exceed the mid-point of the fan hysteresis value itself (e.g. final number after rollover of 38 - 112 for a 75 RPM interval fan hysteresis would equate to a multipler of 1x since 38 exceeds the mid-point between 0x and 1x multiplers, but 112 does not exceed the mid-point of multipliers 1x and 2x, thus the result is 1x fan hysteresis in this example).
