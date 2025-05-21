# When fans are controlled, validate CPU temperature controls and override temperature.
function validate_cpu_temperature_thresholds ()
{
	if (( cpu_temp_med < cpu_temp_low + 10 )); then # 1/ ensure at least 10 degrees of separation between CPU temperature thresholds
		debug_print 2 "Adjusted medium CPU temperature threshold (cpu_temp_med) upward because it was too low"
		cpu_temp_med=$(( cpu_temp_low + 10 ))
		debug_print 3 "CPU medium temp threshold now set to $cpu_temp_med deg C"
	fi # 1/

	if (( cpu_temp_high < cpu_temp_med + 10 )); then # 1/
		debug_print 2 "Adjusted <HIGH> CPU temperature threshold (cpu_temp_high) upward because it was too low"
		cpu_temp_high=$(( cpu_temp_med + 10 ))
		debug_print 3 "CPU high temp threshold now set to $cpu_temp_high deg C"
	fi # 1/

	if [ "$cpu_temp_override" -gt 0 ] && [ "$cpu_temp_override" -lt "$cpu_temp_high" ]; then # 1/ set cpu override temperature automatically when not pre-defined
		cpu_temp_override=$(( cpu_temp_high + 10 ))
		debug_print 2 caution "CPU panic mode trigger (cpu_temp_override) needs to be 10+ degrees > High CPU temp (cpu_temp_high)"
	fi # 1/
}
