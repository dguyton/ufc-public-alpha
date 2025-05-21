##
# Compile IPMI fan duty command(s).
#
# Called by execute_ipmi_fan_payload subroutine.
#
# Required Arguments
# 	- Direct fan control method    : fan duty cycle, fan ID
# 	- Group fan control method     : CPU fan duty cycle, device fan duty cycle
# 	- Universal fan control method : fan duty cycle
# 	- Zone fan control method      : fan duty cycle, zone ID
##

function compile_ipmi_fan_payload ()
{
	local fan_category			# fan cooling type (e.g. cpu, device)
	local fan_duty_hex
	local index

	local -n ipmi_payload="$1"	# IPMI command payload construction ($ipmi_command_payload)
	local -n target_fan="$2"		# target fan header id or zone id ($target)
	local -n target_fan_duty="$3"	# $fan_duty

<<>>

--> vendor-specific code function

--> it will need inputs of: 
	--> indirect management of var name ipmi_command_payload
	--> input values of $fan_duty, $target
	--> indirectly work with $target as it might be modified below
	--> move $fan_duty_hex calc and local var use to new sub (not needed in execute_ipmi_fan_payload)
	--> all other mentioned vars are or should be global


--> inputs needed here: fan_duty (fan_duty), target (target)
--> need to calculate here: fan_duty_hex, ipmi_payload (ipmi_command_payload)

	##
	# There are many iterations of ASRock motherboard IPMI command schemas. They differ
	# based on various characteristics, but are largely related to a combination of BMC
	# chip generation and motherboard generation.
	##

	# build raw command line based on manufacturer and model specifics
	case "$mobo_manufacturer" in # 1/

		asrock)

			##
			# There are many iterations of ASRock motherboard IPMI command schemas. They differ
			# based on various characteristics, but are largely related to a combination of BMC
			# chip generation and motherboard generation.
			#
			# When this subroutine was built, ASRock boards only supported the Group method of
			# fan control. Therefore, there is no additional filtering for each BMC schema based
			# on fan control method, as seen with nearly all other manufcturers below.
			##

			case "$bmc_command_schema" in # 2/ only group method is supported

				asrock-ast2300-v1)
					# unique fan management process is a blend between Group and Zone methods
					# requires 2x command lines with 8-byte payloads
					# part 1: ipmitool raw 0x3a 0x01 {cpu_1 override} {CPU_FAN1_1} {REAR_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3}
					# part 2: ipmitool raw 0x3a 0x11 {cpu_2 override} {CPU_FAN2_1} {REAR_FAN2} {FRNT_FAN4} {dummy byte} {dummy byte}

					if (( ${#ipmi_group_fan_payload[@]} != 12 )); then # 1/
						debug_print 2 critical "IPMI data payload has an insufficient number of bytes in its data payload" true
						return 1
					fi # 1/

					# convert combined data payload values to hex before splitting
					convert_array_to_hex "ipmi_group_fan_payload"

					# prep first command line
					ipmi_payload="$ipmitool raw 0x3a 0x01"

					# compile remainder of 1st command line by appending first portion of data payload
					for (( index=0; index<6; index++ )); do # 1/ get first 6 bytes
						ipmi_payload+=" ${ipmi_group_fan_payload[$index]}"
					done # 1/

					# execute prepared ipmi command
					debug_print 4 "Execute IPMI command payload request, part 1 of 2: '${ipmi_payload}'"

					if ! run_command "$ipmi_payload"; then # 1/ execute 1st command line
						debug_print 4 warn "1st fan group IPMI payload execution attempt failed" true
						return 1
					fi # 1/

					# prep 2nd command line
					ipmi_payload="$ipmitool raw 0x3a 0x11"

					# compile remainder of 2nd command line by appending second portion of data payload
					for (( index=6; index<12; index++ )); do # 1/ process remaining write position indeces 6-11 (6 bytes)
						ipmi_payload+=" ${ipmi_group_fan_payload[$index]}"
					done # 1/

					# execute prepared ipmi command
					debug_print 4 "Execute IPMI command payload request, part 2 of 2: '${ipmi_payload}'"

					# when successful, return without error, but with IPMI command var empty so that caller knows no further steps are needed
					if run_command "$ipmi_payload"; then # 1/ execute 2nd command line
						unset ipmi_payload
						return 0 # exit after 2nd command is executed
					else # 1/
						debug_print 4 warn "2nd fan group IPMI payload execution attempt failed" true
						return 1
					fi # 1/
				;;

				asrock-ast2300-v2)
					# ipmitool raw 0x3a 0x01 {CPU_FAN1} {CPU_FAN2} {REAR_FAN1} {REAR_FAN2} {FRNT_FAN1} {FRNT_FAN2} {dummy byte} {dummy byte}
					ipmi_payload="0x3a 0x01"
				;;

				asrock-ast2300-v3)
					# ipmitool raw 0x3a 0x01 {CPU_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {FRNT_FAN4} {FRNT_FAN5}
					ipmi_payload="0x3a 0x01"
				;;

				asrock-ast2300-v4)
					# ipmitool raw 0x3a 0x01 {CPU_FAN1} {dummy byte} {REAR_FAN1} {dummy byte} {FRNT_FAN1} {dummy byte} {dummy byte} {dummy byte}
					ipmi_payload="0x3a 0x01"
				;;

				asrock-ast2400-v1)
					# ipmitool raw 0x3a 0x01 {CPU1_FAN1} {REAR_FAN1} {FRNT_FAN1} {5x dummy bytes}
					# ipmi_payload="0x3a 0x01 ${ipmi_fan_order_cpu[1]} ${ipmi_fan_order_rear[1]} ${ipmi_fan_order_front[1]} 0x00 0x00 0x00 0x00 0x00"
					ipmi_payload="0x3a 0x01"
				;;

				asrock-ast2500-v1)
					# ipmitool raw 0x3a 0x01 {CPU1_FAN1} {CPU2_FAN1} {REAR_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {FRNT_FAN4} {dummy byte}
					ipmi_payload="0x3a 0x01"
				;;

				asrock-ast2500-v2)
					# ipmitool raw 0x3a 0xd6 {CPU_FAN1} {FRNT_FAN1} {FRNT_FAN2} {13x dummy bytes}
					ipmi_payload="0x3a 0xd6"
				;;

				asrock-ast2500-v3|asrock-ast2500-v5)
					# ipmitool raw 0x3a 0xd6 {CPU_FAN1} {SYSTEM_FAN1} {SYSTEM_FAN2} {SYSTEM_FAN3} {SYSTEM_FAN4} {SYSTEM_FAN5} {10x dummy bytes}
					ipmi_payload="0x3a 0xd6"
				;;

				asrock-ast2500-v4)
					# ipmitool raw 0x3a 0x01 {CPU_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {REAR_FAN1} {REAR_FAN2} {10x dummy bytes}
					ipmi_payload="0x3a 0x01"
				;;

				asrock-ast2500-v6)
					# ipmitool raw 0x3a 0x01 {CPU1_FAN1} {cpu override} {REAR_FAN1} {REAR_FAN2} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {FRNT_FAN4}
					ipmi_payload="0x3a 0x01"
				;;

				asrock-ast2500-v7)
					# ipmitool raw 0x3a 0x01 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {2x dummy bytes}
					ipmi_payload="0x3a 0x01"
				;;

				asrock-ast2500-v8|asrock-ast2500-v9|asrock-ast2500-v13)
					# ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {10x dummy bytes}
					ipmi_payload="0x3a 0xd6"
				;;

				asrock-ast2500-v10)
					# ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {12x dummy bytes}
					ipmi_payload="0x3a 0xd6"
				;;

				asrock-ast2500-v11)
					# ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {13x dummy bytes}
					ipmi_payload="0x3a 0xd6"
				;;

				asrock-ast2500-v12|asrock-ast2600-v1)
					# ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {FAN7} {9x dummy bytes}
					ipmi_payload="0x3a 0xd6"
				;;

				asrock-ast2500-v14)
					# ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {FAN7} {FAN8} {8x dummy bytes}
					ipmi_payload="0x3a 0xd6"
				;;

			esac # 2/
		;;

		asus)
			# Asus schema v1 supports direct (individual fan) and universal (all fans) control methods
			# Asus schema v2 supports zoned fan control method only
			# Asus schema v3 supports the group control method only

			case "$bmc_command_schema" in # 2/

				asus-v1)

					# dual mode: direct or universal
					case "$fan_control_method" in # 3/

						direct)
							# convert specified fan header id to hex
							debug_print 4 "Compile direct mode IPMI command"
						;;

						universal)
							# universal mode (action all fans together)
							target="0xff"
						;;

						*)
							# force return empty $ipmi_payload to trigger failure condition
							return 1
						;;

					esac # 3/

					# ipmitool raw 0x30 0x30 {mode: set = 0x02} {fan_id} {duty 0-100}
					ipmi_payload="0x30 0x30 0x02 $target $fan_duty_hex"
				;;

				asus-v2)

					case "$fan_control_method" in # 3/

						zone)
							# 0x30 0x70 0x66 0x0<Zone ID> <Duty Cycle>
							ipmi_payload="0x30 0x70 0x66 0x1${target} $fan_duty_hex"
						;;

					esac # 3/
				;;

				asus-v3)
					# prep first command line (group method)
					ipmi_payload="$ipmitool raw 0x30 0x05 0x01"
				;;

			esac # 2/
		;;

		dell|hpe|nec)

			case "$bmc_command_schema" in # 2/

				dell-v1|hpe-v1|nec-v1)

					# dual mode: direct or universal
					case "$fan_control_method" in # 3/

						direct)
							# convert specified fan header id to hex
							debug_print 4 "Compile direct mode IPMI command"
						;;

						universal)
							# universal mode (action all fans together)
							target="0xff"
						;;

						*)
							unset ipmi_payload
						;;
					esac # 3/

					# ipmitool raw 0x30 0x30 {mode: set = 0x02} {fan_id} {duty 0-100}
					ipmi_payload="0x30 0x30 0x02 $target $fan_duty_hex"
				;;

				*)
					unset ipmi_payload
				;;

			esac # 2/
		;;

		gigabyte)

			case "$bmc_command_schema" in # 2/

				gigabyte-ast2500-v1)

					##
					# Aspeed AST2500 with Redfish middleware
					# dual mode: direct or universal
					# duty range 0 - ff ( 0 - 100% PWM )
					##

					case "$fan_control_method" in # 3/

						direct) # set speed for a specific fan header
							# convert specified fan header id to hex
							debug_print 4 "Compile direct mode IPMI command"
						;;

						universal)
							target="0xff" # action all fans together
						;;

						*)
							unset ipmi_payload
						;;

					esac # 3/

					# legacy conversion method is required
					fan_duty_hex="$(printf "%.0f" "$(awk "BEGIN { print ( int( $target_fan_duty / 100 ) * 255 ) }")")" # convert range % to range 0-255

					# ipmitool raw 0x2e 0x10 0x0a 0x3c 0 64 <1 = disable auto mode> <Duty> <Fan ID>
					ipmi_payload="0x2e 0x10 0x0a 0x3c 0x00 0x40 0x01 $fan_duty_hex $target"
				;;

				gigabyte-ast2500-v2)

					case "$fan_control_method" in # 3/ only direct mode is supported

						direct)

							##
							# Presumes only cpu fan group exists.
							# Fans are controlled by pre-set CPU temperature settings.
							#
							# Device fan PID control not supported for these boards, because
							# this unusual BMC method uses three (3) independent temperature control
							# thresholds to set fan duty cycles.
							##

							if ! query_ordinal_in_binary "$target" "fan_header_active_binary" "master"; then # 2/ fan header not active
								debug_print 3 warn "Received fan speed change request for fan '${fan_header_name[$target]}, but it is inactive"
								return 1
							fi # 2/

<<>>

--> need to refactor to:
	--> 1. know fan category type
	--> 2. lookup correct fan duty low value, if relevant


							# target is a fan header id and active
							if [ "$fan_category" = "cpu" ]; then # 2/ active cpu fan
								if [ "$cpu_fan_control" != true ]; then # 3/
									debug_print 4 caution "Received fan speed change request for CPU fan, but CPU fan control is disabled"
									return 1
								fi # 3/

								# raw 0x3c 0x16 0x02 {fan_id} {duty 1} {duty 2} {duty 3} {temp 1} {temp 2} {temp 3}
								ipmi_payload="0x3c 0x16 0x02 $target $(printf "0x%x" "${fan_duty_low[cpu]}"}) $(printf "0x%x" "$cpu_fan_duty_med") $(printf "0x%x" "$cpu_fan_duty_high") $(printf "0x%x" "$cpu_temp_low") $(printf "0x%x" "$cpu_temp_med") $(printf "0x%x" "$cpu_temp_high")"

							else # 2/ non-cpu fan

								# raw 0x3c 0x16 0x02 {fan_id} {duty 1} {duty 2} {duty 3} {temp 1} {temp 2} {temp 3}
								ipmi_payload="0x3c 0x16 0x02 $target $(printf "0x%x" "$device_fan_duty_low") $(printf "0x%x" "$device_fan_duty_med") $(printf "0x%x" "$device_fan_duty_high") $(printf "0x%x" "$device_temp_low") $(printf "0x%x" "$device_temp_med") $(printf "0x%x" "$device_temp_high")"
							fi # 2/
						;;

						*)
							unset ipmi_payload
						;;
					esac # 3/
				;;
			esac # 2/
		;;

		ibm|lenovo)

			case "$bmc_command_schema" in # 2/

				ibm-v1|lenovo-v1)

					case "$fan_control_method" in # 3/ only direct mode is supported

						direct)

							##
							# ipmitool raw 0x3a 0x07 {fan_id} {speed} {fan_override}
							# fan_id = 0x01, 0x02, 0x03
							# speed = 0x00 - 0xff
							# override auto; on = 0x01 ; off (ignore speed command) = 0x00
							##

<<>>

--> possibly refactor dummy bytes based on new reserved words array for this purpose


							# check whether current fan id is CPU fan, in order to determine whether or not override flag is also be required
							if [ "$fan_category" = "cpu" ] && [ "$cpu_fan_control" = true ]; then # 1/
								cpu_fan_override="0x01" # enable cpu override (overrides automatic cpu fan mode)
							else # 1/ do not override
								cpu_fan_override="0x00" # disable cpu override (set cpu related fan to automatic mode)
							fi # 1/

							# legacy conversion method required - convert fan duty decimal % to hex range 0-255
							fan_duty_hex="$(printf "0x%x" "$(awk "BEGIN { print ( ( int( $target_fan_duty / 100 ) * 255 )) }")")"

							ipmi_payload="0x3a 0x07 $target $fan_duty_hex $cpu_fan_override"
						;;

					esac # 3/
				;;

			esac # 2/
		;;

		intel)

			case "$bmc_command_schema" in # 2/

				intel-v1)

					case "$fan_control_method" in # 3/ only universal mode is supported

						universal)
							# ipmitool raw 0x30 0x8c {fan duty 1-100}
							ipmi_payload="0x30 0x8c $fan_duty_hex" # set all fans to same speed 1-100
						;;

					esac # 3/
				;;

				intel-v2)

					# Intel pGFx BMC chip
					case "$fan_control_method" in # 3/ only universal mode is supported

						universal)
							# ipmitool raw 0x30 0x30 0x02 {fan duty 1-100}
							ipmi_payload="raw 0x30 0x30 0x02 $fan_duty_hex" # set all fans to same speed 1-100
						;;

						zone)
							# ipmitool 0x30 0x70 0x66 0x01 {fan zone ID} {fan duty 1-100}
							ipmi_payload="raw 0x30 0x70 0x66 0x01 0x0${target} $fan_duty_hex"
						;;

					esac # 3/
				;;

			esac # 2/
		;;

		quanta)

			case "$bmc_command_schema" in # 2/

				quanta-v1) # 1U variants

					case "$fan_control_method" in # 3/

						direct)
 							# set a single fan to specified fan duty
							ipmi_payload="0x30 0x39 0x01 0x01 $target $fan_duty_hex"
						;;

						universal)

							##
							# quanta-v1 universal mode 4th byte likely does not matter as long as
							# it is no-zero (i.e. 0x01 or 0x04) to enable 'universal' mode.
							# if [ -n "$log_filename" ], this has not been independently confirmed.
							#
							# Fan id 0x06 is the critical enabler (though it is also possible that
							# any non-existent fan id will work, but again, this is unproven).
							##

							ipmi_payload="0x30 0x39 0x01 0x04 0x06 $fan_duty_hex"
						;;

					esac # 3/
				;;

				quanta-v2) # 2U variants

					case "$fan_control_method" in # 3/ only direct mode is supported

						direct)
 							# set a single fan to specified fan duty
							ipmi_payload="0x30 0x39 0x01 0x00 $target $fan_duty_hex"
						;;

					esac # 3/
				;;
			esac # 2/
		;;

		supermicro)

			case "$bmc_command_schema" in # 2/ only zone mode is supported

				supermicro-v1)

					case "$fan_control_method" in # 3/

						zone)
							# X9 gen, Nuvoton BMC, requires legacy hex conversion 0x00 - 0xFF (100%)
							fan_duty_hex="$(printf "0x%x" "$(awk "BEGIN { print ( int( $ipmi_payload=() / 100 ) * 255 ) }")")" # convert range % to range 0-255

							case "$mobo_model" in # 4/ speicial mobo model handling

								X9DRIF)
									# X9 X9DRi-F only; differing raw command byte payload
									ipmi_payload="0x30 0x91 0x45 0x03 0x0${target} $fan_duty_hex"
								;;

								*)
									ipmi_payload="0x30 0x91 0x5A 0x03 0x1${target} $fan_duty_hex"
								;;

							esac # 4/
						;;

					esac # 3/
				;;

				supermicro-v2|supermicro-v3) # X10 and later motherboards use 0x0z format where z = zone number

					case "$fan_control_method" in # 3/

						zone)
							# X10+ gen, ASPEED AST2xxx, hex conversion 0x00 - 0x64 (100%)
							target="$(printf "0x%x" "$target")"
							ipmi_payload="0x30 0x70 0x66 0x01 $target $fan_duty_hex"
						;;

					esac # 3/
				;;

			esac # 2/
		;;

		tyan)

			case "$bmc_command_schema" in # 2/ only direct mode is supported

				tyan-v1)
					# Aspeed 2050 BMC
					# raw 0x2e 0x05 0xfd 0x19 0x00 <fan id> ＜0x00-0x64|0xfe|0xff>
					# last byte 0xfe = read data instead of write data
					# last byte 0xff = set fan to auto mode

					# ipmitool raw 0x2e 0x05 0xfd 0x19 0x00 {fan_id} {duty}

					case "$fan_control_method" in # 3/

						direct)
							ipmi_payload="0x2e 0x05 0xfd 0x19 0x00 $target $fan_duty_hex"
						;;

					esac # 3/
				;;

				tyan-v2)
					# Aspeed 2500 BMC
					# raw 0x2e 0x44 0xfd 0x19 0x00 <fan_id> 0x01 <fan_duty_cycle>
					# fan duty cycle 0-100 (0x00 - 0x64)
					# last byte 0xfe = read data instead of write data
					# last byte 0xff = set fan to auto mode

					case "$fan_control_method" in # 3/

						direct)
							ipmi_payload="0x2e 0x44 0xfd 0x19 0x00 $target 0x01 $fan_duty_hex"
						;;

					esac # 3/
				;;

				tyan-v3)

					# Intel pGFx BMC chip
					case "$fan_control_method" in # 3/ only universal mode is supported

						universal)
							# ipmitool raw 0x30 0x30 0x02 {fan duty 1-100}
							ipmi_payload="raw 0x30 0x30 0x02 $fan_duty_hex" # set all fans to same speed 1-100
						;;

						zone)
							# ipmitool 0x30 0x70 0x66 0x01 {fan zone ID} {fan duty 1-100}
							ipmi_payload="raw 0x30 0x70 0x66 0x01 0x0${target} $fan_duty_hex"
						;;

					esac # 3/
				;;

			esac # 2/
		;;

	esac # 1/

	##
	# $ipmi_payload only gets populated when it was successfully updated.
	# Therefore, when it is null, something went wrong with IPMI command creation
	# subroutine call.
	##

	if [ -z "$ipmi_payload" ]; then # 1/
		debug_print 4 critical "Something went wrong with IPMI command creation process" true
		return 1 # failure
	fi # 1/

	return 0 # success
}
