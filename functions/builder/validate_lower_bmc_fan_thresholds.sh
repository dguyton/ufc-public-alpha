##
# validate lower BMC fan speed thresholds
#
# Builder only.
#
# Evaluate lower BMC rotational fan speed thresholds against estimated minimum fan speed.
# When minimum speed is unknown, estimate lowest logical potential values.
##

function validate_lower_bmc_fan_thresholds ()
{
	local bmc_lower_lnr_limit	# calculate universal low; only applies when threshold buffer mode = loose
	local bmc_lower_lcr_limit	# calculate universal low; only applies when threshold buffer mode = loose
	local bmc_lower_lnc_limit	# calculate universal low; only applies when threshold buffer mode = loose
	local fan_id

	local -a fan_array

	debug_print 2 "Check lower BMC fan speed thresholds for each fan"
	debug_print 3 "LNC = Lower Non-Critical fan speed setting (permanently stored in BMC)"
	debug_print 3 "LCR = Lower CRitical fan speed setting (permanently stored in BMC)"
	debug_print 3 "LNR = Lower Non-Recoverable fan speed setting (permanently stored in BMC)"

	##
	# When lowest possible BMC fan threshold is declared in the config file,
	# it must be validated against the fan hysteresis.
	##

	if [ "$auto_bmc_fan_thresholds" = true ]; then # 1/
		if [ "$bmc_threshold_buffer_mode" = "loose" ]; then # 2/ do not constrain upper fan speed limit, and purposefully keep it as lenient as possible
			debug_print 3 "Lower fan speed limiting mode: LOOSE (minimum BMC detection levels)"
			bmc_lower_lnr_limit="$bmc_threshold_interval"
			bmc_lower_lcr_limit=$(( bmc_lower_lnr_limit + bmc_threshold_interval ))
			bmc_lower_lnc_limit=$(( bmc_lower_lcr_limit + bmc_threshold_interval ))
		else # 2/ narrowo latitude
			debug_print 3 "Lower fan speed limiting mode: STRICT (align lower fan speed threshold limits of each fan to its minimum speed)"
		fi # 2/

		##
		# Set thresholds for each fan individually
		##

		# ensure minimum cpu fan duty cycle meets minimum cpu fan speed (RPM) requirement for every cpu fan
		convert_binary_to_array "${fan_header_active_binary[master]}" "fan_array"

		# determine minimum possible fan speed without triggering BMC panic mode
		for fan_id in "${!fan_array[@]}"; do # 1/
			if [ "$bmc_threshold_buffer_mode" = "loose" ]; then # 2/ set lower panic mode triggers as low as possible
				if [ "${fan_speed_limit_min[$fan_id]}" -gt 0 ] && [ "${fan_speed_limit_min[$fan_id]}" -lt $(( bmc_threshold_interval * 4 )) ]; then # 3/ make no change when min speed below 4x fan hysteresis
					debug_print 4 caution "${fan_header_name[$fan_id]} (fan ID $fan_id) BMC lower fan speed thresholds not adjusted: reported minimum fan speed abnormally low"
				else # 3/
					fan_speed_lnc["$fan_id"]=$((bmc_lower_lnc_limit))
					fan_speed_lcr["$fan_id"]=$((bmc_lower_lcr_limit))
					fan_speed_lnr["$fan_id"]=$((bmc_lower_lnr_limit))
				fi # 3/
			else # 2/ strict mode
				if [ "${fan_speed_limit_min[$fan_id]}" -gt 0 ]; then # 3/
					if [ "${fan_speed_limit_min[$fan_id]}" -le $(( bmc_threshold_interval * 5 )) ]; then # 4/ 5x fan hysteresis or less
						if [ "${fan_speed_limit_min[$fan_id]}" -lt $(( bmc_threshold_interval * 4 )) ]; then # 5/ below 4x fan hysteresis
							if [ "${fan_speed_limit_min[$fan_id]}" -lt $(( bmc_threshold_interval * 3 )) ]; then # 6/ below 3x fan hysteresis
								debug_print 3 warn "Fan ${fan_header_name[$fan_id]} (fan ID $fan_id) reported minimum fan speed is extremely low"
								fan_speed_lnr["$fan_id"]="$bmc_threshold_interval" # 1x fan hysteresis is bare minimum
								fan_speed_lcr["$fan_id"]="$bmc_threshold_interval" # 1x fan hysteresis
								fan_speed_lnc["$fan_id"]="$bmc_threshold_interval" # 1x fan hysteresis
							else # 6/ < 4x
								debug_print 3 warn "Fan ${fan_header_name[$fan_id]} (fan ID $fan_id) reported minimum fan speed is peculiarly low"
								fan_speed_lnr["$fan_id"]=$(( bmc_threshold_interval * 2 )) # 2x fan hysteresis is bare minimum
								fan_speed_lcr["$fan_id"]="$bmc_threshold_interval" # 1x fan hysteresis
								fan_speed_lnc["$fan_id"]="$bmc_threshold_interval" # 1x fan hysteresis
							fi # 6/
						else # 5/ < 5x
							debug_print 3 warn "Fan ${fan_header_name[$fan_id]} (fan ID $fan_id) reported minimum fan speed is very low"
							fan_speed_lnr["$fan_id"]=$(( bmc_threshold_interval * 2 )) # 2x fan hysteresis is bare minimum
							fan_speed_lcr["$fan_id"]=$(( bmc_threshold_interval * 2 )) # 2x fan hysteresis
							fan_speed_lnc["$fan_id"]="$bmc_threshold_interval" # 1x fan hysteresis
						fi # 5/
					else # 4/ min speed is >= 5x fan hysteresis
						fan_speed_lnc["$fan_id"]=$(( fan_speed_limit_min[fan_id] - ( bmc_threshold_interval * 4 ) )) # -4x hysteresis
						fan_speed_lcr["$fan_id"]=$(( fan_speed_lnc[fan_id] - bmc_threshold_interval )) # -3x
						fan_speed_lnr["$fan_id"]=$(( fan_speed_lcr[fan_id] - bmc_threshold_interval )) # -2x
					fi # 4/
				else # 3/
					debug_print 3 "Incumbent lower BMC fan speed thresholds retained for ${fan_header_name[$fan_id]} (fan ID $fan_id) as its minimum fan speed is unknown"
				fi # 3/
			fi # 2/
		done # 1/

	else # 1/ existing values will be retained
		debug_print 3 "Retain incumbent lower BMC fan speed thresholds as automated validation is disabled"
	fi # 1/

	set_lower_fan_thresholds # review values for each fan header and write new ones if they changed
}
