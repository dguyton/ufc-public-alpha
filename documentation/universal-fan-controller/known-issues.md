# Known Issues
Some circumstances are beyond the control of UFC because their possibility is too difficult to prognosticate, and/or defensive programming to detect and mitigate these circumstances is simply too daunting of a task, and the condition too rare, to warrant expending the time and resources on doing so.

For the most part, these 'known issues' are complications that are very unlikely to occur. Should you encounter one or more, you have two possible solution choices:
1. Do not consider UFC for your needs; or
2. Be willing to study the code and make adjustments where necessary to support your unique use case.

These conditions _should_ be rare, and you are unlikely to encounter them, however the risk is non-zero.

## Erratic IPMI `sensors` Behavior
The symptom of this issue is when polling the current environment of fans via the IPMI `sensors` command, the data dump returned by IPMI does not display in a consistent order.

### Why This is a Problem
The Builder takes a snapshot of IPMI fan sensor readings and builds UFC's master list of fan IDs from this initial output. This becomes the starting reference point to which fan metadata passed from the Builder will be compared. These data sets should match. If there is a discrepancy, it is a sign of one of two possible
causes:

1) something in the server environment has changed since the Builder was run; OR
2) there is an inconsistency with how IPMI is returning fan header information - particularly fan header order - meaning the order is random depending on when the IPMI command is run.

In theory, error scenario 2 should never occur. However, if it ever does, UFC is not designed to handle such an anomaly and will not fit this use case.
