##
# Device fan override mode boosts disk cooling fans to maximum to help cool CPUs.
# $device_fan_override state may be true, false, or NULL.
#
# Decide when to activate CPU panic mode and when to de-activate it.
# The criteria for activating it is when the highest CPU core temperature
# has exceeded the alarm/override level for two consecutive temp readings,
# AND the most recent CPU temperature reading is not less than the last
# reading, indicating the spike in CPU temps was not a one-time anomaly.
#
# The idea here is to avoid knee-jerk reactions to implementing fan panic
# mode and spiking fan speeds higher when a rapid CPU temp increase is
# likely a momentary spike for some reason. Yet on the other hand, it is
# important to compensate sustained CPU temperature increases as soon as
# possible, to cool them off, avoid damage to the CPUs, and to prevent the
# disk devices from getting too hot from residual heat off the CPUs.
#
# Validate whether or not cpu panic mode conditions exist, and if
# current disk device fan duty cycle should be overridden to help cool CPU.
# Try to avoid engaging panic mode when burst in CPU temp may be a temporary spike.
#
# Activate Disk Device fan zone override when the following conditions are true:
# 1. Disk fans are currently not in override mode; and
# 2. CPU temperature >= CPU panic mode trigger temp (CPU is too hot); and
# 3. Previous CPU temp reading was >= CPU panic mode trigger temp; and
# 4. CPU fan duty cycle is currently in high fan speed mode (true by default if # 2 was true); and
# 5. Previous CPU fan duty cycle was also in high fan speed mode (true by default if # 3 was true); and
# 6. CPU temp did not decline between current and previous temperature readings.
#
# De-activate disk device fan zone override when the following conditions are true:
# 1. Disk Device fans are currently in override mode; and
# 2. CPU temperature has fallen below critical temp level for 2 consecutive cpu temp read cycles
##

function validate_device_fan_override_mode ()
{
	# when disk device fan panic mode is active, determine if it should be deactivated
	if [ "$device_fan_override" = true ]; then # 1/ cpu panic mode active during last cycle
		if (( cpu_temp_highest < cpu_temp_override )); then # 2/ cpu temps are below panic level
			if (( cpu_temp_highest_last < cpu_temp_override )); then # 3/ last cpu temp was also below the panic threshold
				if (( cpu_temp_highest < cpu_temp_highest_last )); then # 4/ cpu temp pattern is declining
					if (( device_avg_temp < device_max_allowed_temp )); then # 5/ average disk temp is below max allowed disk temp
						if (( device_highest_temp < device_max_allowed_temp )); then # 6/ hottest disk temp is below max allowed disk temp
							if (( device_avg_temp < device_avg_temp_last )); then # 7/ average disk temps are declining
								debug_print 3 "CPU temperature dropped below critical threshold."
								device_fan_override=false # disk device zone fan panic mode no longer necessary

								# restore disk device fan zone fan level to previous state
								debug_print 2 "CPU panic mode de-activated. Restoring Disk Device fan speeds to nominal setting."

<<>>

--> needs re-factoring to support fan categories

								set_fan_duty_cycle "device" $((device_fan_duty)) true # restore disk device zone fan speed back to what its duty cycle should be

								# restore cpu fan zone fan level to previous state
								debug_print 3 "Standing down CPU fan speeds from level $cpu_fan_level back to $cpu_fan_level_last."
								cpu_fan_level="$cpu_fan_level_last" # when exiting cpu panic mode, restore cpu_fan_level back to its former state
								set_fan_duty_cycle "cpu" "$(convert_cpu_fan_level_to_fan_duty "$cpu_fan_level")" true # restore cpu fans to their previous level
							fi # 7/
						fi # 6/
					fi # 5/
				fi # 4/
			fi # 3/
		fi # 2/
	else # 1/ not currently in cpu panic / disk device fan override mode; check to see if it should be
		if (( cpu_temp_highest >= cpu_temp_override )) && (( cpu_temp_highest_last >= cpu_temp_override )) && (( cpu_temp_highest >= cpu_temp_highest_last )); then # 2/ yes
			device_fan_override=true # cpu fans need help
			set_fan_duty_cycle "cpu" $((cpu_fan_duty_max)) true # push cpu fans to max speed
			set_fan_duty_cycle "device" $((device_fan_duty_max)) true # push disk device fans to max speed
			debug_print 2 warn "CPU panic mode activated. Spinning up case fans for emergency cooling of CPU(s)."
			debug_print 3 warn "CPU temperature exceeded \$cpu_temp_override threshold ($cpu_temp_override degrees C)."
		fi # 2/ current cpu temp critical check
	fi # 1/
}
