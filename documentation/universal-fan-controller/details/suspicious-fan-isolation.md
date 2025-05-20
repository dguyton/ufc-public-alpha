# Suspicious Fan Isolation
In UFC's terminology, a ['suspicious' fan](/documentation/universal-fan-controller/suspicious-fans.md) means an active fan header that suddenly exhibits behavior inconsistent with it's expected behavior. When discovered, suspicious fan headers are tagged for further scrutiny. If the condition that caused the fan header to be flagged does not improve quickly, UFC will remove the fan from its list of active (operating) fan headers and re-calculate the fan cooling environment.

## Suspicious Fan Criteria
UFC deems a fan to be 'suspicious' when a significant, negative change occurs in fan's behavior, such as:
1. Change in fan state from active/ok to an inactive state, such as "no signal"
2. Reporting a rotational fan speed of 0 RPM or "n/a"
3. Reporting a rotational fan speed more than two standard deviations from its expected fan speed for the current fan duty level
4. Reported a suspicious state in the prior fan sweep and has not returned to a normal state in the current fan sweep

## Disqualifying a Fan Header
A determination that a fan header is acting suspicious is the first step toward flagging a fan header for disqualification. In order for a suspicious fan to be _disqualified_, it must exhibit suspicious fan behavior for **two consecutive** fan analysis cycles. 

Fan headers confirmed to be problematic are removed from service immediately. This can cause a number of significant escalations, depending on how many fans were active before the disqualification, and other factors such as the ratio of CPU to disk device cooling fan distribution.

When a fan is disqualified, UFC re-evaluates the entire active fan landscape. This includes examining the total number of fans available, and the new distribution of CPU vs. non-CPU assigned cooling fans immediately after the disqualified fan is removed from service. Examples of adverse events that can occur at this point include:
- Now no active disk cooling fans exist, meaning the server must be treated as in a "CPU cooling only" state.
- If now no active CPU cooling fans exist, any active disk device fans must be re-assigned to CPU cooling duty. This will change how certain fan duty controls are handled.
- If now no active CPU fans are available, UFC must exit and will attempt to do so gracefully.
- Certain minimum/maximum ranges may be affected and need to be recalculated, which may have other adverse effects.
- If enough cascading disruptions occur, the program may bail (hopefully, gracefully).
