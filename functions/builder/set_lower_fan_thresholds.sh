##
# Set lower BMC fan speed thresholds as low as possible to prevent
# slow fans from triggering false positive alerts in the BMC,
# which may result in the BMC triggering fan panic mode.
#
# Note: only Supermicro X9/X10/X11 boards are supported at this time
# (X8/H11/H12 boards may work as well).
##

function set_lower_fan_thresholds ()
{
	local fan_id
	local -a fan_array

	# process upper limits for all fan headers regardless of status
	convert_binary_to_array "${fan_header_active_binary[master]}" "fan_array"

	if [ "$auto_bmc_fan_thresholds" != true ]; then # 1/
		debug_print 2 bold "Upper BMC fan thresholds not updated, because automatic configuration preference is disabled"
		debug_print 3 "Permanently apply new BMC upper fan speed thresholds"

		case "$mobo_manufacturer" in # 1/
			asrock|dell|gigabyte|hpe|ibm|intel|lenovo|quanta|tyan)
				for fan_id in "${!fan_array[@]}"; do # 1/
					query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude" && return 1 # skip excluded fan headers (fan header bit = on)

					if (( ${fan_speed_lnr[$fan_id]} > 0 )); then # 2/
						debug_print 4 "Modifying LNR for fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) to ${fan_speed_lnr[$fan_id]} RPM"
						run_command "$ipmitool sensor thresh ${fan_header_name[$fan_id]} lnr ${fan_speed_lnr[$fan_id]}" # write new fan speed thresholds to BMC
					fi # 2/

					if (( ${fan_speed_lcr[$fan_id]} > 0 )); then # 2/
						debug_print 4 "Modifying LCR for fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) to ${fan_speed_lcr[$fan_id]} RPM"
						run_command "$ipmitool sensor thresh ${fan_header_name[$fan_id]} lcr ${fan_speed_lcr[$fan_id]}"
					fi # 2/

					if (( ${fan_speed_lnc[$fan_id]} > 0 )); then # 2/
						debug_print 4 "Modifying LNC for fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) to ${fan_speed_lnc[$fan_id]} RPM"
						run_command "$ipmitool sensor thresh ${fan_header_name[$fan_id]} lnc ${fan_speed_lnc[$fan_id]}"
					fi # 2/
				done # 1/
				;;

			supermicro)
				case "$bmc_command_schema" in # 2/
					supermicro-v3)
						# H13, H14, X13, X14 boards only use lower critical threshold setting
						for fan_id in "${!fan_array[@]}"; do # 1/
							query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude" && return 1 # skip excluded fan headers

							if (( ${fan_speed_lcr[$fan_id]} > 0 )); then # 2/
								debug_print 4 "Modifying LCR for fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) to ${fan_speed_lcr[$fan_id]} RPM"
								run_command "$ipmitool sensor thresh ${fan_header_name[$fan_id]} lcr ${fan_speed_lcr[$fan_id]}"
							fi # 2/
						done # 1/
						;;

					*)
						for fan_id in "${!fan_array[@]}"; do # 1/
							query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude" && return 1 # skip excluded fan headers

							if (( ${fan_speed_lnr[$fan_id]} > 0 )); then # 2/
								debug_print 4 "Modifying LNR for fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) to ${fan_speed_lnr[$fan_id]} RPM"
								run_command "$ipmitool sensor thresh ${fan_header_name[$fan_id]} lnr ${fan_speed_lnr[$fan_id]}"
							fi # 2/

							if (( ${fan_speed_lcr[$fan_id]} > 0 )); then # 2/
								debug_print 4 "Modifying LCR for fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) to ${fan_speed_lcr[$fan_id]} RPM"
								run_command "$ipmitool sensor thresh ${fan_header_name[$fan_id]} lcr ${fan_speed_lcr[$fan_id]}"
							fi # 2/

							if (( ${fan_speed_lnc[$fan_id]} > 0 )); then # 2/
								debug_print 4 "Modifying LNC for fan header ${fan_header_name[$fan_id]} (fan ID $fan_id) to ${fan_speed_lnc[$fan_id]} RPM"
								run_command "$ipmitool sensor thresh ${fan_header_name[$fan_id]} lnc ${fan_speed_lnc[$fan_id]}"
							fi # 2/
						done # 1/
						;;
					esac # 2/
					;;

			*)
				debug_print 4 warn "No changes made to BMC Lower fan thresholds (unrecognized motherboard type)"
				return 1
				;;
		esac # 1/
	fi # 1/

	##
	# Print a summary table with all results
	##

	# read current values from BMC to allow user to confirm in log that changes were accepted
	get_fan_info all quiet true

	if [ -n "$log_filename" ]; then # 1/ post data to log file
		{
			printf "\nLower BMC fan threshold speeds (active fan headers only):"
			printf "\n------------------------------------------------"
			printf "\n|      Fan      |   LNC   |   LCR   |   LNR   |"
			printf "\n-----------------------------------------------\n"

			for fan_id in "${!fan_array[@]}"; do # 1/
				printf "|  %11s  |  %5s  |  %5s  |  %5s  |\n" "${fan_header_name[$fan_id]}" "${fan_speed_lnc[$fan_id]}" "${fan_speed_lcr[$fan_id]}" "${fan_speed_lnr[$fan_id]}"
			done # 1/

			printf "|---------------------------------------------|\n"
		} >> "$log_filename"
	fi # 1/

	return 0 # success
}
