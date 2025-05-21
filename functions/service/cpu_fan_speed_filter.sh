##
# Make no change when CPU temps are declining and the following conditions are true:
# 1. Global fan change wait timer has not expired; OR
# 2. Highest CPU temperature is within 25% of trigger threshold for current fan speed
#
# This forces the system to wait to reduce CPU fan speed until after time has passed
# to allow CPU to cool down.
#
# When CPU temp increases, ignore delay timer. This results in more rapid fan response
# to rising temperatures.
##

function cpu_fan_speed_filter ()
{
	local trigger # 75%-ile of delta between two consecutive temperature thresholds

	# act now when current avg temp > last avg temp; OR current avg temp < last avg temp AND not time to tweak fans yet
	if (( cpu_temp_highest > cpu_temp_highest_last )) || { (( cpu_temp_highest < cpu_temp_highest_last )) && (( check_time >= next_cpu_fan_level_change_time )); }; then # 1/
		(( cpu_temp_highest < 1 )) && return # bail on invalid value
		next_cpu_fan_level_change_time=$(( check_time + fan_speed_delay )) # set timer for next cpu fan speed check
		cpu_fan_level_last="$cpu_fan_level" # preserve pre-existing fan speed level before determining new level
		cpu_fan_level="$(calculate_cpu_fan_level_from_temp $((cpu_temp_highest)))" # determine what fan level should be based on current highest cpu or cpu core temp
	fi # 1/

	# only single fan duty category + not already indicating max fan speed + virtual device type fan speed is known
	if [ "$only_cpu_fans" = true ] && [ "$cpu_fan_level" != "maximum" ] && [ -n "$device_fan_level" ]; then # 1/

		##
		# As there is no actual disk fan zone, these variables are not
		# managed elsewhere, and therefore must be managed here.
		##

		device_fan_level_last="$device_fan_level"
		convert_fan_duty_to_fan_level "device_fan_level" "device"

		# modify cpu fan level only when device fan level is higher
		if [ "$device_fan_level" != "$device_fan_level_last" ]; then # 2/ device fan level changed
			if [ "$device_fan_level" = "maximum" ]; then # 3/
				cpu_fan_level="maximum"
			else # 3/ cpu fan level is not maximum, and device fan level is not maximum
				if [ "$cpu_fan_level" != "high" ] && [ "$device_fan_level" = "high" ]; then # 4/ one of them could be set to high
					cpu_fan_level="high"
				else # 4/ neither are set to high
					if [ "$cpu_fan_level" != "medium" ] && [ "$device_fan_level" = "medium" ]; then # 5/ one could be set to medium
						cpu_fan_level="medium"
					fi # 5/ when neither are set to medium, leave cpu fan level as-is
				fi # 4/
			fi # 3/
		fi # 2/
	fi # 1/

	[ "$cpu_fan_level" = "$cpu_fan_level_last" ] && return # nothing to do as fan level has not changed

	########################
	# CONTROLLED FAN DESCENT
	########################

	if [ "$cpu_fan_level" = "maximum" ] && [ "$cpu_fan_level_last" != "maximum" ]; then # 1/ just tripped max speed requirement
		debug_print 4 warn "CPU fans going to maximum speed"
	else # 1/ cooling demand might be declining

		##
		# Potentially reduce CPU fan speeds only when one of the following conditions are true:
		# 1. More than fan duty category + CPU temps are declining; OR
		# 2. Only one fan duty category + CPU temps are declining AND disk temps are declining
		##

		# determine whether declining temperature are substantial enough to warrant a change to CPU fan speeds
		if { [ "$only_cpu_fans" != true ] && (( cpu_temp_highest < cpu_temp_highest_last )) } || { [ "$only_cpu_fans" = true ] && (( cpu_temp_highest < cpu_temp_highest_last )) && (( device_avg_temp > 0 )) && (( device_avg_temp < device_avg_temp_last )) } ; then # 2/
			if [ "$cpu_fan_level" = "low" ]; then # 3/
				if [ "$cpu_fan_level_last" = "medium" ]; then # 4/

					# set trigger to 75% of delta between low and medium cpu temp thresholds
					trigger=$(( cpu_temp_low + ( ( cpu_temp_med - cpu_temp_low ) * 75 / 100 ) ))

					if (( cpu_temp_highest >= trigger )); then # 5/ current highest cpu temp is higher than or equal to range mid-point
						cpu_fan_level="$cpu_fan_level_last" # retain higher fan speed
					else # 5/ cross-check disk temp (single fan duty category scenario)
						if [ "$only_cpu_fans" = true ] && [ "$device_fan_level_last" = "medium" ]; then # 6/

							# set trigger to 75% of delta between disk temp thresholds
							trigger=$(( device_fan_duty_low + ( ( device_fan_duty_med - device_fan_duty_low ) * 75 / 100 ) ))

							if (( device_temp >= trigger )); then # 7/ higher or equal to the mid-point
								cpu_fan_level="$cpu_fan_level_last" # retain higher fan speed
							fi # 7/
						fi # 6/
					fi # 5/
				else # 4/ last cpu fan speed must be high

					# set trigger to 75% of delta between low and high cpu temp thresholds
					trigger=$(( cpu_temp_low + ( ( cpu_temp_high - cpu_temp_low ) * 75 / 100 ) ))

					(( trigger < cpu_temp_med )) && trigger=$((cpu_temp_med)) # ensure it's not too low

					if (( cpu_temp_highest >= trigger )); then # 5/ higher or equal to range mid-point
						cpu_fan_level="$cpu_fan_level_last" # retain higher fan speed
					else # 5/ when single fan duty category, cross-check disk temp
						if [ "$only_cpu_fans" = true ] && [ "$device_fan_level_last" = "$cpu_fan_level_last" ]; then # 6/ = medium?

							# set trigger to 75% of delta
							trigger=$(( device_fan_duty_low + ( ( device_fan_duty_high - device_fan_duty_low ) * 75 / 100 ) ))

							if (( device_temp >= trigger )); then # 7/ disk temps higher or equal to disk mid-point
								cpu_fan_level="$cpu_fan_level_last" # retain higher fan speed
							fi # 7/
						fi # 6/
					fi # 5/
				fi # 4/
			fi # 3/

			if [ "$cpu_fan_level" = "medium" ]; then # 3/ only possible remaining scenario is $cpu_fan_level_last = high

				# set trigger to 75% of delta between medium and high temp thresholds
				trigger=$(( cpu_temp_med + ( ( cpu_temp_high - cpu_temp_med ) * 75 / 100 ) ))


				if (( cpu_temp_highest >= trigger )); then # 4/ higher or equal to delta mid-point
					cpu_fan_level="$cpu_fan_level_last" # assign higher fan speed
				else # 4/ cross-check disk temp (single fan duty category scenario)
					if [ "$only_cpu_fans" = true ] && [ "$device_fan_level_last" = "$cpu_fan_level_last" ]; then # 5/ = high?

						# set trigger to 75% of delta
						trigger=$(( device_fan_duty_med + ( ( device_fan_duty_high - device_fan_duty_med ) * 75 / 100 ) ))

						if (( device_temp >= trigger )); then # 6/ disk temps still higher or equal to the mid-point
							cpu_fan_level="$cpu_fan_level_last" # retain higher fan speed
						fi # 6/
					fi # 5/
				fi # 4/
			fi # 3/
		fi # 2/
	fi # 1/

	# adjust CPU fan duty if it needs to be changed
	cpu_fan_duty=$(convert_cpu_fan_level_to_fan_duty "$cpu_fan_level") # find duty cycle (%age) corresponding to new fan level (low/med/high)

	if (( cpu_fan_duty != cpu_fan_duty_last )); then # 1/
		cpu_fan_duty_last=$((cpu_fan_duty)) # store prior value before it is changed
		set_fan_duty_cycle "cpu" $((cpu_fan_duty)) false
	fi # 1/
}
