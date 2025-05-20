# Suspicious Fans
In UFC terminology, a suspicious fan refers to a fan header currently marked as active that suddenly exhibits behavior inconsistent with its assigned fan duty.

When a suspicious fan is detected, it is flagged for further scrutiny. If the abnormal behavior persists beyond a short monitoring period, UFC removes the fan from the list of active (operating) fan headers and recalculates the fan cooling environment accordingly.

## Suspicious Fan Criteria
UFC deems a fan to be 'suspicious' when a significant, spontaneous negative change occurs in the fan's behavior, such as:
A fan is deemed suspicious when it undergoes a significant, spontaneous negative change in behavior. Examples include:
- Changing from an active/OK state to an inactive state (e.g., reporting a "no signal" status)
- Reporting a rotational speed of 0 RPM or "n/a"
- Reporting a speed that deviates more than 2x the fan hysteresis interval from the expected RPM at the current fan duty level
- Continuing to report a suspicious state in consecutive fan sweeps (i.e., was already flagged in the previous cycle and has not recovered)

## Resetting Suspicious Fan Tag
The suspicious fan process has a very short-term memory. A key part of the process is looking for validation that a fan is in fact failing or has failed completely. In order to avoid disqualifying a fan when a polling could have gleaned bad data, or the fan may have had a momentary voltage drop, consecutive failure conditions are required before any action is taken other than tagging a fan for follow-up screening.

If a fan is marked 'suspicious' and it subsequently appears to be operating normally during the next fan polling, its suspicious fan flag will be removed. This process will then start over if the same fan is tagged again in the future.

## Disqualifying a Fan Header
Detecting a suspicious fan is the first step toward possible disqualification. A fan will be disqualified if it continues to exhibit suspicious behavior for two consecutive fan analysis cycles. Once confirmed, the fan header is immediately removed from service.

Disqualifying one or more fans may result in escalating system adjustments, depending on:
- Number of fans active prior to disqualification
- Balance of fan duty between CPU cooling and disk/chassis cooling

### Effects of Fan Disqualification
When a fan is removed from service, UFC re-evaluates the system's cooling environment, including:
- Total number of remaining active fans
- The new distribution of CPU vs. non-CPU assigned cooling

This may lead to several cascading changes or disruptions, such as:
- No active disk cooling fans remaining: UFC pivots to operate in "CPU-only cooling" mode.
- No active CPU cooling fans remaining: any disk cooling fans are reassigned to handle CPU cooling.
- Zero CPU cooling fans after reassignment: UFC must shut down and will attempt to exit gracefully.
- Fan duty minimum/maximum ranges may need to be recalculated, which could have downstream effects.

If multiple cascading disruptions occur, the program may enter a failsafe mode or bail out entirely, with the intent of doing so gracefully.
