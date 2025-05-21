##
# Compare assigned fan duty cycle to current active fan speeds.
#
# Warn user via log when observed fan speed is out of range of
# expected or estimated fan speed range by more than one fan
# hysteresis interval.
#
# Periodically validates fan duty cycles to look for fans acting out of scope.
# When any fan is deemed to be out of scope, flag it for follow-up review
# by tagging the fan as suspicious.
##

# check whether fan speed is operating within expected parameters
function validate_fan_duty_cycle ()
{
	local fan_category
	local fan_id
	local suspect
	local binary_string

	local -a fan_array

	fan_category="$1"	# fan cooling duty type to validate

	debug_print 3 "Validate fan duty cycle for ${fan_category^^} fans"

	# limit validation scope to active fans belonging to target fan duty category only
	binary_string="${fan_header_active_binary[$fan_category]}"

	if [ ! -z "$binary_string" ]; then # 1/
		debug_print 4 warn "Invalid fan duty category specified in subroutine call (no active fan headers)" true
		return 1
	fi # 1/

	debug_print 2 "Validate fan header behavior relative to fan duty cycles"
	debug_print 3 "Compare current raw fan speeds (RPM) to expected fan speeds (duty level) for fan cooling duty type: $fan_category"
	debug_print 4 "Mark fans exhibiting unexpected behavior as suspicious"

	# get current info for all fans of specified fan duty categoryies
	get_fan_info "$fan_category" all verbose false

	convert_binary_to_array "$binary_string" "fan_array"

	for fan_id in "${!fan_array[@]}"; do # 1/ test only active fan headers of target type

		unset suspect # reset from previous loop

		##
		# Minimum fan speed thresholds are primarily focused based on
		# LCR (Lower Non-Critical) and LNR (Lower Non-Recoverable)
		# thresholds enforced by the BMC (Baseboard Management Controller).
		#
		# Working minimum speeds are generally user-defined for CPU fans
		# and observed (0% or 1% power) for non-CPU fans.
		#
		# Maximum fan speed limits are distinguished between maximum duty cycle
		# caps and/or arbitrary ceilings designated by the user via config file.
		##

		if (( fan_header_speed[fan_id] > 0 )); then # 1/ do not attempt to probe fan speed if it was not captured

			# flag fans spinning below minimum allowed threshold (fan speed too low)
			if (( fan_header_speed[fan_id] < fan_speed_limit_min[fan_id] )); then # 2/ under-speed
				suspect="under"

				# BMC lower critical threshold violated
				(( fan_header_speed[fan_id] <= fan_speed_lcr[fan_id] )) && suspect="panic"
			fi # 2/

			# exceeds maximum allowed RPM (max fan duty cycle), but may be below physical speed limit (fan speed too high)
			if (( fan_header_speed[fan_id] > fan_speed_duty_max[fan_id] + bmc_threshold_interval )); then # 2/ over-speed
				suspect="over" # allowed max speed may be < physical max speed

				# fan speed exceeds maximum physically possible speed of any fan
				(( fan_header_speed[fan_id] > 29500 + ( bmc_threshold_interval * 2 ) )) && suspect="error"

				# fan speed exceeds maximum physical speed limit
				(( fan_header_speed[fan_id] > fan_speed_limit_max[fan_id] + bmc_threshold_interval )) && suspect="limit"
			fi # 2/
		fi # 1/

		# validate cpu fans against current fan duty levels (human-readable)
		if [ -z "$suspect" ]; then # 1/ fan is active, not in panic mode, and not yet suspicious

			case "$fan_category" in # 2/
				cpu)
					if [ "$cpu_fan_control" = true ]; then # 2/ cpu fans are actively managed

						#########################
						# CPU FAN TYPE VALIDATION
						#########################

						##
						# CPU fan speed settings are fixed, making them easier to
						# analyze for in/out of scope behavior.
						##

						# validate cpu fans against current fan duty levels (human-readable)
						case "$cpu_fan_level" in # 3/
							high)
								if (( fan_header_speed[fan_id] < fan_speed_duty_high[fan_id] - ( bmc_threshold_interval * 2 ) )); then # 3/
									debug_print 3 warn "CPU fan $fan_id speed too low: ${fan_header_speed[$fan_id]} RPM actual vs. ${fan_speed_duty_high[$fan_id]} RPM expected"
									suspect="low" # flag for follow-up investigation
								fi # 3/
							;;

							medium)
								if (( fan_header_speed[fan_id] < fan_speed_duty_med[fan_id] - ( bmc_threshold_interval * 2 ) )); then # 3/
									debug_print 3 warn "CPU fan $fan_id speed too low: ${fan_header_speed[$fan_id]} RPM actual vs. ${fan_speed_duty_med[$fan_id]} RPM expected"
									suspect="low"
								fi # 3/
							;;

							low)
								if (( fan_header_speed[fan_id] > fan_speed_duty_low[fan_id] - ( bmc_threshold_interval * 2 ) )); then # 3/
									debug_print 3 caution "CPU fan $fan_id speed too low: ${fan_header_speed[$fan_id]} RPM actual vs. ${fan_speed_duty_low[$fan_id]} RPM expected"
									suspect="low"
								fi # 3/
							;;

							maximum)
								if (( fan_header_speed[fan_id] > fan_speed_duty_max[fan_id] + ( bmc_threshold_interval * 2 ) )); then # 3/ too fast
									debug_print 3 caution "CPU fan $fan_id speed too high: ${fan_header_speed[$fan_id]} RPM actual vs. ${fan_speed_duty_max[$fan_id]} RPM expected"
									suspect="high"
								else # 3/
									if (( fan_header_speed[fan_id] < fan_speed_duty_max[fan_id] - ( bmc_threshold_interval * 2 ) )); then # 4/ too slow
										debug_print 3 warn "CPU fan $fan_id speed too low: ${fan_header_speed[$fan_id]} RPM actual vs. ${fan_speed_duty_med[$fan_id]} RPM expected"
										suspect="low"
									fi # 4/
								fi # 3/
							;;

							*)
								debug_print 4 warn "Duty cycle validation failed: could not validate CPU fan ${fan_header_name[$fan_id]} (fan ID $fan_id) actual vs. expected fan speed"
							;;
						esac # 3/
					fi # 2/
				;;

				device)

					#################################
					# DISK DEVICE FAN TYPE VALIDATION
					#################################

					##
					# Disk Device fan speeds are variable, thus requiring
					# a different approach to ascertaining when fans may
					# be operating out of spec.
					##

					# fan duty >= high threshold and fan speed is < high rpm threshold
					if (( device_fan_duty >= device_fan_duty_high )) && (( fan_header_speed[fan_id] < fan_speed_duty_high[fan_id] - ( bmc_threshold_interval * 2 ) )); then # 2/
						debug_print 3 "Disk Device fan $fan_id speed too low: ${fan_header_speed[$fan_id]} RPM actual vs. ${fan_speed_duty_high[$fan_id]} RPM expected."
						suspect="low"
					fi # 2/

					# fan duty <= low threshold and fan speed is > low rpm threshold
					if (( device_fan_duty <= device_fan_duty_low )) && (( fan_header_speed[fan_id] > fan_speed_duty_low[fan_id] + ( bmc_threshold_interval * 2 ) )); then # 2/ outside bounds of low fan duty
						debug_print 3 "Disk Device fan $fan_id speed too high: ${fan_header_speed[$fan_id]} RPM actual vs. ${fan_speed_duty_low[$fan_id]} RPM expected."
						suspect="high"
					fi # 2/

					# fan duty > low and < high thresholds and fan speed is < low rpm threshold or > high rpm threshold (out of bounds)
					if (( device_fan_duty > device_fan_duty_low )) && (( device_fan_duty < device_fan_duty_high )); then # 2/ outside bounds of medium fan duty
						if (( fan_header_speed[fan_id] < fan_speed_duty_low[fan_id] - ( bmc_threshold_interval * 2 ) )); then # 3/
							debug_print 3 "Disk Device fan $fan_id speed too low: ${fan_header_speed[$fan_id]} RPM actual vs. ${fan_speed_duty_med[$fan_id]} RPM expected."
							suspect="low"
						else # 3/
							if (( fan_header_speed[fan_id] > fan_speed_duty_high[fan_id] + ( bmc_threshold_interval * 2 ) )); then # 4/
								debug_print 3 "Disk Device fan $fan_id speed too high: ${fan_header_speed[$fan_id]} RPM actual vs. ${fan_speed_duty_med[$fan_id]} RPM expected."
								suspect="high"
							fi # 4/
						fi # 3/
					fi # 2/
				;;

				*)
					debug_print 3 warn "Could not determine fan duty category for fan header ${fan_header_name[$fan_id]} (fan ID $fan_id)"
				;;
			esac
		fi # 1/

		# add suspect fan headers to suspicious fan tracker
		if [ -n "$suspect" ]; then # 1/ cycle previous reading from current to past and set alert when fan tagged as suspicious
			[ -n "${suspicious_fan_list[$fan_id]}" ] && suspicious_fan_list_old[$fan_id]="${suspicious_fan_list[$fan_id]}" # copy current to prior suspicious tracking state when there is one
			suspicious_fan_list[$fan_id]="$suspect"
		fi # 1/
	done # 1/

	##
	# Set timer for suspicious fan validation when one or more
	# fan headers were flagged as suspicious by this subroutine,
	# and the timer was not already active.
	##

	if (( ${#suspicious_fan_list[@]} > 0 )); then # 1/
		if [ -z "$suspicious_fan_timer" ]; then # 2/ suspicious fans found and timer not already set
			suspicious_fan_timer=$(( $(current_time) + suspicious_fan_validation_delay ))
			debug_print 3 "Start suspicious fan validation countdown timer"
		else # 2/
			debug_print 4 "Suspicious fan timer already set"
		fi # 2/
	fi # 1/

	return 0
}
