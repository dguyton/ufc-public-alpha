# Graceful Exits
What is a "_graceful exit_?"

In UFC parlance, a _graceful exit_ refers to a program exit routed through a series of functions that attempts to perform various clean-up actions prior to exiting. These actions include activities such as:
- Logging the reason for the exit, such as adverse conditions.
- Triggering the [Failure Notification Handler](/documentation/universal-fan-controller/fnh.md).
- Closing out log files.
- Forcing all fan speeds to optimal or full speed modes.

The opposite of a graceful exit would be an unplanned exit, such as a program crash. Exit conditions related to `trap` conditions are not graceful.
