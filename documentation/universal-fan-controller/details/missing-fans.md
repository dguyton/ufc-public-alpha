# Missing or Inactive Fans at Start-up
The situation gets slightly complex when a fan is acting up or not responding on system start-up.

The Launcher will attempt to activate all fans it thinks are active (based on what the Builder told it), validate the fan group arrangement, and make the first metadata polling of all fans. When it launches the Runtime program, the Launcher will pass all of this information to it. Thus, the Runtime starts off with pre-determined expectations of:
- The list of active fan headers
- Initial states of _all_ fan headers (including inactive ones)

When a fan header tagged as active is flat-out missing or dead, it will take the Runtime script a couple of fan validation cycles to determine there is definitely a problem. The offending fan header will be marked [suspicious](/documentation/universal-fan-controller/suspicious-fans.md) and flagged for further monitoring and analysis. If the problem with the fan does not rectify itself fairly quickly, it will be marked bad and taken out of service.

Disqualified fans may be reported to the end user via email messages, program logs, JSON logs, and possibly syslog. Which occur (if any) will depend on how the user configured these settings in the Bulider's configuration file. If a particular fan appears to be a repeat offender on server restarts, the user should take note and investigate further. If the user intends to take the fan out of service permanently or to replace it, they must re-run the Builder in order to pickup the changes. This will prevent nuisance notifications.
