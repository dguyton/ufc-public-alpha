##
# Programmatically determine minimum fan speeds (RPM) for non-CPU cooling fans.
#
# This subroutine performs **progressive testing** to determine a *safe minimum duty cycle* 
# that will not cause fans to:
# - Stop spinning due to inertia/friction/hardware limits
# - Drop below BMC (Baseboard Management Controller) LNC/LCR thresholds
# - Trigger panic modes or log noise
#
# CPU fans are explicitly excluded due to their critical role in system health,
# real-time thermal response requirements, and potential BMC override behavior.
#
# This logic only runs during the Builder phase, not Launcher or Runtime services.
##

##
# Increase current minimum duty cycle by 5% for a given fan duty category.
# Invoked when fans are spinning too slowly or triggering BMC panic mode.
##

function bump_and_retry_min_duty ()
{
	local category="$1"

	fan_duty_min["$category"]=$(( fan_duty_min[$category] + 5 ))
}

##
# Compare proposed fan duty to current minimum.
#
# Attempt to set new minimum fan duty to proposed value.
# Bump incumbent value when proposed value is not higher.
##

function try_set_min_or_bump ()
{
	local category="$1"
	local proposed_fan_duty="$2"

	if [ "${fan_duty_min[$category]}" -lt "$proposed_fan_duty" ]; then # 1/
		fan_duty_min["$category"]="$proposed_fan_duty"
	else # 1/
		bump_and_retry_min_duty "$category"
	fi # 1/
}

# Core logic to probe all non-CPU fans and determine safe minimum duty cycles.
function validate_device_min_fan_speeds ()
{
	local fan_category
	local fan_id
	local temp_fan_duty_min_last
	local min_duty_cycle_calc
	local wait_timer

	local -a fan_array

	# Skip non-CPU validation if configured to test CPU fans only
	[ "$only_cpu_fans" = true ] && return

	debug_print 3 "Probe minimum speeds of non-CPU cooling fans"

	##
	# Expand normal wait timer to a minimum of 15 seconds.
	#
	# This helps to allow the system to calm down in the event that
	# panic mode was tripped in the prior fan speed detection attempt.
	##

	wait_timer=15
	(( fan_speed_delay > 15 )) && wait_timer=$((fan_speed_delay))

	for fan_category in "${fan_duty_category[@]}"; do # 1/

		# skip CPU-controlled and explicitly excluded categories
		[ "$fan_category" = "cpu" ] && continue
		[ "$fan_category" = "exclude" ] && continue

		debug_print 3 "Fan duty category '$fan_category' pre-validation fan duty minimum duty cycle: ${fan_duty_min[$fan_category]}%"

		# store last attempted value to detect stagnation
		temp_fan_duty_min_last=999 # start with value guaranteed to be overwritten unless inner loop fails

		# try progressively increasing fan duty until a valid min speed is found
		while [ "${fan_duty_min[$fan_category]}" -lt "${fan_duty_max[$fan_category]}" ]; do # 2/

			# detect stagnation and bail out if no progress is being made (likely due to hardware misreporting)
			if [ "${fan_duty_min[$fan_category]}" -eq "$temp_fan_duty_min_last" ]; then # 1/

				# extract the relevant fan speeds for the current category into a temporary array
				local -a category_speeds

				for fan_id in "${!fan_array[@]}"; do # 3/
					[ "${fan_header_category[$fan_id]}" == "$fan_category" ] && category_speeds+=("${fan_header_speed[$fan_id]}")
				done # 3/

				# check if all RPMs for this category are zero
				if [ -z "${category_speeds[*]##0}" ]; then # 2/ strip 0's

					# if all RPMs are zero, it indicates a problem with fan operation or sensor misreporting
					debug_print 4 critical "All RPM readings are zero (0 RPM) for fans in '$fan_category' — possible disconnection, sensor fault, or insufficient spin-up at current PWM"
					bail_with_fans_optimal "Failed to detect any RPMs for '$fan_category' fans, likely due to hardware misreporting or misconfiguration"

				else # 2/

					# if not all RPMs are zero, but we still can't progress, there's an issue with the fan duty cycle
					debug_print 4 critical "RPMs detected but no progress is being made in '$fan_category' — controller may not be responding to PWM changes correctly"
					bail_with_fans_optimal "No progress in fan speed validation for '$fan_category', possibly due to unresponsive controller"
				fi # 2/
			fi # 1/

			debug_print 4 "Analyze performance: ${fan_duty_min[$fan_category]}% PWM"

			##
			# Phase 1: Set fan duty cycle and give the system time to stabilize before taking readings.
			##

			set_fan_duty_cycle "$fan_category" "${fan_duty_min[$fan_category]}"

			##
			# Wait at least 15 seconds for fans to calm down prior to measuring.
			# Recall the fans were set to maximum speed for all fans initially.
			# Now, they must be reduced down to whatever is the desired minimum
			# speed for the fans.
			#
			# If the user has configured the fan speed delay timer to be rather
			# short, and at the same time has configured the fan duty category
			# type minimum fan speed to be very low, then it is necessary to wait
			# for a prolonged period of time prior to reading actual minimal fan
			# speed RPMs.
			#
			# Failure to wait long enough may result in inaccurate detection of 
			# minimum safe fan speeds. This in turn will lead to inaccurate error
			# flagging and alerts when the fans are detected spinning below the
			# Service program's perception of acceptable minimal fan speeds for
			# the given fan.
			#
			# Artificially extending the waiting period between maximum and minimum
			# fan speeds allows sufficient time for the fans to spin down before
			# taking new speed readings. This extended wait period is only necessary
			# for this setup process, and ensures readings are accurate.
			##

			sleep "$wait_timer"

			get_fan_info "$fan_category" quiet false

			##
			# Phase 2: Determine if any fan is violating safety margins, return a signal to adjust and how
			##

			# Store last tried value to detect infinite retry loops
			temp_fan_duty_min_last="${fan_duty_min[$fan_category]}"

			# convert binary string of enabled fans into an array of usable fan IDs
			convert_binary_to_array "${fan_header_active_binary[$fan_category]}" "fan_array"

			# analyze fan data for each member of this category
			for fan_id in "${!fan_array[@]}"; do # 3/
				# skip sensors reporting 0 RPM (likely disconnected or irrelevant)
				[ "${fan_header_speed[$fan_id]}" -eq 0 ] && continue

				# when a fan triggers panic mode or hits hard speed ceiling, back off and retry
				if [ "${fan_header_status[$fan_id]}" = "panic" ] || [ "${fan_header_speed[$fan_id]}" -ge "${fan_speed_limit_max[$fan_id]}" ]; then # 1/
					debug_print 4 "BMC panic mode appears to have been triggered"
					debug_print 4 caution "Adjusting minimum fan duty cycle to compensate and re-test"
					bump_and_retry_min_duty "$fan_category"
					continue 2
				fi # 1/

				# warn if speed is uncomfortably close to maximum — could affect future scaling
				[ "${fan_header_speed[$fan_id]}" -ge $(( fan_speed_limit_max[fan_id] - ( 3 * bmc_threshold_interval ) )) ] &&
					debug_print 3 caution "${fan_header_name[$fan_id]} minimum fan speed (${fan_header_speed[$fan_id]} RPM) is close to its maximum"

				# LNC (Low Non-Critical) warning: too low could cause log noise or power cycling
				{ [ "${fan_speed_lnc[$fan_id]}" -gt 0 ] && [ "${fan_header_speed[$fan_id]}" -le "${fan_speed_lnc[$fan_id]}" ]; } &&
					debug_print 3 caution "Minimum fan duty may cause ${fan_header_name[$fan_id]} to spin at or below its LNC threshold"

				# LCR (Low Critical) warning: system may interpret fan as failed, trigger panic
				if [ "${fan_speed_lcr[$fan_id]}" -gt 0 ] && [ "${fan_header_speed[$fan_id]}" -le $(( fan_speed_lcr[fan_id] + ( bmc_threshold_interval * 2 ) )) ]; then # 1/
					debug_print 3 warn "Minimum fan duty may cause ${fan_header_name[$fan_id]} to spin at or below its LCR threshold, triggering panic mode"
					debug_print 3 "Adjusting minimum '$fan_category' fan duty to compensate"
					bump_and_retry_min_duty "$fan_category"
					continue 2
				fi # 1/

				##
				# Phase 3: When a fan is operating below safe thresholds, calculate a new minimum duty cycle
				##

				# if fan speed is abnormally low, estimate a safe duty cycle and try again
				if [ "${fan_header_speed[$fan_id]}" -lt $(( bmc_threshold_interval * 3 )) ]; then # 1/
					debug_print 3 "Adjust and re-test duty cycle; ${fan_duty_min[$fan_category]}% PWM is too low for ${fan_header_name[$fan_id]}"
					min_duty_cycle_calc="$(convert_rpm_to_duty_cycle $(( bmc_threshold_interval * 3 )) "${fan_speed_limit_max[$fan_id]}")"
					try_set_min_or_bump "$fan_category" "$min_duty_cycle_calc"
					continue 2
				fi # 1/
			done # 3/

			# update min fan speed threshold for all fans belonging to the current fan duty category
			temp_fan_duty_min_last="${fan_duty_min[$fan_category]}"

			# if all fans passed, break out of PWM testing loop
			break

		done # 2/

		##
		# Phase 4: Clean-up, calibrate and publish minimum rotational fan speeds, apply to fan_speed_limit_min[]
		##

		# if min duty equals max, log a warning; fans will run at full speed constantly
		if [ "${fan_duty_min[$fan_category]}" -ge "${fan_duty_max[$fan_category]}" ]; then # 1/
			fan_duty_min["$fan_category"]="${fan_duty_max[$fan_category]}"
			debug_print 3 caution "Minimum '$fan_category' fan duty cycle set to maximum"
			debug_print 4 warn "This means '$fan_category' fans will run at their maximum fan duty all the time"
		fi # 1/

		debug_print 2 "Minimum duty cycle for '$fan_category' fans validated at ${fan_duty_min[$fan_category]}%"
		debug_print 3 "Determine corresponding minimum rotational speed of each '$fan_category' fan"

		# set baseline RPM thresholds corresponding to validated min duty
		for fan_id in "${!fan_array[@]}"; do # 2/
			if [ "${fan_speed_limit_max[$fan_id]}" -gt 0 ]; then # 1/
				fan_speed_limit_min["$fan_id"]="$(convert_duty_cycle_to_rpm "${fan_duty_min[$fan_category]}" "${fan_speed_limit_max[$fan_id]}")"
			else # 1/
				fan_speed_limit_min["$fan_id"]="$(convert_duty_cycle_to_rpm "${fan_duty_min[$fan_category]}" "${fan_speed_lowest_max[$fan_category]}")"
			fi # 1/

			debug_print 4 "Min fan speed limit of ${fan_header_name[$fan_id]} (fan ID $fan_id) set to ${fan_speed_limit_min[$fan_id]}"
		done # 2/
	done # 1/
}
