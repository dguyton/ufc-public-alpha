##
# Programatically determine disk device/case fan zone minimum fan speeds (RPM).
#
# Perform a logical analysis of declared minimum device fan zone fans
# prior to assessing actual minimum capabilities of the fans.
#
# Purpose of this step is to prevent inadvertent triggering of BMC panic mode.
#
# Performs real-world testing of purported device fan speed minimum against
# actual fan performance. Also monitors for triggering lower thresholds if the
# speeds are too low, meaning either the thresholds need to be adjusted, or
# the minimum allowed fan duty cycle for the device fans should be adjusted.
#
# Builder only.
##

<<>>

--> re-factor to support all non-cpu fan types


function validate_category_min_fan_speeds ()
{
	local fan_category
	local fan_id
	local min_duty_cycle_calc

	local -a fan_array

	local -A fan_duty_min_last

	[ "$only_cpu_fans" = true ] && return # no independent disk device fan duty category

	debug_print 3 "Probe minimum speeds of non-CPU cooling fans"

for fan_category in "${fan_duty_category[@]}"; do # 1/

# probe active fans only
convert_binary_to_array "${fan_header_active_binary[$fan_category]}" "fan_array"

	##
	# Estimate lowest minimum rpm (logical value) of all disk device fans based
	# on user declared minimum fan duty cycle %age and known max fan speed,
	# and validate it against LNC threshold in BMC, if known. This information
	# provides insight into whether or not the disk device fans are potentially
	# about to be set to a level that is too low, triggering BMC panic mode.
	#
	# If such a risk seems plausible, the program will monitor for such a condition
	# and try to inform the user via forensics recorded in the program log.
	##

	# force mismatch on first pass to ensure test proceeds
	fan_duty_min_last["$fan_category"]="$fan_duty_limit" # lead with a value that cannot be tripped on the first pass

	while [ "${fan_duty_min_last[$fan_category]}" -lt "${fan_duty_max[$fan_category]}" ]; do # 1/ find minimum duty cycle percentage that works

		# trap infinite loop edge case where no fan speed reported for any category fan
		if [ "$device_fan_duty_min" -eq "${fan_duty_min_last[$fan_category]}" ]; then # 1/ should never happen
			debug_print 4 critical "Unable to detect current fan speed of any type ${fan_category^^} cooling fan"
			bail_with_fans_optimal "Valid ${fan_category^^} fan duty cycle could not be determined"
		fi # 1/

		debug_print 4 "Analyze performance: ${fan_duty_min[$fan_category]}% PWM"

		# start device fans at min speed
		set_fan_duty_cycle "$fan_category" "${fan_duty_min[$fan_category]}"

		##
		# Wait at least 15 seconds for fans to calm down prior to measuring.
		# Recall the fans were set to maximum speed for all fans initially.
		# Now, they must be reduced down to whatever is the desired minimum
		# speed for the disk device fans.
		#
		# If the user has configured the fan speed delay timer to be rather
		# short, and at the same time has configured the disk device fan duty
		# type minimum fan speed to be very low, then it is necessary to wait
		# for a prolonged period of time prior to reading actual minimal fan
		# speed RPMs.
		#
		# Failure to wait long enough may result in the program establishing
		# inaccurate settings for Disk Device fan duty minimum fan speeds.
		# This in turn will lead to inaccurate error flagging and alerts when
		# the fans are detected spinning below the Service program's perception
		# of acceptable minimal fan speeds for the given fan.
		#
		# Artificially extending the waiting period between maximum and minimum
		# fan speeds allows sufficient time for the fans to spin down before
		# taking new speed readings. This extended wait period is only necessary
		# for this setup process, and ensures readings are accurate.
		##

		sleep "$fan_speed_delay" # wait a bit for fan speeds to adjust to new duty cycle before polling their info

		get_fan_info "$fan_category" quiet false # update fan speed metrics for peripheral (disk device) fan duty only

		# store currently tested fan duty before it can be altered
		fan_duty_min_last["$fan_category"]="${fan_duty_min[$fan_category]}"

		for fan_id in "${!fan_array[@]}"; do # 2/

			[ "${fan_header_speed[$fan_id]}" -eq 0 ] && continue # skip when no speed info

			# check if BMC panic mode triggered by accident... user needs to investigate the cause (most likely, min duty cycle set too low)
			if [ "${fan_header_status[$fan_id]}" = "panic" ] || [ "${fan_header_speed[$fan_id]}" -ge "${fan_speed_limit_max[$fan_id]}" ]; then # 1/ panic mode
				debug_print 4 "BMC panic mode appears to have been triggered"
				debug_print 4 caution "Adjusting minimum fan duty cycle to compensate and re-test"
				fan_duty_min["$fan_category"]=$(( device_fan_duty_min + 5 )) # increment 5% and re-test all device fans
				continue 2 # restart main loop
			fi # 1/

			##
			# Run some tests to determine if fan speed is too close to lower fan speed thresholds.
			##

			# warn when min fan duty causes any fan speed to be near its maximum limit
			[ "${fan_header_speed[$fan_id]}" -ge $(( fan_speed_limit_max[fan_id] - ( 3 * bmc_threshold_interval ) )) ] && debug_print 3 caution "${fan_header_name[$fan_id]} minimum fan speed (${fan_header_speed[$fan_id]} RPM) is close to its maximum"

			# min fan duty cycle setting ok but may be questionable
			{ [ "${fan_speed_lnc[$fan_id]}" -gt 0 ] && [ "${fan_header_speed[$fan_id]}" -le "${fan_speed_lnc[$fan_id]}" ]; } && debug_print 3 caution "Minimum fan duty may cause ${fan_header_name[$fan_id]} to spin at or below its LNC threshold"

			# duty cycle too low, causing fan to spin dangerously close to LCR
			if [ "${fan_speed_lcr[$fan_id]}" -gt 0 ] && [ "${fan_header_speed[$fan_id]}" -le $(( fan_speed_lcr[fan_id] + ( bmc_threshold_interval * 2 ) )) ]; then # 1/
				debug_print 3 warn "Minimum fan duty may cause ${fan_header_name[$fan_id]} to spin at or below its LCR threshold, triggering panic mode"
				debug_print 3 "Adjusting minimum device fan duty to compensate"
				fan_duty_min[default]=$(( device_fan_duty_min + 5 )) # add 5% and try again
				continue 2
			fi # 1/

			# scraping the bottom

<<>>

--> this may be worth quantifying and coming up with a variable that represents the buffer or buffer multiplier
--> e.g., "min_safe_rpm=" perhaps specified in config or elsewhere. could still be formulaic.


			if [ "${fan_header_speed[$fan_id]}" -lt $(( bmc_threshold_interval * 3 )) ]; then # 1/ fan speed should be at least 3x fan hysteresis to prevent conflicts with BMC thresholds
				debug_print 3 "Adjust and re-test duty cycle; ${device_fan_duty_min}% PWM is too low for ${fan_header_name[$fan_id]}"

				# calculate a more suitable floor
				min_duty_cycle_calc="$(convert_rpm_to_duty_cycle $(( bmc_threshold_interval * 3 )) "${fan_speed_limit_max[$fan_id]}")"

				if [ "${fan_duty_min[$fan_category]}" -lt "$min_duty_cycle_calc" ]; then # 2/
					fan_duty_min["$fan_category"]="$min_duty_cycle_calc"
				else # 2/
					fan_duty_min["$fan_category"]=$(( device_fan_duty_min + 5 )) # increment 5%
				fi # 2/

				continue 2 # re-test all device fan headers
			fi # 1/
		done # 2/

		break # abort when current fan duty cycle seems to work as minimum for all device fans

	done # 1/ this loop ends when the current minimum duty cycle is viable for every device fan

	##
	# Clean-up, calibrate and publish minimum rotational fan speeds
	##

	if [ "${fan_duty_min[$fan_category]}" -ge "${fan_duty_max[$fan_category]}" ]; then # 1/
		debug_print 3 caution "Minimum Device fan duty cycle set to maximum"
		debug_print 4 warn "Device fans will be run at maximum Device fan duty all the time"
		fan_duty_min["$fan_category"]="${fan_duty_max[$fan_category]}" # cap it at max
	fi # 1/

	debug_print 2 "Minimum duty cycle for Device (case) fans validated at ${fan_duty_min[$fan_category]}%"
	debug_print 3 "Determine corresponding minimum rotational speed of each ${fan_category^} fan"

	for fan_id in "${!fan_array[@]}"; do # 1/
		if [ "${fan_speed_limit_max[$fan_id]}" -gt 0 ]; then # 1/
			fan_speed_limit_min["$fan_id"]="$(convert_duty_cycle_to_rpm "${fan_duty_min[$fan_category]}" "${fan_speed_limit_max[$fan_id]}")"
		else # 1/
			fan_speed_limit_min["$fan_id"]="$(convert_duty_cycle_to_rpm "${fan_duty_min[$fan_category]}" "${fan_speed_lowest_max[$fan_category]}")"
		fi # 1/

		debug_print 4 "Min fan speed limit of ${fan_header_name[$fan_id]} (fan ID $fan_id) set to ${fan_speed_limit_min[$fan_id]}"
	done # 1/
}

--> optionally re-verify the actual RPM after calculating fan_speed_limit_min[$fan_id] at the very end,
--> to ensure it reflects a true post-test state.