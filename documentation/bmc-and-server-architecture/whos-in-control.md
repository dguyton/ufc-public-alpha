# Potential Causes of Fan Speed Race Conditions
When attempting to control fan speeds manually - such as through IPMI - it is not uncommon to encounter a scenario whereby whenever a user attempts to set fan speeds manually, after a few seconds the fans revert back to their previous speed and/or mode. There are a few possible explanations:

1. BIOS overwriting user's fan speed commands
2. User's commands cause fan speeds to exceed fan speed threshold limits
3. Another program trying to control fan speeds manually at the same time

In order to diagnose the root cause, one must understand how the BIOS, BMC (Baseboard Management Controller), and Fan Controller all work together.

## The Fan Controller
The [fan controller](#the-fan-controller) - sometimes referred to as the "chassis controller" - is a low level hardware component directly responsible for implementing commands to the fans by regulating voltage applied to each fan header. The fan controller also reports fan tachometer readings back to the BMC.

## The BIOS
The BIOS is essentially a simplistic operating system on a chip. Initiated when the power button is turned on, its primary purpose is to lay the foundation for a higher level operating system the user will interact with. One responsibility of the BIOS is to ensure the components of the server environment are operating normally. To this end, its responsibilities include validating the presence of expected hardware, initializing data storage devices, and checking various systems for errors. These roles include starting up the fans as soon as possible, and setting their speed to pre-determined levels. Thus, the first fan speed commands on system boot are sent from the BIOS and received by either the BMC or the fan controller directly.

## The BMC
As explained [here](bmc.md), the Baseboard Management Controller (BMC) is a dedicated chip responsible for overseeing low-level hardware management on a server motherboard. The BMC's role is two-fold: first, provide out-of-band access to the server by remote users; and second, act as a middle layer between low-level hardware components and the operating system.

## How Fan Control Commands Are Routed
There are two possible paths the BIOS may take to reach the fan controller, depending on the architectural design of the motherboard.

Both the BIOS and BMC to communicate with the fan controller. On most modern server motherboards, the BMC has the only connection to the fan controller, meaning everything else - including the BIOS - must route commands to the fan controller through the BMC. This arrangement centralizes the communication path and allows the BMC to be aware of how the fans should be behaving at all times. A disadvantage of this approach is slower boot-up times, as the BIOS must wait for the BMC to initialze before performing certain tasks, such as spinning up the CPU fan to prevent the CPU from overheating quickly once it is activated.

On some older motherboard designs, the BIOS and BMC have independent connections to the fan controller. When this is the case, the BMC has no awareness of when the BIOS is sending instructions to the fan controller. The advantage of this design is the BIOS has immediate access to controlling the fans, and does not need to wait for the BMC to initialize first. This is one reason why older motherboards tend to boot faster than newer boards as the CPU and other components may be activated sooner.

### BIOS Directly Connected to Fan Controller
This process is less common, but may be found on older server motherboards. The BIOS is directly linked to the fan controller. This means when the BIOS wishes to set fan speeds, the BMC is bypassed completely. BIOS-based fan algorithms are based on temperature sensor readings. These temperature sensors are hardware sensors inside the server chassis or (more likely) on the motherboard itself.

Once the higher level operating system is active, this scenario can create confusion when the operating system which the user interacts with attempts to control the fan speeds. If the BIOS is continuing to monitor fan speeds, it may attempt to intervene and force fan speed changes when it detects a condition outside of the parameters it expects. This typically involves thermal sensors on the motherboard that are monitored by the BIOS. When the BIOS detects an anomaly, it reacts by prompting the fan controller to modify the fan speeds. When this occurs, the BMC is unaware of what the BIOS is up to, and is potentially unaware of the fan speed changes imposed by the BIOS.

> [!Note]
> This guide is not going to get into great detail figuring out why the BIOS may be ramping fans up higher. For example, the underlying cause may be a bad temperature sensor or a bad part on the motherboard. This guide is solely focused on diagnosing and discussing potential mitigation of what is taking control of your fans? There may be another deeper layer to discover which pertains to why something is trying to control the fans in an unexpcted way, but deep-diving into that realm is not part of this article nor this overall guide.

## Diagnosing the Cause
Having explained the possible backdrop above, now it's time to figure out which situation you're in if you are experiencing the 'ramp down, ramp up, repeat' fan speed and noise process that is so annoying. To be more specific, this is the scenario I'm referring to:
1. User boots system
2. System powers up normally, starts fans at boot-up default setting
3. BIOS and BMC initialize the system, fans may change to post-boot default state
4. Operating system initializes, and fans are still running in post-boot default state (no change)
5. User manually or via installed program sets fans to a lower speed (quieter)
6. A short time passes, fan speeds ramp up without user intervention (louder)
7. User manually or via installed program sets fans to a lower speed (quieter)
8. A short time passes, fan speeds ramp up without user intervention (louder)
9. Repeat steps 5-6 over and over or give up and live with louder fans

Even if it is possible to set fan speeds manually via the BMC on such motherboards, the user's IPMI command is overwritten after a few seconds. Why?

As mentioned in the beginning of this article, there are only three (3) possible reasons why this happens:
1. BIOS overwriting user's fan speed commands
2. User's commands cause fan speeds to exceed fan speed threshold limits
3. Another program trying to control fan speeds manually at the same time

Let's examine each scenario, how to identify when it is occurring, and how to defeat it.

### Scenario 1: BIOS Usurping Control
This can happen under one of two circumstances. The first is that the BIOS has a direct connection to the fan controller. If this is the case, the only way to defeat the problem - if it is possible to do so - is to disable or modify the BIOS algorithms sending messages to the fan controller. This is the most difficult scenario to defeat.

Digging deeper, you have two (2) possible paths to a resolution:
1. BIOS has user-controllable switches that you can manipulate, which cause the BIOS to stop taking control of the fans constantly.
2. There isn't such a user-accessible capability in the BIOS user interface.

#### Scenario 1A: User-Controllable BIOS Settings
What you want to do here is examine your options. Can you simply turn off the BIOS control over system fans? That's very unlikely, but if you find that option, then obviously take it. What is more likely is that you may be able to manipulate the trigger conditions the BIOS uses to make decisions on when it intervenes to control the fans. This is typically a set of basic algorithms tied to temperature sensors, such as when sensor X goes above temperature Y then set fans to speed percentage Z.

Locate the algorithm settings and adjust the temperature triggers so they are as high as possible, that you are comfortable with. The idea here is to stop the BIOS from being overbearing with controlling the fans. However, depending on your use case you might want to leave some of them intact and set the trigger temps to something you find reasonable for your system. If you are planning to utilize a software-based fan controller that you control in the main operating system, so long as that software will monitor system temperatures and make prudent fan speed adjustments as necessary, then you should be safe to effectively disable them here in the BIOS to the extent that you can.

#### Scenario 1B: No User Control over BIOS Fan Speed Settings
So, you find yourself in the unenviable scenario where the BIOS seems to be hard-wired to the fan controller, and you can find no user-configurable settings in the BIOS user interface. Well, unfortunately this is the worst-case scneario. If you choose to force the server into submission, you will be dealing with a constant race condition.

Frankly, your options are very limited. They boil down to two (2) possible approaches:
1. Give up and do not use a software based fan controller. If the BIOS has settings for a fan mode, look for one labeled "acoustic," "optimal," or something similar. This should reduce overall fan noise dramatically, though it may not quiet the server enough for some Home Lab use cases. However, frankly this is all you've got to work with (or use a different motherboard/server).
2. Setup your software-driven fan controller with a very short timer. You will need a program that runs constantly in the background, and which will automatically issue fan speed commands on regular intervals. You will probably need to set an interval of about two (2) seconds at the most, and the program will need to be designed to favor automatically issuing a command every interval to set the fan speeds. This is going to seem very redundant when the server environment has not changed from the previous interval, but it is the only way to counter-act the signals the BIOS will be sending constantly, as it tries to override what you're doing.

### Scenario 2: Fan Behavior Triggering BMC Thresholds
One of the functions of the BMC in terms of fan control involves the contant monitoring of physical fan speeds (RPMs). Every fan has a tachometer that reports its current rotational speed in RPMs (Revolutions Per Minute). The BMC will have a table of outlier fan speeds. When a fan's rotational speed exceeds a threshold, an action may be taken, depending on the circumstance. More information regarding what these thresholds are, how they function, and how to alter them may be found [here](bmc-fan-speed-thresholds.md).

#### How do you know when this is the scenario you're dealing with?
All of your fans will suddenly ramp up to full speed for what seems like no reason. There won't be an associated spike in temperature of the CPU(s) or other temp sensors inside the server chassis. The fans will spontaneiously increase to full power for apparently no reason. This is usually a sign there is something wrong perceived with one or more fans, as they are operating outside the normal range of physical fan speeds expected by the BMC of one or more fans.

#### What is the solution?
1. Determine why this is happening
2. Review the guide information in [BMC Fan Speed Thresholds](bmc-fan-speed-thresholds.md)
3. When the root cause is not caused by a fan defect, determine the appropriate IPMI commands to modify your fan speed thresholds in the BMC to position them outside the normal operating range of your fans
4. Execute the IPMI commands to modify the BMC fan speed thresholds
5. Wait to see if the problem recurs (if it does, repeat this process with more aggressive modifications to the fan speed thresholds)

### Scenario 3: Competing Fan Controllers
When you've ruled out the first and second scenarios, the only other possibility is that there is another process competing with your software-based fan controller. You'll have to go on a fishing expedition to find it and then determine how you want to handle the situation. I recommend you look for cron jobs and systemd daemon services that could be running and impacting fan speeds. These are usually where you'll find the culprit as both can be designed to run at intervals and in the background.
