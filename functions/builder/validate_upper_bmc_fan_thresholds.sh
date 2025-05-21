##
# Set upper BMC thresholds and normalize maximum possible fan speed.
#
# Builder only.
#
# Measuring limit of the BMC is 256x BMC fan interval (fan hysteresis).
# If a fan speed were to exceed this value, the counter will roll over to 0 (zero)
# and continue incrementing, which would provide a false value of the true fan speed.
# Also note fan speed is reported by BMC in increments of fan hysteresis intervals.
#
# Examine preiously collected top fan speed data points and make an intelligent
# determination of appropriate upper limit BMC fan speed thresholds. Validate
# existing data and apply the result to all fan headers.
#
# When specified, $upper_rpm_limit defines the upper limit of the upper BMC
# fan speed thresholds. It is relevant only when automatic assignment of BMC
# thresholds is requested. If it is not specified, the upper BMC thresholds
# will be set to their highest possible values by default.
##

function validate_upper_bmc_fan_thresholds ()
{
	local bmc_upper_max	# highest fan speed BMC is capable of tracking
	local bmc_upper_ucr_limit
	local bmc_upper_unc_limit
	local bmc_upper_unr_limit
	local fan_id

	local -a fan_array

	##
	# Ensure maximum allowed fan speeds do not exceed level the BMC is capable of monitoring.
	#
	# Prevent maximum allowed fan speed from exceeding the measuring capability
	# of the BMC. Also, set default to maximum allowed based on logical limit of BMC.
	##

	debug_print 2 "Determine upper BMC fan speed thresholds for each fan"

	debug_print 3 "UNC = Upper Non-Critical fan speed setting (permanently stored in BMC)"
	debug_print 3 "UCR = Upper CRitical fan speed setting (permanently stored in BMC)"
	debug_print 3 "UNR = Upper Non-Recoverable fan speed setting (permanently stored in BMC)"

	bmc_upper_max=$(( bmc_threshold_interval * 255 )) # max upper fan speed BMC can handle (8-bits) x fan hysteresis interval buffer

	debug_print 4 "Maximum read-able fan speed (by BMC): $bmc_upper_max"

	[ "$auto_bmc_fan_thresholds" != true ] && debug_print 3 "Automatic BMC fan speed validation disabled: retain existing upper BMC fan speed threshold settings"

	##
	# Evaluate user-declared preference regarding BMC fan speed threshold tolerances.
	#
	# When 'loose' mode is enabled, calculate tiered upper BMC fan speed threshold
	# settings based on absolute theoretical BMC maximum limit. Alternatively, when
	# 'strict' mode is enabled, take into consideration observed maximum fan speeds of
	# all existing fans. When theoretical fan speed limit is well above observed fan
	# speed limits, set the BMC fan speed limit thresholds slighty above the highest
	# observed fan speed limit.
	##

	if [ "$auto_bmc_fan_thresholds" = true ] && [ "$bmc_threshold_buffer_mode" = "strict" ]; then # 1/ narrow latitude
		debug_print 3 "Upper fan speed limiting mode: STRICT"
		debug_print 4 "Align upper fan speed threshold limits of each fan to its observed speeds"
	else # 1/ do not constrain upper fan speed limit, and purposefully keep it as lenient as possible
		debug_print 3 "Upper fan speed limiting mode: LOOSE"
		debug_print 4 "Limit upper fan speed threshold limits of each fan to theoretical limits of BMC"

		# assign upper BMC fan speed thresholds based on BMC threshold limits only when mode = loose
		bmc_upper_unr_limit="$bmc_upper_max"
		bmc_upper_ucr_limit=$(( bmc_upper_unr_limit - bmc_threshold_interval ))
		bmc_upper_unc_limit=$(( bmc_upper_ucr_limit - bmc_threshold_interval ))
	fi # 1/

	##
	# Set thresholds for each fan individually
	##

	# ensure minimum cpu fan duty cycle meets minimum cpu fan speed (RPM) requirement for every cpu fan
	convert_binary_to_array "${fan_header_active_binary[master]}" "fan_array"

	# determine minimum possible fan speed without triggering BMC panic mode
	for fan_id in "${!fan_array[@]}"; do # 1/
		if [ "$auto_bmc_fan_thresholds" = true ]; then # 1/
			if [ "$bmc_threshold_buffer_mode" = "loose" ]; then # 2/ set upper panic mode triggers as high as possible
				fan_speed_unc["$fan_id"]=$((bmc_upper_unc_limit))
				fan_speed_ucr["$fan_id"]=$((bmc_upper_ucr_limit))
				fan_speed_unr["$fan_id"]=$((bmc_upper_unr_limit))
			else # 2/ strict mode
				if [ "${fan_speed_limit_max[$fan_id]}" -gt 0 ]; then # 3/
					fan_speed_unc[$fan_id]=$(( fan_speed_limit_max[fan_id] + ( 2 * bmc_threshold_interval ) ))
					fan_speed_ucr[$fan_id]=$(( bmc_upper_unc_limit + bmc_threshold_interval ))
					fan_speed_unr[$fan_id]=$(( bmc_upper_ucr_limit + bmc_threshold_interval ))
				else # 3/
					debug_print 4 caution "Cannot determine upper fan speed thresholds for fan ${fan_header_name[$fan_id]} (fan ID $fan_id) because its max speed is unknown"
				fi # 3/
			fi # 2/
		fi # 1/

		debug_print 4 "${fan_header_name[$fan_id]} (fan ID $fan_id) UNC=${fan_speed_unc[$fan_id]}"
		debug_print 4 "${fan_header_name[$fan_id]} (fan ID $fan_id) UCR=${fan_speed_ucr[$fan_id]}"
		debug_print 4 "${fan_header_name[$fan_id]} (fan ID $fan_id) UNR=${fan_speed_unr[$fan_id]}"
	done # 1/

	set_upper_fan_thresholds # write new fan speed boundaries to BMC
}
