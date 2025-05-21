## Set upper fan thresholds in the BMC for the specified fan header
#
# The goal is to set the upper thresholds as high as possible to prevent high speed
# fans from triggering false positive alerts in the BMC, which may result in the BMC
# triggering fan panic mode. Only Supermicro X9/X10/X11 boards are supported at this
# time (X8/H11/H12 boards might work as well).
#
# These values get hard-coded and will survive server reboots and power cycles.
##

function set_upper_fan_thresholds ()
{
	local -a fan_array
	local fan_id

	# process upper limits for all fan headers regardless of status
	convert_binary_to_array "${fan_header_active_binary[master]}" "fan_array"

	if [ "$auto_bmc_fan_thresholds" != true ]; then # 1/
		debug_print 2 bold "Upper BMC fan thresholds not updated, because automatic configuration preference is disabled"
		debug_print 3 "Permanently apply new BMC upper fan speed thresholds"

		case "$mobo_manufacturer" in # 1/
			asrock|dell|gigabyte|hpe|ibm|intel|lenovo|quanta|supermicro|tyan)

				case "$bmc_command_schema" in # 2/ H13, H14, X13, X14 boards have limited lower threshold settings
					supermicro-v3)
						return 1 # nothing to do because these metrics do not exist for the current board
					;;
				esac # 2/

				for fan_id in "${!fan_array[@]}"; do # 1/ set each fan threshold independently when it exists
					query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude" && continue # skip any excluded fan headers not yet removed from active status

					if [ "${fan_speed_unr[$fan_id]}" -gt 0 ]; then # 2/
						debug_print 4 "Modifying UNR for fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) to ${fan_speed_unr[$fan_id]} RPM"
						run_command "$ipmitool sensor thresh ${fan_header_name[$fan_id]} unr ${fan_speed_unr[$fan_id]}" # write new fan speed threshold to BMC
					fi # 2/

					if [ "${fan_speed_ucr[$fan_id]}" -gt 0 ]; then # 2/
						debug_print 4 "Modifying UCR for fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) to ${fan_speed_ucr[$fan_id]} RPM"
						run_command "$ipmitool sensor thresh ${fan_header_name[$fan_id]} ucr ${fan_speed_ucr[$fan_id]}"
					fi # 2/

					if [ "${fan_speed_unc[$fan_id]}" -gt 0 ]; then # 2/
						debug_print 4 "Modifying UNC for fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) to ${fan_speed_unc[$fan_id]} RPM"
						run_command "$ipmitool sensor thresh ${fan_header_name[$fan_id]} unc ${fan_speed_unc[$fan_id]}"
					fi # 2/
				done # 1/
			;;

			*)
				debug_print 4 warn "No changes made to BMC Upper fan thresholds (unrecognized motherboard type)"
			;;
		esac # 1/
	fi # 1/

	##
	# Print a summary table with all results
	##

	# read current BMC threshold values from BMC to confirm changes occurred
	get_fan_info all verbose false

	if [ -n "$log_filename" ]; then # 1/ write data to log file
		{
			printf "\nUpper BMC fan threshold speeds (active fan headers only):"
			printf "\n------------------------------------------------"
			printf "\n|      Fan      |   UNC   |   UCR   |   UNR   |"
			printf "\n-----------------------------------------------"

			for fan_id in "${!fan_array[@]}"; do # 1/
				query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude" && continue # skip excluded fan headers
				printf "\n|  %11s  |  %5s  |  %5s  |  %5s  |" "${fan_header_name[$fan_id]}" "${fan_speed_unc[$fan_id]}" "${fan_speed_ucr[$fan_id]}" "${fan_speed_unr[$fan_id]}"
			done # 1/

			printf "\n|---------------------------------------------|\n"
		} >> "$log_filename"
	fi # 1/

	return 0 # success
}
