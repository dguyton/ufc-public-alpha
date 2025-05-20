# P.I.D. Explained
P.I.D. is an acronym for _PID Controller_; a continuously adjusting feedback loop mechanism designed for industrial control mechanisms.

- P = Proportional
- I = Integral
- D = Derivative

While not normally incorporated into computer equipment cooling tasks, the concept can be surprisingly agile and well suited for such tasks.

## PID Usage for Temperature Control
Rack-mounted servers are notorious for their loud fans (think airplane jet engine) and for running fans louder than necessary when idle. This may not be a problem in a data center, but when the server is placed in a small office or Home Lab environment, it's a different story. 

PID lends itself well to indirect process manipulation, such as reducing data storage device temperatures in a rackmount server by intelligently controlling airflow through the server chassis. A PID-enhanced fan controller can effectively manage system cooling while moderating fan adjustments to minimize noise.

The Universal Fan Controller (UFC) applies PID **only to fans responsible for cooling disk devices**. Fans tasked just with cooling CPUs are not affected.

### How PID Affects Fan Speeds
UFC relies on its PID model to maintain:

1. Data storage device temperatures within a nominal range
2. Minimal case/system fan noise without compromising #1

Fan modulation is the primary tool available for temperature regulation in the server environment. Thus, output from the PID controller is applied as a modifier to the current fan duty cycle. This nudges fan speeds up or down to prompt the data storage device mean temperature toward the target temperature (Set Point).

The PID formula considers the current fan duty cycle, previous duty cycle, slope of the historic temperature trend, and various static weights to derive its recommendation. It presumes temperatures below the target (Set Point) are more acceptable than temperatures above the target, and therefore is tweaked to favor more rapid changes to fan speed adjustments when temperatures are rising and to respond more slowly when ambient temperatures are falling.

PID utilizes a measured response to temperature changes that takes into consideration the rate of change, factoring the *proportion* between the current and ideal fan duty cycles, recent *trend* in input temperatures, and *velocity* of the trend.

## Breaking Down the PID Elements
The PID algorithm takes a variable input (mean device temperature) and applies a correction to it (output stimulus to fan speed) using constructs (formula) to computed PID variables, each of which are influenced differently by the environment (*P*-*I*-*D*). 

The overall PID calculation is further influenced by a fourth variable: _Time_ which in this case means the _time interval between temperature polls_ (represented by _T_).

### _P_ is for _Proportional_
- Directly influenced by the raw delta between current temperature and set point (target temperature)
- *Increases* more rapidly as the current vs. previous temperature delta moves *further* from the set point
- *More* pronounced when the time interval between temperature readings is *higher* (lower frequency polling)
- *Less* pronounced when the time interval between temperature readings is *lower* (higher frequency polling)
- Influences the _direction_ of the PID adjustment

### _I_ is for _Integral_
- Heavily influenced by whether current temperature is trending toward or away from the set point (target)
- *Increases* more rapidly when temperature delta is moving *away from* set point (trend is expanding)
- *Decreases* more rapidly when temperature delta is moving *toward* set point (trend is contracting)
- Influences the _intensity_ of the PID adjustment

### _D_ is for _Derivative_
- Heavily influenced by Time (_T_) between temperature polls
- *More* pronounced when time between temperature polls is *lower*
- *Less* pronounced when time between temperature polls is *greater*
- Influences the _intensity_ of the PID adjustment

### _T_ is for _Time_
(_T_)ime is not part of the PID controller, but is equally if not more important because it dictates the cadence of temperature polling and when those controls have an opportunity to influence fan speed.

*T*ime interval should be carefully considered within the confines of your overall strategy as it is directly tied to [volatility](#volatility) and [managing risk](#managing-risk).

Though indirect, *T*'s impact can be profound as it has a heavy influence on the responsiveness of the overall fan control system. Shorter polling intervals lead to more frequent temperature checks, and potentially more frequent fan speed changes. Likewise, longer time intervals yield fewer opportunities for change. 

## Environment Variables
PID is a smoothing algorithm that attempts to reduce volatility in fan speed adjustments, based on the current environment.

- _Set Point_ (`SP`) : also known as the _target_, is the desired temperature goal
- _Time_ (`T`) : self-explanatory, but its importance is explained above
- _Error_ (`ERR`) : the delta between a measured temperature and the set point
- _Current Error_ (`ERRc`) : the current Error (delta between current temperature and the set point or target temperature)
- _Previous Error_ (`ERRp`) : the previous or last calculated Error

### Input is the Mean (Average)
PID controller inputs are calculated from the _mean_ (average) temperature inputs of _all_ data storage devices. Likewise, the **Set Point** is treated as the mean (average) _target_ value. This is the temperature goal you wish UFC to strive for, in terms of your data storage device *mean* temperature between all of your devices.

This signifies the possibility storage devices will be unequally affected by the cooling fans. For example, one device could be running significantly hotter than the others due to its lack of proximity to the cooling fans, and vice-versa another device could be significantly cooler for the opposite reason. The design and construction of the data storage devices themselves may also influence the rate at which their individual temperature rises or falls.

In order to mitigate this phenomenon to some extent, there is logic built-in to the Universal Fan Controller (UFC) to prevent storage devices experiencing extreme overheating from being ignored due to the averaging logic. If a device temperature reaches a threshold above the mean target temperature, its temperature reading will override the normal input temp. This is only true with regards to devices that become too hot. This logic does not concern itself with devices exhibiting temperature readings significantly below the **Set Point** target.

As disk temperatures are read on the next polling cycle, this information is fed into the PID calculation. A feedback loop ensues.
### Errors
It's important to clarify what an _error_ means in the context of PID. The term is commonly associated with something broken or not working correctly. Computer programmers tend to think of errors as unexpected and undesirable events; circumstances where the expected result or outcome of a process failed to occur.

With regards to PID controls and PID calculations, the term _error_ denotes when the perceived input value of the system is not at the desired level. Therefore, in the case of the UFC and its PID implementation, an error is a measure of how far (deviation) the temperature input is from the target temperature, and the direction of the deviation (positive or negative). For example, if hard drives are being monitored, and you have established a target or ideal ambient temperature of 30 degrees Celsius in the UFC configuration file, and the PID controller records a value of 35C, then your error is +5C as your current reading is 5C higher than the ideal reading. This works the same in reverse. If the current temperature is 25C, then the error is -5C. It's still a 5C deviation from the ideal target temperature, just in the opposite direction.

These error readings are used in the PID calculation to determine how aggressively the system needs to respond in order to bring the value being measured (in this case temperature of something) back to the ideal or target value.

## Volatility
Volatility measures the variance in change within an environment or system. A highly volatile environment is one where there is a lot of change happening rapidly. For instance, a computer system in a constant state of short bursts of activity followed by periods of inactivity. When a system is changing rapidly from one state (e.g. calm or highly active) to another (opposite state), it is highly volatile, and vice-versa.

Experimentation has shown that server-based fan controllers making concurrent adjustments to fan speeds in sync with real-time temperature changes promote high volatility systems. Models with linear correlations between temperature and fan speeds and short time intervals between temperature polls typically lead to excessive fan speed permutations, inefficient fan speed management, and erratic fan noise patterns as their fans ramp up and down abruptly with every iterative temperature change. 

Highly volatile fan control systems demonstrating frequent and sudden changes often regularly and/or randomly produce excessive levels of noise. Most people find it unpleasant to be in close proximity to servers with a fan controller behaving in such a highly volatile fashion. This is especially a concern for the Universal Fan Controller (UFC) as one of its [goals](program-goals.md) is to minimize fan noise whenever possible. The human ear tends to dislike the sound of case fans ramping up and down in rapid succession like a rollercoaster. That said, sometimes it is necessary.

### How UFC Mitigates Volatility
Ideally, when there is a change in input volatility (e.g. temperature), UFC would have an understanding of the causal relationship between the system environment and the inputs. However, this is not a realistic goal. UFC must act without knowing the cause, and hence cannot make reasonable predictions about near-future volatility and how it may trend. UFC can only evaluate the information gathers. It is always going to be a reactive system, and there's no way around this. Having said that, UFC can and does adjust its behavior based on the source of temperature inputs, and it makes inferences based on two criteria:

1. Source of input (CPU or storage devices)
2. Input trend

Universal Fan Controller (UFC) logic sensitive to volatility is bifurcated between CPUs versus data storage devices. CPUs require more aggressive and immediate temperature management, as they tend to be more likely to have significant changes in temperature very rapidly, and they are more sensitive to temperature, especially high temperatures. Therefore, we need to essentially ignore volatility when managing CPU cooling, and this is why the PID controller is not applied to CPU cooling. It's too slow. Again, we have to go back to the two primary [goals](program-goals.md) of UFC: preserving the health of the system trumps fan noise mitigation.

Data storage devices also need their temperature managed appropriately, but are not as acute. Most of the time, this works well from the perspective of the secondary goal (limiting fan noise as much as possible). There tend to be more fans involved in cooling devices versus CPUs. This means the effect on fan noise is *usually* more pronounced when case/system fans are adjusted versus CPU fans (which may or may not also be case/system fans). Regardless, there has to be a higher level of priority on the CPU fans, no matter which fans they are.

What this means in terms of UFC managing volatility is:
1. Volatility is less of a concern for CPU fans as they require immediate or near-immediate response times, and this fact drives their cooling plan above any other factor.
2. Data storage device cooling is by nature more flexible, and thus there is room for a more sophisticated level of control. This is where the PID controller comes into play.

These reasons are why the PID controller ONLY applies to fans NOT dedicated to CPU temperature management. The PID controller's purpose is to smooth out volatility, though not to the extent beyond which it may cause the system to violate its first directive (protecting data storage devices).

The PID controller's output is massaged to deliver proportional changes in fan speed based on the intensity of environmental variable changes. The intent is to strike a balance between mean device temperature modulation (primary goal) and keeping fan noise to the minimum necessary level (secondary goal).

Thus, UFC's PID model takes _volatility_ into consideration. However, it is not a prognosticator and is always in a position of reacting to stimuli. Therefore, some level of volatility is unavoidable. The question is, what tools can be utilized to manage it?

### Time (_T_) Interval Impacts Volatility
Changes in the value of _T_ (Time interval) contribute significantly to input temperature volatility. Frequent input sampling increases the odds of sudden changes in volatility from a low to a high state.

- Smaller _T_ values (shorter time frames) nearly always promote higher volatility
- Larger *T* values (longer time intervals) usually cause volatility to drift lower

If volatility is already low, longer time intervals may sully it further. But, if volatility is already relatively high, longer time intervals can exacerbate it.

Tendency of (*T*)ime constant's impact on PID volatility:
1. When *T* is short, and volatility is high, then *T* tends to increase volatility
2. When *T* is short, and volatility is low, then *T* is neutral to volatility
3. When *T* is long, and volatility is high, then *T* tends to increase volatility
4. When *T* is long, and volatility is low, then *T* tends to decrease volatility

## Managing Risk
Which risks will your PID control design be most vulnerable to? Especially, how does your choice of *T*ime interval affect them?

*T* has the greatest impact on system volatility, as it controls the frequency of input polling. Determining the most appropriate value for the *T*ime interval depends largely on how your system is expected to be utilized on a routine basis and your tolerance for risk. There is a trade-off between responsiveness and how reactive you would like the fan controller to be overall. That said, you should consider how the other PID values will work together in conjunction with your choice for *T* and also take into consideration your prioritization of fan noise versus cooling response time relative to mean temperature changes.

From this information, you should be able to make an informed decision on strategy for cooling fan management under your particular circumstances.

> [!IMPORTANT]
> Bear in mind, your choices of every PID value together dictate how your system favors risk tolerance. For example, if you prefer to set *T* to a shorter interval, it may be wise to use smaller PID adjustments, and vice-versa, though this all depends on how you want to structure your PID model behavior.

### The Inherent Value of *(T)ime*
*T* is perhaps the most important static variable you can control in terms of governing how PID leans in its priorities of fan control logic. Every approach has some level of risk. You will not completely eliminate it no matter how you structure your PID control variables. There is always going to be a scenario your UFC setup does not handle ideally.

As discussed above, time has a profound affect on volatility. This is not a bad thing. *T*ime is but one lever in the PID controller. It should be given ample thought when deciding how sensitive you want UFC to behave toward environmental change. 

The following describes the worst-case scenarios the PID controller is vulnerable to, based on various risk models. The purpose of this information is to provide some guidance on pros and cons of your PID variable choices, but especially relative to *T*ime.

### High Volatility Environments
There are a couple of possible risk scenarios to be aware of when temperature volatility is high.

- Too Short *T* intervals
	- PID may react sharply to wide changes in temperature, resulting in more aggressive ramping up or down of fan speeds
	- Fan noise changes rapidly and frequently (potentially annoying)
	- Fan behavior may be unnecessary or even counter-productive

- Too Long *T* intervals
	- Temperatures between polling periods fluctuate widely
	- High volatility occurs between temp polls that is not detected
	- PID gets false impression volatility is low, when in fact it is high
	- Storage devices may run significantly hotter than target temp for longer

#### Short *T* + High Volatility
- PID may react sharply to wide changes in temperature, resulting in more aggressive ramping up or down of fan speeds
- Rapid changes could be annoying in terms of fan noise
- Fan behavior may be unnecessary or even counter-productive

#### Long *T* + High Volatility
- Temperatures between polling periods fluctuate widely
- Possible high volatility occurring in between temp polls is not detected and PID gets false impression volatility is low, when in fact it is high

### Long *T* Edge Case: Masked High Temperatures
When polling periods (_Time_ intervals) between temperature readings are long, and temperature fluctuations between readings are highly volatile, polled temperatures may not be telling the whole story.

A high *T* setting can create a scenario where the server environment appears to have consistent temperature readings, but in reality this is not true and there is a high level of volatility in input temperatures happening *between* PID control calculations. In this case, spikes in mean storage device temperatures are masked by the long *T* periods and thus, are unknown to the PID controller. The environment (input) temperature trend appears to be neutral. Under these circumstances, fan speed adjustments will be limited (if any occur at all).

#### Does It Matter?
One way of looking at this scenario is to conclude it doesn't matter. Under this school of thought, since the mean storage device temperature appears stable, any temperature spikes are temporary and the current fan speed is enough to bring them down close enough to the prior temperature reading that PID does not detect a new trend. Although there may be dislike for such temperature spikes, they are likely not causing harm either. Therefore, perhaps this behavioral risk is tolerable.

### Smoothing the Curve
The PID controller is always intent on aligning the system environment such that it is either in a state of low [volatility](#volatility), or moving from a state of high volatility to low volatility. Let us dive deeper in to the nuances of how the PID controller accomplishes this.

The (_D_)erivative exacerbates the (_P_)roportional reading when the most recent temperature reading is moving in the same direction as the overall temperature trend. However, when the most recent temperature change goes against the trend (a sign of possible trend reversal), then _D_ counteracts _P_ and reduces the impact of _P_.

When a temperature trend reverses, _D_ begins working against _P_, causing a change in fan duty cycle, and moderating slowly from its peak. For example, when storage device temps are cooling rapidly - approaching the Set Point (_SP_) from a large positive delta above _SP_ - then, _P_ will be positive and _D_ will be negative. Thus, when the apex or peak temperature change occurs, _D_ is pushing back against _P_ the greatest. This results in a smoother curve ramping up the corresponding fan duty cycle. While _P_ has a greater influence than _D_, the pushback from _D_ causes the slope of change to be more gradual.

The opposite is also true. After average disk temperature peaks, it begins to revert (drop) toward the mean (_SP_). Then _D_ starts to have a greater effect on fan duty cycle, as _P_'s impact diminishes. This results in smoothing the fan speed curve (duty cycle) on the way down as well. Eventually, as temperatures drop more rapidly, input temperatures come closer to the _SP_. The effect of _D_ becomes less pronounced, and _P_ becomes much more significant again, resulting in a more rapid drop in the fan duty cycle as the mean device temperature approaches the _SP_ temperature.

This process works both ways; i.e., with rising or declining disk temperatures. The further away the current average disk temperature moves from the Set Point (_SP_), the greater the effect the Derivative (_D_) has on the fan duty cycle, relative to the Proportional factor (_P_).

When the temperature trend reverses, _P_ and _D_ begin working against one another. This causes _D_ to have the effect of taming or reducing the impact of _P_ and its affect on moderating fan speed. Specifically, _D_ works to counteract _P_ (works against it), which in turn causes the change _P_ applied to have a less pronounced impact on modifying the overall fan duty cycle.

> [!TIP]
> If you'll be using this fan controller in a home lab environment, you may prefer to avoid an implementation prone to high volatility, as it tends to lead to rapid and sizeable spontaneous changes in fan speed (and noise).
> 
> Take this into consideration when determining your input values.

All of this behavior mimics what is happening in the system environment. As the environment moves toward stability, a logical preference is to stop pushing hard on trying to catch up or balance the change of the variables in that environment. For instance, there is no point in continuing to run your server fans at full speed after they've brought down temperature to a manageable level, unless the stimulus that created the higher temps in the first place is still pushing those temps up.

# PID Variable Relative Importance
Having gone into great detail on the influence of *T*ime on the PID controller's output, it's worth noting the affect of each P-I-D value and how their relative importance is ranked. In this context, "importance" refers to the variable with the greatest influence on the outcome (fan speed).

The ***Proportional*** value is the easiest concept to understand. It is simply the current error (the delta between the current temperature and the Set Point or target temperature). 

The **Proportional** value has the greatest impact on how PID influences fan speed, followed by the **Derivative**.

The ***Derivative*** is the slope of the error line. It measures the _ratio of change_ of the error over time. For example, if a system's temperature is increasing and its rate of increase is accelerating over time, this will be reflected in the **Derivative**.

The **Integral** is a running tally of temperature errors. It is cumulative. During every cycle, the current error is added to the **Integral**. This tends to augment the **Proportional** value.

The **Proportional** is the most important value. It acts as the baseline delta between the current temperature state and the desired state. **Derivative** is the next most important value. The **Derivative** acts as both an amplifier and a moderator. The **Proportional** describes how far from the target the current temperature state is, while the **Derivative** moderates the intensity of the trend by amplifying how quickly fan speed change proceeds in the direction of the current trend.

## Tweaking Outcomes with Constants
The PID formula can be further enhanced through the use of _constants_. By defining these constants, the end user is able to influence the weight of each PID variable applied to the final result. This allows the user to weight the formula. Larger constants increase the influence of the measure, while smaller (e.g. fractional) constants reduce it. The proportion of constant values to one another also has a notable influence on the final formula outcome.

> Kp : Proportional constant exacerbates the real-time temperature delta
> 
> Ki : Integral constant amplifies the cumulative deviation value
> 
> Kd : Derivative constant causes the slope or intensity of recent changes to have a greater influence

When constants are applied: `new value = current value + Kp + Ki + Kd`

As you can see from the formula, since these constants are user-defined in the [Builder program configuration file walk-through](/documentation/configuration/builder-config-file.md), they may be used to tweak the scaling effect of the PID formula even further, by placing greater or lesser influence on one value or another.

### _Proportional_
This is a correction _proportional_ (P) to the _current error_ (ERRc), multiplied by the _tuning constant_ (K).

The formula for P is simply `Kp * ERRc`

> Kp = constant * proportional
> 
> ERRc = current error

The (_P_)roportional setting is the primary influencer of the PID values in terms of how aggressively fan speed djustments ramp up or down. The Proportional value always moves the fan speed duty cycle in the same direction as the current temperature trend. For example, when the disk drive temperature average exceeds the Set Point (_SP_) positively, _P_ increases. Likewise, when the average disk temp moves away from the _SP_ negatively, _P_ decreases. The movement of _P_ is proportional to the current differential temperature difference between the current average temp and the _SP_.

### _Integral_
This is a correction for _cumulative error_.

Every cycle the product of the _current error_ (ERRc) and _time interval_ (T) are added to the _cumulative error_ (ERR), and then multiplied by a _tuning constant_ (Ki).

This adjusts the offset in a way that nudges input measurement (temperature) a bit below or above the _set point_.

The formula for I is `I = Ki * (( ERRc * T ) + ERR )`

> Ki = constant * integral
> 
> ERRc = current error
> 
> T = time interval
> 
> ERR = cumulative error

#### Integral and its Constant (_Ki_)
The ***Integral*** incorporates a mathematical constant (_Ki_). The usefulness of the constant - which acts as a multiplier of the calculated **Integral** value - is debatable among PID application designers. 

_Ki_ (the Integral constant) may be used to amplify the affect of PID. Values above zero exacerbate the influence of PID calculations. For this reason, Integral (_Ki_) constants should be applied judiciously. If _Kp_ and _Ki_ are assigned the same value, it causes _I_ to effectively act as an amplfied version of _P_. The reverse is also true. A value of _I_ less than _P_ (but not zero or less) will cause _I_ to more closely resemble _P_.

Many PID processes ignore the Integral's constant by removing it from the **Integral** (_I_) formula entirely or setting it to one (1). Why? Many end users find the **Integral** has a tendency to exacerbate the **Proportional** movement and cause it to overshoot, generating more marked and rapid transitions.

> [!WARNING]
> _Ki_ values < 1 reduce the impact of the Interval, and thus the rate-of-change in the overall PID calculations. While values > 1 cause the Integral multiplier to have an out-sized impact.
> 
> Remember the calculated Integral (_I_) value is **cumulative**, meaning it will add itself to the Integral from the previous cycle. When the variable Time (_T_) between cycles is short, an Integral interval constant > 1 will result in rapidly cascading escalations.

#### Use Caution When Applying Constants to Integral 
Higher integral values (especially > 1) tend to exacerbate abrupt and wide changes to fan speeds, resulting in a similar, choppy pattern in ambient fan noise. Most people adjust to constant volume background noises, but will find this scenario to be a negative experience as it tends to generate a random noise pattern.

There is one use case scenario where a non-zero Integral Constant could make sense: when you have a temperature critical device, and keeping that device's ambient temp within a tight range is a priority over audible noise.

There really isn't any point in using both _I_ and _P_, because the longer the script runs, the more they tend to counteract one another.

Understanding this quirk of PID helps to understand why many users express dissatisfaction when `Ki is > 0`, because its affect on fan speed is more likely to be abrupt. 

This is why many experienced users typically set `Ki = 0` in order to eliminate the effect of _K_ to begin with. Another possibility is to set `Ki = 1`, though this options retains an influence on the PID result, and if _Kp_ is relatively low it will tend to mute the role of _P_ over time.

#### Is Integral Useful?
Whether or not to use Integral is a personal decision. Generally speaking, if you favor the prioritization of rapidly responding to changes in cooling demand over fan noise, then you are probably better off utilizing Integral. However, if you are more concerned with fan noise than the speed at which your fans respond to cooling demand change, or have no opinion on the matter, then you are unlikely to observe any adverse effects should you choose to exclude Integral by setting its constant to zero (0) in the configuration file (`Ki = 0`).

### _Derivative_
This is the change in _current error with respect to time_, or basically the _slope of the error_ over time.

Subtract _current error_ (ERRc) from the _previous error_ (ERRp), divide by the _time interval_ (T), and multiply by another _tuning constant_ (K).

The formula for D is `D = Kd * (( ERRc – ERRp ) / T )`

> Kd = constant * derivative
> 
> ERRc = current error
> 
> ERRp = previous error
> 
> T = time interval

_Kd_ is a derivative tuning constant (_K_) applied to the Derivative (_D_). The Derivative moderates the slope of change over time, and the constant (_K_) applied to _D_ influences how strongly _D_ moderates the Proportional (_P_) value. _D_ can work with or against _P_, depending on the temperature trend. _Kd_ is optional, and can be used to force curve fan speed changes more or less aggressively.

Higher _Kd_ numbers will cause the fans to change speed more quickly, and vice-versa. However, its effect on raw fan speeds is less pronounced than _Kp_ or _Ki_. _Kd_ is a coarse adjustment. You could reproduce a similar effect by simply decreasing or increasing _T_ (time interval) between readings, causing fan adjustments to occur more or less frequently.

Kd may be used as an alternative to adjusting _T_ (_Time_) based factors. It can be used to accentuate or mitigate more or less fan speed changes, though _T_ and _Kd_ function quite differently.

The difference in their behavior is complicated, but at a high level, Kd has a tendency to mitigate or counter-balance extreme movements in _Kp_ and _Ki_, while altering Time (_T_) is a universal influencer of polling frequency, while also having some (though less direct that _Kd_) affect on PID calculations.

> _Kd_ constants typically work best when they are multiples of your _T_ polling time separation between temperature polls, though they can also be fractions of _T_ (e.g. 60 where `T = 120`, such that _T_ is a multiple of _Kd_, and _Kd_ is a fraction of _T_).

When an event occurs which causes the disk drive temperatures to increase rapidly:
- the larger the increase in error, the larger _D_ is
- in the case of a large positive error, _D_ and _P_ are additive, aggressively increasing duty cycle
- _D_ exacerbates _P_ (more aggressive fan speed adjustments) when the most recent temp reading is moving in the same direction as the past several temp readings, but works against _P_ (less aggressive fan speed adjustments) when the most recent temperature polling indicates the current temperature is now moving back toward the set point (_SP_)

## R-PID Formulas
For completeness and transparency, the actual PID formulas used in the R-PID runtime program are described here.

`proportional = Kp * ( current error )`

`integral = Ki * ( ( current error * T ) + cumulative error )`

`derivative = Kd * ( ( current error - previous error ) / T )`

### Time Interval (_T_)
The _time interval_ is expressed in **minutes**. This prevents the values impacted by Time from being abrupt and out-sized, since the temperature polls are conducted every fraction of a minute (the polling delay timer is measured in seconds).

#### Derivative (_D_) versus Time (_T_)
Optionally, fan duty cycle sensitivity may be influenced by adjusting _Kd_ instead of _T_ (Time).

_Kd_ influences current temperatures by exaggerating changes in their values, relative to the frequency (_T_) of polling those temperatures. A higher _Kd_ (greater than 1) will cause rapid increases in temperature readings to illicit a more robust fan speed response (acting sooner and/or potentially spinning fans up to a higher duty cycle more quickly). While vice-versa, lower _Kd_ values (below 1) will slow the response of the script to rapid changes in temperature readings, and thus make the script less sensitive or less responsive.

On the other hand, higher _T_ values mean there is more time between polling checks, which reduces volatility, or the opposite (lower _T_ values tend to equate to increased volatility in _Kd_), depending on the rate at which the current temperature trend is increasing or decreasing.

### Constant Recommendations
The constants are defined in the [Builder configuration file](/documentation/configuration/builder-config-file.md).

The general recommended use of the constants is:
- Kp: 1 - 10x
- Ki: 0 or 1 or fraction of 1
- Kd: 50 - 200x ; the higher the number, the greater the influence of the Derivative

### Re-capping Constants
PID utilizes constants as switches that moderate or accentuate various calculations. It is important to understand the role of each PID constant and how they amplify their respective PID values.

- P = Period
- I = Integral
- D = Derivative
- PID constants are programmatically expressed as Kp, Ki, and Kd
     - Kp influences the time interval between temperature checks
     - Ki is usually ignored by setting it to 0 (zero).
     - Kd influences the time interval calculated from the difference in current and previous hd temp differences from the set point.

Do not use negative constants. And particularly, do not mix and match their signs. For example, negative Ki and positive Kp will cause Ki to counteract P (i.e. fans might be adjusted in wrong direction).
