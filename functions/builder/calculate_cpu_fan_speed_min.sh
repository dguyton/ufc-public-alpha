##
# Estimate minimum CPU fan speeds, based on one or more of the following:
#
# 1. Declared RPM floor (per config file)
# 2. Declared minimum CPU fan duty cycle (per config)
# 3. Pre-existing lower BMC fan speed thresholds
#
# fan_speed_min[cpu] speed acts as a floor. When specified, indicates
# the lowest fan speed RPM any CPU fan should be allowed to run at. This
# threshold is operational and independent of BMC LOWER thresholds.
#
# The minimum CPU fan speed deterministic logic is composed of 3 parts:
#
# 1. estimated RPM floor, which may be declared in config
# 2. modify the starting position based on declared min duty cycle
# 3. apply estimated minimums, probe reaction, adjust when necessary
#
# Practical minimum fan speeds are calculated through trial-and-error
# regardless of whether or not $cpu_fan_speed_min has a value set in the
# configuration file or not. It is also possible this value could be set
# in a .zone file, if [ -n "$log_filename" ] this method is not recommended.
#
# When the minimum CPU fan speed is declared in the configuration file,
# it acts as a de-facto floor. The value will be used as a starting point
# when probing actual minimums.
#
# The technique to arrive at a definitive minimum speed value involves
# taking either the pre-defined minimum target speed value defined in a
# configuration file, or creating a starting point based on a multiple of
# the BMC fan hysteresis interval.
#
# After determining the starting RPM target, its equivalent fan duty cycle
# PWM percentage is calculated based on the known maximum speeds of each
# CPU fan header. The highest ratio is applied as the initial starting
# level for minimum fan duty cycle %. The fan with the lowest maximum fan
# speed is normally the gating factor, and will tend to increase the
# minimum fan duty cycle. if [ -n "$log_filename" ], this is necessary when different fan
# types are present in the group of CPU cooling fans, as care must be
# exercised to ensure no fan is asked to spin too slowly, as this will
# lead to the BMC triggering panic mode when a request is made to set fan
# speeds to the minimum fan duty cycle. This is obviously not desirable.
#
# The fan headers are then probed. all CPU fans are spun down to their
# minimum duty cycle. Fan behavior is then observed. If panic mode is
# triggered, it is clear the fan duty level is too low, and is adjusted.
# This adjustment process continues until a fan duty floor is reached
# where panic mode is not triggered. If that is the case on the first fan
# duty cycle attempt, then the originally estimated fan duty cycle value
# is retained as the minimum for all CPU fans.
# 
# This prevents setting the minimum fan speed too low for slower fans when
# multiple fans are responsible for CPU cooling, as each may have different
# characteristics. Managing the lower limit based on the slowest fan prevents
# slower fans from stalling out, albeit at the expense of forcing faster fans
# to run at higher RPMs when set to the same duty cycle as the slower fans.
# if [ -n "$log_filename" ], this by-product is necessary to avoid any fan stalling, or cooling
# CPU(s) inadequately. This problem may be avoided by ensuring all fans
# responsible for CPU cooling are identical.
##

function calculate_cpu_fan_speed_min ()
{
	local cpu_fan_duty_calc				# temporary fan duty used in calculations
	local cpu_fan_speed_calc				# temporary fan speed used in calculations
	local fan_id

	local -a cpu_fan_list

	debug_print 2 "Estimate viable minimum CPU fan speeds"

	convert_binary_to_array "${fan_header_active_binary[cpu]}" "cpu_fan_list"

	##
	# Store minimum fan speed limit for each cpu fan, based on
	# each fan's LNC (Lower Non-Critical) BMC fan speed threshold,
	# plus an offset based on the fan hysteresis interval.
	#
	# Set minimum allowed speed for each CPU fan to the higher of the following values:
	# 	--> 1. $cpu_fan_speed_min RPM
	# 	--> 2. LNC (Lower Non-Critical) BMC threshold + 2x fan hysteresis
	# 	--> 3. 5x fan hysteresis
	#
	# Also record the highest corresponding CPU fan duty cycle percentage
	# associated with the minimum speed of each CPU fan. This ensures that
	# the minimum allowed CPU fan zone duty cycle will keep each CPU fan
	# operating at a speed no lower than the required minimum RPM
	##

	if (( fan_speed_min[cpu] == 0 )) && (( fan_duty_min[cpu] == 0 )); then # 1/ neither benchmark specified in config

		##
		# Estimate values for CPU minimum fan speed and fan duty
		#
		# When not starting with either specified value, estimate
		# minimum CPU fan speed and then validate both criteria.
		##

		debug_print 4 "Setting baseline minimum rotational fan speed for each CPU fan based on incumbent LCR values"

		for fan_id in "${!cpu_fan_list[@]}"; do # 1/ set logical floor for each cpu fan
			fan_speed_limit_min["$fan_id"]=$(( fan_speed_lcr[fan_id] + ( 2 * bmc_threshold_interval ) ))
			(( fan_speed_limit_min["$fan_id"] < $(( 3 * bmc_threshold_interval )) )) && fan_speed_limit_min["$fan_id"]=$(( 3 * bmc_threshold_interval ))
			(( fan_speed_limit_min["$fan_id"] > fan_speed_min[cpu] )) && fan_speed_min[cpu]="${fan_speed_limit_min[$fan_id]}" # retain highest speed of any cpu fan as de-facto minimum for now
		done # 1/

		# step above failed; cannot continue without viable fan duty estimate
		(( fan_speed_min[cpu] == 0 )) && bail_with_fans_optimal "Baseline CPU fan duty cycle could not be calculated from incumbent LCR speed threshold (BMC)" # baseline calcs failed

		# calculate minimum CPU fan duty starting point
		debug_print 4 "Estimate minimum CPU fan duty based on highest estimated minimum CPU rotational fan speed"
		for fan_id in "${!cpu_fan_list[@]}"; do # 1/ set min cpu fan duty to highest ratio of minimum speed to maximum speed
			cpu_fan_duty_calc="$(convert_rpm_to_duty_cycle "${fan_speed_min[cpu]}" "${fan_speed_limit_max[$fan_id]}")"

			if (( cpu_fan_duty_calc > fan_duty_min[cpu] )); then # 2/
				fan_duty_min[cpu]="$cpu_fan_duty_calc" # retain highest minimum duty cycle for now
				debug_print 4 "Adjusted minimum CPU fan duty cycle upward to ${fan_duty_min[cpu]}% based on ${fan_header_name[$fan_id]} min/max fan speeds"
			fi # 2/
		done # 1/

		# minimum fan duty conversion failed
		(( fan_duty_min[cpu] == 0 )) && bail_with_fans_optimal "Minimum CPU fan duty cycle could not be determined"
	fi # 1/

	##
	# Validate minimum CPU fan duty against maximum rotational speed limit of any CPU fan.
	#
	# Increase minimum CPU fan duty when fan will not reach minimum required rotational speed.
	#
	# Apply minimum CPU fan duty cycle against each CPU fan maximum speed. If this causes a fan to fail to meet
	# minimum CPU rotational fan speed requirement, then increase duty cycle until minimum fan speed is met.
	##

	if (( fan_duty_min[cpu] > 0 )) && (( fan_duty_min[cpu] < fan_duty_limit )); then # 1/ skip when fan duty not set or already at maximum
		for fan_id in "${!cpu_fan_list[@]}"; do # 1/
			cpu_fan_speed_calc="$(convert_duty_cycle_to_rpm "${fan_duty_min[cpu]}" "${fan_speed_limit_max[$fan_id]}")"

			# compare calculated equivalent RPM, but offset comparo to allow for natural fan speed fluctuations
			if (( cpu_fan_speed_calc > 0 )) && (( cpu_fan_speed_calc < $(( fan_speed_min[cpu] - bmc_threshold_interval )) )); then # 2/ duty cycle set too low
				fan_duty_min[cpu]="$(convert_rpm_to_duty_cycle "${fan_speed_min[cpu]}" "${fan_speed_limit_max[$fan_id]}")" # calculate higher duty cycle based on current fan ratio of min to max fan speed
				debug_print 3 "Min CPU fan duty cycle raised to ${fan_duty_min[cpu]}% to resolve fan duty/min speed discrepancy"
			fi # 2/
		done # 1/
	fi # 1/

	##
	# Cap minimum CPU rotational fan speed limit at no higher than slowest CPU fan max speed limit.
	#
	# Limit minimum CPU rotational fan speed requirement to no greater than maximum speed of any CPU fan.
	##

	# min cpu fan speed cannot be greater than max speed of any cpu fan
	debug_print 4 "Restrict CPU fan speed min <= slowest max CPU fan speed"

	for fan_id in "${!cpu_fan_list[@]}"; do # 1/ lower global min to max rpm of current fan when min fan speed too high for current fan to handle
		if (( fan_speed_limit_max[$fan_id] > 0 )) && (( fan_speed_min[cpu] >= fan_speed_limit_max[$fan_id] )); then # 2/ past limit of current fan
			debug_print 4 "Reduce minimum CPU fan speed to prevent slowest fan from triggering false alerts in Service program"
			fan_speed_min[cpu]="${fan_speed_limit_max[$fan_id]}" # reduce min cpu fan speed requirement to level slowest fan is capable of to avoid false fan alerts in Service program

			if (( fan_duty_min[cpu] < fan_duty_limit )); then # 3/ all CPU fans must be run at 100% duty cycle to keep current fan at required min speed
				fan_duty_min[cpu]="$fan_duty_limit"
				debug_print 4 caution "${fan_header_name[$fan_id]} maximum fan speed is less than declared or calculated minimum CPU fan speed threshold"
				debug_print 3 "CPU fans must be run at maximum duty cycle in order to meet minimum rotational speed requirements"
			fi # 3/
		fi # 2/
	done # 1/

	##
	# Reset minimum CPU fan duty cycle after above validation steps.
	#
	# If minimum fan speed requirement causes any fan to need to be set to its maximum fan speed,
	# then ensure minimum fan duty = maximum fan duty limit and move on to next step.
	##

	debug_print 4 "Validate minimum CPU fan duty cycle after estimation"

	for fan_id in "${!cpu_fan_list[@]}"; do # 1/ set min cpu fan duty to highest ratio of minimum speed to maximum speed for any cpu fan
		(( fan_duty_min[cpu] == fan_duty_limit )) && break # maximum reached for at least one fan, nothing more to do here
		cpu_fan_duty_calc="$(convert_rpm_to_duty_cycle "${fan_speed_min[cpu]}" "${fan_speed_limit_max[$fan_id]}")"

		if (( cpu_fan_duty_calc > fan_duty_min[cpu] )); then # 1/
			debug_print 4 "Increase CPU fan duty cycle to match ratio of min CPU fan speed to ${fan_header_name[$fan_id]} max speed"
			fan_duty_min[cpu]="$cpu_fan_duty_calc"
		fi # 1/
	done # 1/

	(( fan_duty_min[cpu] > fan_duty_limit )) && fan_duty_min[cpu]="$fan_duty_limit"

	# re-validate CPU minimum fan duty cycle to align with minimum fan speed, relative to each CPU fan maximum
	for fan_id in "${!cpu_fan_list[@]}"; do # 1/
		cpu_fan_speed_calc="$(convert_duty_cycle_to_rpm "${fan_duty_min[cpu]}" "${fan_speed_limit_max[$fan_id]}")"

		if (( cpu_fan_speed_calc < fan_speed_min[cpu] )) && (( cpu_fan_duty_calc > 0 )); then # 1/ duty cycle set too low
			debug_print 4 "Duty cycle too low"

			fan_duty_min[cpu]="$(convert_rpm_to_duty_cycle "${fan_speed_min[cpu]}" "${fan_speed_limit_max[$fan_id]}")" # bump min duty cycle higher to fix

			debug_print 4 "Current min CPU fan duty would cause ${fan_header_name[$fan_id]} to fail to meet min CPU fan speed"
			debug_print 3 "Increased min CPU fan duty cycle to ${fan_duty_min[cpu]}% to resolve fan duty/min speed discrepancy"
		fi # 1/
	done # 1/

	##
	# Bail when a minimum speed for CPU cooling fans could not be determined or seems invalid.
	#
	# Cannot continue when no declared or deduced minimum fan speed nor minimum cpu fan duty.
	##

	(( fan_duty_min[cpu] == 0 )) && bail_with_fans_optimal "Could not determine viable minimum CPU fan speed duty cycle"

	if (( fan_duty_min[cpu] > fan_duty_limit )); then # 1/
		debug_print 3 critical "Minimum CPU fan duty cannot be set because it would exceed global fan duty limiter"
		debug_print 4 "Raise global maximum fan duty limit in configuration file or examine CPU fans for discrepancies"

		bail_with_fans_optimal "Calculated or declared CPU minimum fan duty exceeds universal maximum fan duty limiter"
	fi # 1/

	debug_print 2 "Minimum CPU fan group duty cycle confirmed at ${fan_duty_min[cpu]}%"
	debug_print 3 "Revise minimum fan speed RPM thresholds of CPU cooling fans"

	##
	# Now that a floor for CPU fan zone duty cycle has been established,
	# it needs to be applied to every CPU fan such that a minimum fan 
	# speed for each fan is assigned independently. Tthis allows granular
	# fan monitoring on a per fan basis by the Service program.
	##

	# re-calibrate each cpu fan minimum speed limit based on its max speed and the min duty cycle
	for fan_id in "${!cpu_fan_list[@]}"; do # 1/
		if (( fan_speed_limit_max[$fan_id] > 0 )); then # 1/
			fan_speed_limit_min["$fan_id"]="$(convert_duty_cycle_to_rpm "${fan_duty_min[cpu]}" "${fan_speed_limit_max[$fan_id]}")"
		else # 1/ generic estimate
			if (( fan_speed_lowest_max[cpu] > 0 )); then # 2/
				fan_speed_limit_min["$fan_id"]="$(convert_duty_cycle_to_rpm "${fan_duty_min[cpu]}" "${fan_speed_lowest_max[cpu]}")"
			else # 2/
				debug_print 4 warn "Missing or invalid value (${fan_speed_lowest_max[cpu]}) for '\${fan_speed_lowest_max[cpu]}'" true
			fi # 2/
		fi # 1/

		debug_print 4 "${fan_header_name[$fan_id]} (ID $fan_id) duty cycle $(printf "%3d" "${fan_duty_min[cpu]}")% = estimated fan speed: $cpu_fan_speed_calc RPM"
	done # 1/
}
