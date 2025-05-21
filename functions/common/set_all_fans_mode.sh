# set fan mode (all fans auto, optimal, full modes)
function set_all_fans_mode ()
{
	local fan_id
	local mode
	local zone_id

	local -a fan_array
	local -a zone_array

	mode="$1" # fan control mode
	debug_print 1 bold "Set fan mode: ${mode^^}"

	case "$mode" in # 1/
		full)
			case "$mobo_manufacturer" in # 2/ segment manufacturer specific special handling
				dell|hpe|nec)
					case "$bmc_command_schema" in # 3/
						dell-v1|hpe-v1|nec-v1)
							run_command "$ipmitool raw 0x30 0x30 0x02 0xff 0xff"
						;;
					esac # 3/
				;;

				supermicro)
					# supermicro is a special case because it has built-in full fan mode
					case "$bmc_command_schema" in # 3/
						supermicro-v1|supermicro-v2)
							debug_print 2 "Activating Supermicro FULL fan speed operating mode"
							run_command "$ipmitool raw 0x30 0x45 0x01 0x01"
						;;
					esac # 3/
				;;

				*)
					case "$fan_control_method" in # 3/ hand-off other motherboards to standard fan speed execution subroutine sub-branched via fan control method
						direct)
							convert_binary_to_array "${fan_header_binary[master]}" "fan_array" # all fan headers regardless of state
							for fan_id in "${!fan_array[@]}"; do # 1/ process each fan header
								query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude" && continue # skip excluded fan headers

								# substitute write position for fan id when known
								[ -n "${ipmi_fan_id_write_position[$fan_id]}" ] && fan_id="${ipmi_fan_id_write_position[$fan_id]}"

								execute_ipmi_fan_payload "$fan_duty_limit" "$fan_id"
							done # 1/
						;;

						group)
							compile_group_duty_cycle_payload "all" "$fan_duty_limit"
							execute_ipmi_fan_payload
						;;

						universal)
							execute_ipmi_fan_payload "$fan_duty_limit"
						;;

						zone)
							convert_binary_to_array "${fan_zone_binary[master]}" "zone_array" # all fan zones regardless of state
							for zone_id in "${!zone_array[@]}"; do # 1/ process each fan zone
								execute_ipmi_fan_payload "$fan_duty_limit" "$zone_id"
							done # 1/
						;;

						*)
							debug_print 1 critical "Failed to set fan mode (FULL) for an unknown reason" true
							debug_print 2 critical "Unrecognized fan control method: $fan_control_method" true
						;;
					esac # 3/
				;;
			esac # 2/
		;;

		##
		# Set fans to auto or optimal mode on motherboards that support it.
		# Use arbitrary 30% target for those that do not.
		#
		# 'Optimal' fan speed mode may refer to a particular fan mode called optimal
		# or it may refer to automatic fan controls, depending the motherboard
		# manufacturer features and nomenclature.
		##

		optimal)
			case "$mobo_manufacturer" in # 2/
				asus) # experimental
					debug_print 4 caution "Asus fan control support is experimental"

					case "$bmc_command_schema" in # 3/
						asus-v1)
							# enable automatic fan speed control
							# {NetFn} {Fan control} {auto mode feature} {turn auto mode on}
							run_command "$ipmitool raw 0x30 0x30 0x01 0x01"
						;;

						asus-v2|asus-v3)
							# enable automatic fan speed control
							# {NetFn} {Fan control} {auto mode feature} {turn auto mode on}
							run_command "$ipmitool raw 0x30 0x70 0x66 0x00"
						;;

						*)
							debug_print 2 warn "Unrecognized fan mode; no changes were made" true
						;;
					esac # 3/
				;;

				dell|hpe|nec)
					case "$bmc_command_schema" in # 3/
						dell-v1|hpe-v1|nec-v1)
							# enable automatic fan speed control
							run_command "$ipmitool raw 0x30 0x30 0x01 0x01"

							if (( mobo_gen == 3 )); then # 1/ PowerEdge gen 13 servers (circa 2014) with 3rd party fan controller

								# enable 3rd-party PCIe card default cooling response logic
								run_command "$ipmitool raw 0x30 0xce 0x00 0x16 0x05 0x00 0x00 0x00 0x05 0x00 0x00 0x00 0x00"
								debug_print 4 caution "Attempt to enable 3rd party peripheral fan auto speed"
							fi # 1/
						;;

						*)
							debug_print 1 critical "${mobo_manufacturer^} BMC command schema not recognized"
						;;
					esac # 3/
				;;

				gigabyte)
					case "$bmc_command_schema" in # 3/
						gigabyte-ast2500-v1)
							# activate auto fan mode
							run_command "$ipmitool raw 0x2e 0x10 0x0a 0x3c 0x00 0x40 0x00"
						;;

						gigabyte-ast2500-v2)
							convert_binary_to_array "${fan_header_binary[master]}" "fan_array"
							for fan_id in "${!fan_array[@]}"; do # 1/ force 30% fan speed for each fan
								! query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude" && execute_ipmi_fan_payload 30 "$fan_id" # skip excluded fan headers
							done # 1/
						;;


						*)
							debug_print 2 warn "Unrecognized fan mode; no changes were made" true
						;;

					esac # 3/
				;;

				# supermicro is a special case because it has built-in full fan mode
				supermicro)
					case "$bmc_command_schema" in # 3/
						supermicro-v1|supermicro-v2)
							debug_print 2 "Activate Supermicro built-in OPTIMAL fan speed operating mode"

							# fan mode = 2
							run_command "$ipmitool raw 0x30 0x45 0x01 0x02"
						;;
					esac # 3/
				;;

				*)
					case "$fan_control_method" in # 2/ hand-off other motherboards to standard fan speed execution subroutine sub-branched via fan control method
						direct)
							convert_binary_to_array "${fan_header_binary[master]}" "fan_array" # all fan headers regardless of state

							for fan_id in "${!fan_array[@]}"; do # 1/ process each fan header
								query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude" && continue # skip excluded fan headers

								# substitute write position for fan id when exists
								[ -n "${ipmi_fan_id_write_position[$fan_id]}" ] && fan_id="${ipmi_fan_id_write_position[$fan_id]}"

								execute_ipmi_fan_payload 30 "$fan_id"
							done # 1/
						;;

						group)
							compile_group_duty_cycle_payload "all" 30
							execute_ipmi_fan_payload
						;;

						universal)
							execute_ipmi_fan_payload 30
						;;

						zone)
							convert_binary_to_array "${fan_zone_binary[master]}" "zone_array" # all fan zones regardless of state
							for zone_id in "${!zone_array[@]}"; do # 1/ process each fan zone
								execute_ipmi_fan_payload 30 "$zone_id"
							done # 1/
						;;

						*)
							debug_print 1 critical "Failed to set fan mode (OPTIMAL) for an unknown reason" true
							debug_print 2 critical "Unrecognized fan control method: $fan_control_method" true
						;;
					esac # 3/
				;;
			esac # 2/
		;;

		*)
			debug_print 1 warn "Unrecognized fan mode; no changes were made" true
		;;
	esac # 1/
}
