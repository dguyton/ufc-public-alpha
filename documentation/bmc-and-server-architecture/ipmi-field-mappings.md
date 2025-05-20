# IPMI Field Mappings
How to identify the field position of information in the IPMI sensor data output streams.

## Sensor Query
The **ipmitool** sensor query commands output data for all sensors monitored by IPMI. These lines then need to be filtered to screen out only the fan related sensor readings. From there, it is necessary to clarify which columns of these output lines contain particular pieces of data the program is interested in. The parameters below identify those field positions.

**ipmitool** has two separately available sensor reporting commands: _sensor_ and _sdr_

The output from these commands is slightly different, resulting in some shifts in column field position even reporting the same data. It is necessary to provide field mappings for both commands because the fan controller program utilizes both. In a nutshell, `ipmitool sensor` provides more information, but is considerably slower than the `ipmitool sdr` query. Thus, they are used for slightly different purposes, where the _sdr_ variant is typically used during runtime queries where minimizing system load is more important.

**Default parameters are modeled for Supermicro motherboards.**

You may need to experiment with running the related ipmitool commands manually on your server in order to identify the correct fields for your hardware. The default settings should work with all X9 and later generation Supermicro boards, but verfication of your particular hardware is strongly recommended prior to running the fan controller program.

To manually examine your motherboard's data output, use the following commands as a template for your own command line instructions to query this data:

>`sudo ipmitool sdr | grep -i fan`
>`sudo ipmitool sensor | grep -i fan`

Utilize the text output column isolating command of your choice to further filter the information and positively identify each relevant column number.

For example, you might create a short script similar to these.

ipmitool sdr:

	#!/bin/bash
	# parse each fan header reported by BMC
	ipmi_sensor_id_column=1
	while read -r fan_info; do
		fan_id="$(printf "%s" "$fan_info" | awk -v pos="$ipmi_sensor_id_column" '{print $(pos)}')"
		echo "$fan_id"
	done <<< "$(ipmitool sdr | grep -i fan)"

ipmitool sensor:

	#!/bin/bash
	# parse each fan header reported by BMC
	ipmi_sensor_id_column=1
	while read -r fan_info; do
		fan_id="$(printf "%s" "$fan_info" | awk -v pos="$ipmi_sensor_id_column" '{print $(pos)}')"
		echo "$fan_id"
	done <<< "$(ipmitool sensor | grep -i fan)"

## ipmitool SDR Output
These fields pertain to parsing the output from the `ipmitool sdr` command.

For each respective parameter, indicate the appropriate column number for each line of `sudo ipmitool sdr` output corresponding to the given data field.
