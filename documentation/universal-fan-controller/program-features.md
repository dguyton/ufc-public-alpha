# What Makes the Universal Fan Controller (UFC) Unique?

There are a number of fan controller programs freely available online. What differentiates the Universal Fan Controller (UFC) from similar projects? The UFC stands out from other fan controller programs due to its innovative design, broad compatibility, and advanced features. Here's how:

## 1. Streamlined Program Design
- **Configuration File-Based Settings**: Users can easily adjust settings through a configuration file.
- **Modular Architecture**: Separates setup/configuration tasks from operational processes for better usability.

## 2. Extensive Hardware Support
- Compatible with a wide range of motherboards from multiple manufacturers.

## 3. Cross-Platform Compatibility
- Written in BaSH (Bourne Again SHell script) with high [POSIX](/documentation/details/posix-support.md) compliance, ensuring minimal dependencies.
- Tested on Ubuntu Server versions 16.04, 18.04, 20.04, and 22.04 (Debian-based).

## 4. Comprehensive Design for User Needs
- **Quiet Operation**: Prioritizes silent performance during normal conditions.
- **Fan State Validation**: Real-time detection of fan failures with automated fallback mechanisms.
- **Advanced Controls**:
  - Individual fan header control (on supported motherboards).
  - Multi-zone support for cooling (dependent on BMC).

## 5. Enhanced Features Beyond Competitors
- **Automatic Parameter Detection**:
  - Fan speed thresholds, hysteresis intervals, and min/max speed limits.
- **Proactive Monitoring**:
  - Detects unresponsive or failing fans and isolates them from active monitoring.
- **Email Alerts**: Notifies users of runtime failures or abnormal conditions.
- **Dynamic Adjustments**:
  - Adapts fan speeds based on CPU/chassis temperature changes.
  - Monitors and adjusts for disk array cooling needs, including hot-swap drives.

## 6. Robust Logging
- Logs include:
  - Syslog alerts.
  - Setup logs.
  - Time-constrained runtime logs.
  - JSON metadata export options.
- Features automatic log pruning to manage data efficiently.

## 7. Modular Design
- Core program functionality is separated by function:
  - Set-up and configuration
  - In-situ self-validation and runtime launcher
  - Implementation (runtime)
- Designed to simplify the process of adding certain types of new features
  - Additional motherboard manufacturers
  - Additional motherboard models for existing, supported manufacturers
  - New fan categories
