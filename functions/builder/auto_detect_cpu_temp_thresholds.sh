##
# Automatically determine high and critical CPU temperatures from hardware info.
# Requires presence of lm-sensors program.
#
# Lowest temperature is retained as the de-facto threshold.
# For critical temperature threshold, if a value is pre-defined in the config file,
# and that value is lower than the auto-detected values reported by the CPU(s), the
# lower value will be retained.
#
# Note some tools (such as lm-sensors) start CPU ID numbering at 0, while other
# tools (e.g. ipmitool) begin CPU ID numbering at 1.
##

function auto_detect_cpu_temp_thresholds ()
{
	local cpu_data
	local cpu_id
	local -a cpu_temp_sensors_critical
	local -a cpu_temp_sensors_high
	local temperature
	local var_temp

	if [ "$cpu_temp_sensor" != "sensors" ]; then # 1/ auto detection only works with lm-sensors
		if [ "$auto_detect_cpu_high_temp" = true ] || [ "$auto_detect_cpu_critical_temp" = true ]; then # 2/
			debug_print 3 caution "Validation of high/critical CPU temperature settings not available (lm-sensors not installed)"
			auto_detect_cpu_critical_temp=false
			auto_detect_cpu_high_temp=false
			return
		fi # 2/
	fi # 1/

	if [ -z "$numcpu" ] || [ "$numcpu" -lt 1 ]; then # 1/
		debug_print 2 warn "'numcpu' is unset or invalid, skipping CPU temperature auto-detection"
		auto_detect_cpu_critical_temp=false
		auto_detect_cpu_high_temp=false
		return
	fi # 1/

	ipmi_sensor_column_cpu_temp[high]="$(printf "%.0f" "${ipmi_sensor_column_cpu_temp[high]//[!0-9.]/}")" # normalize value with default of 0
	ipmi_sensor_column_cpu_temp[critical]="$(printf "%.0f" "${ipmi_sensor_column_cpu_temp[critical]//[!0-9.]/}")"

	debug_print 3 "Auto-detect of CPU high temperature thresholds: $auto_detect_cpu_high_temp"
	debug_print 3 "Auto-detect of CPU critical temperature thresholds: $auto_detect_cpu_critical_temp"

	if [ "$auto_detect_cpu_high_temp" = true ]; then # 1/
		debug_print 4 "Auto-detect CPU high temperature threshold"

		if [ "${ipmi_sensor_column_cpu_temp[high]}" -lt 1 ]; then # 3/
			auto_detect_cpu_high_temp=false
			debug_print 3 warn "Automatic CPU high temperature detection requested, but {lm-sensors} data column is undefined or invalid"
		else # 2/

			for (( cpu_id=0; cpu_id<numcpu; cpu_id++ )); do # 1/ cycle through each physical cpu, beginning with ID 0
				while read -r cpu_data; do # 2/
					unset var_temp

					if parse_ipmi_column "var_temp" "sensor" "cpu" "high" "$cpu_data" "temp"; then # 2/ ipmi_sensor_column_cpu_temp[high]
						cpu_temp_sensors_high[cpu_id]="$var_temp"
					fi # 2/

				done <<< "$(sensors "coretemp-isa-00$(printf "%02d" "$cpu_id")" | grep -i -E "core [0-9]+:")" # 2/ multi-line output of active cores belonging to current cpu id
			done # 1/

			##
			# Choose the lowest auto-detected 'high' CPU temperature threshold among
			# all CPUs and apply it as the 'high' CPU temperature for all CPUs.
			#
			# Use high temp from config file (if any) as the baseline.
			##

			# set the CPU high temp threshold to the lowest of all CPUs
			temperature="$cpu_temp_high"

			for (( cpu_id=0; cpu_id<numcpu; cpu_id++ )); do # 1/
				[ "${cpu_temp_sensors_high[$cpu_id]}" -gt 0 ] && [ "${cpu_temp_sensors_high[$cpu_id]}" -lt "$temperature" ] && cpu_temp_high="${cpu_temp_sensors_high[$cpu_id]}"
			done # 1/

			debug_print 2 "High CPU temperature threshold automatically detected and assigned: $cpu_temp_high degrees C"
		fi # 2/
	fi # 1/

	if [ "$auto_detect_cpu_critical_temp" = true ]; then # 1/
		if [ "${ipmi_sensor_column_cpu_temp[critical]}" -lt 1 ]; then # 2/
			auto_detect_cpu_critical_temp=false
			debug_print 3 warn "Automatic CPU critical temperature detection requested, but {lm-sensors} data column is undefined or invalid"
		else # 2/ retain lowest temperature as critical CPU temperature benchmark

			[ "$cpu_temp_override" -gt 0 ] && debug_print 3 "Critical CPU temperature threshold declared in config file: $cpu_temp_override degrees C"

			for (( cpu_id=0; cpu_id<numcpu; cpu_id++ )); do # 1/ cycle through each physical cpu, beginning with ID 0
				while read -r cpu_data; do # 2/
					unset var_temp

					if parse_ipmi_column "var_temp" "sensor" "cpu" "critical" "$cpu_data" "temp"; then # 3/ # ipmi_sensor_column_cpu_temp[critical]
						cpu_temp_sensors_critical[cpu_id]="$var_temp"
					fi # 3/

				done <<< "$(sensors "coretemp-isa-00$(printf "%02d" "$cpu_id")" | grep -i -E "core [0-9]+:")" # 2/ multi-line output of active cores belonging to current cpu id
			done # 1/

			##
			# Choose the lowest 'critical' CPU temperature threshold among all CPUs and
			# apply it as the 'critical' CPU temperature for all CPUs.
			#
			# Critical temp from config file (if any) is the baseline. If a lower temp
			# is auto-detected as a threshold temp, the lower value is retained.
			#
			# If the critical temp threshold cannot be determined automatically, the
			# declared value (if any) is retained as $cpu_temp_override value.
			##

			unset temperature # force use of detected critical threshold

			for (( cpu_id=0; cpu_id<numcpu; cpu_id++ )); do # 1/
				if [ -n "${cpu_temp_sensors_critical[cpu_id]}" ] && [ "${cpu_temp_sensors_critical[cpu_id]}" -gt 0 ]; then # 2/
					debug_print 4 "CPU ID $cpu_id reported critical temperature threshold: ${cpu_temp_sensors_critical[cpu_id]}"
					if [ -z "$temperature" ] || (( cpu_temp_sensors_critical[cpu_id] < temperature )); then # 3/
						temperature="${cpu_temp_sensors_critical[$cpu_id]}"
					fi # 3/
				else # 2/
					debug_print 4 "CPU ID $cpu_id has no manufacturer indicated critical temperature threshold"
				fi # 2/
			done # 1/

			if [ -z "$temperature" ]; then # 2/ auto-detect failed
				debug_print 3 warn "Auto-detection of CPU critical temperature threshold failed"

				if (( cpu_temp_override > 0 )); then # 3/ revert to pre-config override temperature from config file if available
					debug_print 3 "Retained temperature override setting from config"
				else # 3/
					debug_print 3 caution "Critical CPU temperature threshold unknown"
				fi # 3/
			else # 2/ success
				if (( temperature < cpu_temp_override )); then # 3/
					debug_print 3 "Declared critical CPU temp threshold ($cpu_temp_override) overridden by lower detected critical value ($temperature deg C)"
					cpu_temp_override="$temperature"
				else # 3/
					debug_print 3 "Retained temperature override setting from config"
				fi # 3/
			fi # 2/

			if (( cpu_temp_override > 0 )); then # 2/
				debug_print 2 "Assigned critical CPU temperature threshold: $cpu_temp_override"
			else # 2/ could not determine critical cpu temp
				auto_detect_cpu_critical_temp=false
				debug_print 3 warn "Attempts to assign critical CPU temperature threshold were unsuccessful"
			fi # 3/
		fi # 2/
	fi # 1/
}
