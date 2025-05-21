##
# Calculate and return estimated RPM corresponding to specified duty cycle
# percentage, based on current speed vs max speed of the fan.
#
# Purpose of this sub-routine is to calculate what a fan's expected RPM is,
# based on its duty cycle percentage.
#
# Force adjust fan duty cycle when indicated value is below specified threshold.
# Most fans do not ramp in a linear fashion, especially at very low speeds.
# Therefore, literal values are presumed to be inaccurate and/or would stall
# most fans. The default threshold is < 25% fan duty, based on PWM patterns.
#
# Align result with fan hysteresis (when known) to keep results consistent
# with potential observed fan speed values (which will always be a multiple
# of fan hysteresis).
##

function convert_duty_cycle_to_rpm ()
{
	local fan_duty_cycle
	local fan_duty_cycle_input
	local fan_speed_limit
	local result

	fan_duty_cycle_input="$1"
	fan_speed_limit="$2"

	##
	# When fan duty is very low, use a percentage offset when calculating
	# associated RPM level. Adjust raw reported fan speed reading to account
	# for skewed raw fan speeds. Default threshold is < 25% PWM and default
	# adjustment is to add 10% to raw reported fan RPM speed.
	##

	(( low_duty_cycle_offset < 1 )) && low_duty_cycle_offset=10
	(( low_duty_cycle_threshold < 1 )) && low_duty_cycle_threshold=25

	# pad low speeds since nearly all mobos undervolt the fans at low duty cycles
	if (( fan_duty_cycle_input < low_duty_cycle_threshold )); then # 1/
		fan_duty_cycle=$(( fan_duty_cycle + low_duty_cycle_offset ))

		if (( fan_duty_cycle_input > low_duty_cycle_threshold )); then # 2/
			fan_duty_cycle_input=$((low_duty_cycle_threshold))
		fi # 2/

		debug_print 4 caution "Adjusted low fan duty cycle input value to $fan_duty_cycle_input"

	else # 1/
		fan_duty_cycle="$fan_duty_cycle_input"
	fi # 1/

	# cannot be > max limit, which could be less than 100
	(( fan_duty_cycle > fan_duty_limit )) && fan_duty_cycle="$fan_duty_limit"

	result=$(( ( fan_speed_limit * fan_duty_cycle ) / 100 ))

	# round result up to nearest fan hysteresis, when known
	(( bmc_threshold_interval > 0 )) && result=$(( ( ( result / bmc_threshold_interval ) + 1 ) * bmc_threshold_interval ))

	printf "%d" "$result" # return result
}
