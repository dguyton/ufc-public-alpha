##
# Some motherboards require their Fan Mode to be set in a particular fashion
# before it is possible to manually control their fan speeds.
##

# enable manual fan control for boards that require it to be set explicitly
function enable_manual_fan_control ()
{
	debug_print 4 "Configure motherboard for manual fan speed control"

	case "$mobo_manufacturer" in # 1/
		asrock)
			# group fan control method is presumed
			local -a fan_array
			local ipmi_command_payload

			case "$bmc_command_schema" in # 2/
				asrock-ast2500-v2|asrock-ast2500-v3|asrock-ast2500-v4|asrock-ast2500-v5|asrock-ast2500-v6|asrock-ast2500-v8|asrock-ast2500-v9|asrock-ast2500-v10|asrock-ast2500-v11|asrock-ast2500-v12|asrock-ast2500-v13|asrock-ast2500-v14|asrock-ast2600-v1)

					##
					# Enable manual fan control.
					# Write to all 16 fan header ids simultaneously.
					##

					ipmi_command_payload="$ipmitool raw 0x3a 0xd8"

					if binary_is_empty "$exclude_fan_header_binary"; then # 1/ no fan headers are excluded
						ipmi_command_payload+=" 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01 0x01" # enable manual control for all fan headers
					else # 1/ properly tag excluded vs. manually controlled fan headers

						##
						# Segment any excluded fan headers, and set their fan speed
						# to automatic mode. These fans are excluded from monitoring
						# and reporting. This step ensures the fans will be managed
						# by the BIOS.
						##

						##
						# Tag all excluded fans for automation. This function call is intended for group
						# fan control method only.
						#
						# Populate $fan_array[] array with enable (0x00) or disable (0x01) automatic fan
						# control bytes for each fan header.
						##

						automate_excluded_fans "fan_array" "0x00" "0x01" 16 # force 16 data byte payload regardless of actual fan binary string length

						for fan_id in "${!fan_array[@]}"; do # 1/
							ipmi_command_payload+=" ${fan_array[$fan_id]}"
						done # 1/
					fi # 1/

					run_command "$ipmi_command_payload"
				;;
			esac # 2/
		;;

		asus)
			# Asus requires disabling manual control before sending fan speed commands

			debug_print 4 caution "Asus fan control support is experimental"

			case "$bmc_command_schema" in # 2/
				asus-v1)
					# set manual mode
					# {NetFn} {Fan control} {auto mode feature} {turn auto mode off}
					$ipmitool raw 0x30 0x30 0x01 0x00
				;;

				asus-v3)
					# disable automatic fan speed control for all fans
					$ipmitool raw 0x30 0x70 0x66 0x01
				;;
			esac # 2/
		;;

		dell|hpe)
			case "$bmc_command_schema" in # 2/
				dell-v1|hpe-v1)
					run_command "$ipmitool raw 0x30 0x30 0x01 0x00"

					if (( mobo_gen == 3 )); then # 1/ PowerEdge gen 13 servers (circa 2014) with 3rd party fan controller
						run_command "$ipmitool raw 0x30 0xce 0x00 0x16 0x05 0x00 0x00 0x00 0x05 0x00 0x01 0x00 0x00"
						debug_print 4 caution "Attempt to disable 3rd party peripheral fan auto speed"
					fi # 1/

					##
					# When all fans are assigned to the same type of fan cooling duty,
					# ensure all fans have their fan speed set at the same time. Most
					# Dell motherboards allow both individual and group fan speed control.
					#
					# This change makes IPMI fan speed commands more efficient.
					##

					if [ "$only_cpu_fans" = true ] && [ "$fan_control_method" != "universal" ]; then # 1/
						debug_print 4 "Modified fan control method from '${fan_control_method}' to 'universal' because all fans are assigned to CPU fan cooling"
						fan_control_method="universal"
					fi # 1/
				;;
			esac # 2/
		;;

		nec)
			case "$bmc_command_schema" in # 2/
				nec-v1)
					run_command "$ipmitool raw 0x30 0x30 0x01 0x00"
				;;
			esac # 2/
		;;

		supermicro)
			case "$bmc_command_schema" in # 2/
				supermicro-v1|supermicro-v2|supermicro-v3)
					# supermicro is a special case because it has built-in full fan mode
					set_all_fans_mode full
					return
				;;
			esac # 2/
		;;

		*)
			debug_print 4 caution "Configure motherboard for manual fan speed control: no known process"
		;;
	esac # 1/
}
