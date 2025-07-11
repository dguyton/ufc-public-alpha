# Frequently Asked Questions (F.A.Q.)

## 1. Must the Programs be Run as _root_?

Yes. Both the Builder (setup) and Service programs need to be run as the _root_ user.

This should occur by default when running the service program via a systemd daemon service. However, the builder program must be run explicitly as _root_, unless you wish to go to great lengths to it to be run by a non-root user. Some dependency programs (such as `ipmitool`) require _root_ access to enable their full capabilities.

## 2. Is My Motherboard Supported?

Please review the [hardware compatibility](/documentation/universal-fan-controller/supported-hardware-manufacturers.md) page.

Extensive research has been performed across all motherboard manufacturers. If your motherboard manufacturer or model are not supported, it is quite possible this is because manual fan control for it is not possible.

## 3. Which BMCs are Compatible with the Universal Fan Controller (UFC)?

You will find that information under [System Requirements and Constraints](/documentation/universal-fan-controller/system-requirements.md).

## 4. Is UFC Compatible with Windows?

No. Linux only.

## 5. I'm Not Receiving Email Messages

UFC sends emails rarely, and only via the Failure Notification Handler (FNH) add-on. If you have disabled the FNH, chose not to enable it in the first place, or if it's failing for some reason (check the Service Launcher program logs), then you won't receive emails informing you when the Service Launcher or Runtime programs fail.

## 6. My Server's Fans Are So Quiet, How Do I Know It's Working?

Your server fans should be nearly silent or as quiet as they can be when the system load is low and the heat generated by its hardware components is relatively low (CPUs, disk drives, and other components).

The exact sound volume of your fans depends on many factors, especially your particular fan models, the chassis design, your motherboard's capabilities, and the load placed on the server. The current state of the server is also a factor, as nearly all servers operate their fans differently during boot-up sequences versus after the operating system is loaded. And finally, some motherboards are not compatible. It is possible UFC is not compatible with your hardware. You may wish to check the [compatibility list](/documentation/universal-fan-controller/supported-hardware-manufacturers.md).

## 7. Why Are My Fans So Loud?

The exact sound volume of your fans depends on many factors, especially your particular fan models, the chassis design, your motherboard's capabilities, and the load placed on the server. The current state of the server is also a factor, as nearly all servers operate their fans differently during boot-up sequences versus after the operating system is loaded. And finally, some motherboards are not compatible. It is possible UFC is not compatible with your hardware. You may wish to check the compatibility list.

## 8. What Happens if it Doesn't Work?

Certain conditions will cause the main program to abort. If the conditions described below do not apply to you, perform the following troubleshooting steps:
1. Have you previously run the builder (setup) program? If not, do this first.
2. Check the status of the  service.
3. If you enabled Email Alerts in your configuration settings, check your email for messages from .
4. Reboot your server.

Even though it runs as a service file in the background, the process will abort and post a message in the system log (_syslog_) if any of the following catastrophic conditions occur:
- CPU fan zone has no active fans
- Disk Device fan zone previously had active fans, and they have all failed
- The service (runtime) program cannot load the init file (permissions error)
- The init file is not found by the runtime program
- No disk temperature reading application is available
- No IPMI reader is available
- One or more fan headers identify as belonging to an unknown fan zone ID
- Unsupported motherboard

## 9. How Do I Know It Will Work?

Have you tried installing it yet? You must run the _Builder_ first. The Builder is a setup and configuration utility that configures and installs the Service Launcher and Runtime daemons which run in the background.

## 10. Which Motherboards are Supported?
Please refer to [Supported Hardware Manufacturerers](/documentation/universal-fan-controller/supported-hardware-manufacturers.md).

## 11. What Programming Language is UFC Written In?
BaSH (SHell)

## 12. Does UFC Work with Every Motherboard and BMC Chipset?
No. It is not universally supported.

Please refer to [Environmental Constraints](/(/documentation/universal-fan-controller/md#environmental-constraints.md) and/or Supported Hardware Manufacturerers.
