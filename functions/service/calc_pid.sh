# calculate P.I.D. values for disk device cooling fans
function calc_pid ()
{
	# PID related disk device calculation trackers (floating point)
	local proportional		# PID proportional baseline (before constant is applied)
	local integral			# PID integral baseline
	local derivative		# PID derivative baseline

	# only calculate new PID when average temperature recently changed
	(( device_avg_temp_delta == device_avg_temp_delta_last )) && return

	# cumulative error calc
	device_avg_temp_delta_cumulative="$(printf "%.3f" "$(awk "BEGIN { print ( $device_avg_temp_delta_cumulative + $device_avg_temp_delta ) }")")"

	##
	# "error" = delta between current temperature and target temperature (set point)
	# proportional = pid_Kp * current error
	# integral = pid_Ki * ( ( current error * time interval between temperature polling calculations ) + cumulative error )
	# derivative = pid_Kd * ( ( current error - previous error ) / time interval between temperature polling calculations )
	##

	proportional="$(printf "%.3f" "$(awk "BEGIN { print ( $device_avg_temp_delta ) }")")" # avg temp deviation from set point adjusted by time between temp checks
	integral="$(printf "%.3f" "$(awk "BEGIN { print ( ( $device_avg_temp_delta * ( $device_temp_polling_interval / 60 ) ) + $device_avg_temp_delta_cumulative ) }")")" # cumulative proportional values cause more rapid adjustments when rate of change is not declining
	derivative="$(printf "%.3f" "$(awk "BEGIN { print ( ( $device_avg_temp_delta - $device_avg_temp_delta_last ) / ( $device_temp_polling_interval / 60 ) ) }")")" # slope of average temp change over time

	##
	# This program uses a simplified form of Parallel PID Control Equation.
	#
	# The PID values are additive to the previous hd duty cycle + PID percentage.
	# This causes the PID to smooth the duty cycle when moving in the same direction as the last reading.
	# Likewise, when the temperature trend reverses, it will gradually pick up momentum.
	#
	# 'P' is the product of the mean temperature deviation and a constant (pid_Kp).
	#	--> 'P' is closely related to (but no the same as) the integral ($integral).
	#	--> 'P' is a positive number when current average disk temperature is greater than the target average temperature (set point)
	#	--> Both P and I utilize the current cycle integral value, but otherwise differ in two important ways:
	# 		1) The stored integral ($integral) is cumulative. $integral is stateful. The current cycle is added to the prior cycle's integral.
	# 		2) P ($pid_P) is the product of a constant ($pid_Kp) and the current cycle integral only. Thus P is a non-cumulative value.
	#
	# 'I' is the product of the cumulative integral and a constant (pid_Ki).
	#	--> 'I' is a bit odd. Notice the cumulative integral ($integral) is used to determine I ($I), yet the CURRENT integral is used to calculate P ($pid_P).
	#	--> If you think about this for a moment, you will see why most people choose to ignore 'I' ($I) by setting its pid_Ki ($pid_Ki) constant to zero.
	#	--> 'I' (integral) has the effect of exacerbating the current trend 'P' (proportional), resulting in larger fan duty adjustments between polling intervals.
	#	--> The larger the difference between pid_Ki and pid_Kp, the more pronounced the effect of pid_Ki.
	#
	# 'D' is the Derivative and should not be used alone (i.e. setting P and I to 0).
	#	--> Purpose of Derivative is to augment Proportional and Integral readings.
	#	--> Derivative enhances the effect of P + I when the temperature trend is accelerating or static.
	##

	# use globals for current hd duty and PID formulas to keep them persistent between adjustments
	pid_P="$(printf "%.3f" "$(awk "BEGIN { print ( $pid_Kp * $proportional ) }")")"
	pid_I="$(printf "%.3f" "$(awk "BEGIN { print ( $pid_Ki * $integral ) }")")"
	pid_D="$(printf "%.3f" "$(awk "BEGIN { print ( $pid_Kd * $derivative ) }")")"

	##
	# The P.I.D. is independent of the duty cycle, but
	# is added to the duty cycle to generate a new duty
	# cycle consisting of current duty cycle + offset,
	# where the offset is tied to current deviation of
	# disk temperature averages from the target temp.
	##

	device_fan_duty_pid_last="$device_fan_duty_pid" # save previous value
	device_fan_duty_pid="$(printf "%.3f" "$(awk "BEGIN { print ( $device_fan_duty + $pid_P + $pid_I + $pid_D ) }")")" # previous value is used to calculate new value, using updated PID

	debug_print 2 "Average disk temperature deviation from mean target temp: $device_avg_temp_delta degrees C."
	debug_print 3 "Raw P.I.D. duty cycle: $device_fan_duty_pid"
	debug_print 4 "P.I.D. corrections are P = $pid_P, I = $pid_I and D = $pid_D"
}
