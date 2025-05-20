# Release Notes

Current version: 2.0 released April 2025

This article contains release notes for the current version only. The full release notes including archived version information is available [here](history.md).

## Changelog

### Version 2.0 (Universal Fan Controller) - April 2025

1. Completely overhauled architecture, pivoting to modular design
2. Removed manual mode from fan controller
3. Refined the Builder/Runtime architectural model introduced in version 1.1 further by splitting the Runtime concept into two (2) parts: a Launcher script and a smaller Runtime script to reduce the code footprint of the evergreen portion
4. Expanded use of configuration files
5. Enlarged scope to include over a dozen motherboard manufacturers
6. Enhanced anomaly detection
	1. Refined logic for automatic resolution of anomalous conditions
	2. Added additional validation checkpoints before beginning critical tasks
	3. Alert user to resolve non-sequitur issues via program log
	4. Exit gracefully and alert user when encountering non-recoverable error conditions
7. Split Service side core program
	1. Service Launcher: environmental calibration on system boot
	2. Service Runtime: continuous loop fan controller
8. Reduced Service Runtime footprint through design optimizations
9. Core program load only necessary functions
10. Manufacturer-specific parameters moved to separate config files
11. Streamlined configuration handling; loads only relevant parameters
12. Supportive functions migrated to libraries
13. Added traps to handle unexpected program exits
14. Added automated email alerts and program log updates on unexpected exits
15. Improved debug trace details for validation errors
16. Added self-validation (e.g. file manifest and inventory checks)
17. Enhanced Service recycling decision tree through more robust edge case filters
18. Startup self-validation for required components in both Builder and Service programs; fail gracefully when missing
19. New Failure Notification Handler daemon automatically trips when either Service program daemon fails
