##
# Confirm at least one CPU cooling fan is active
#
# Try failsafe recovery by reassigning all fans to CPU cooling duty.
##

function enforce_cpu_cooling_priority ()
{
	# trap scenario where no CPU fan zones are active
	if binary_is_empty "$fan_header_active_binary"; then # 1/ no active fans at all
		bail_with_fans_full "No actively cooling fans are available!"
	fi # 1/

	if binary_is_empty "fan_header_active_binary" "cpu"; then # 1/ no active fans cooling cpu
		debug_print 1 caution "No fans designated for CPU cooling duty"

		if [ "$only_cpu_fans" = true ]; then # 2/ cpu fan only mode already in use means failsafe measures already in use
			bail_with_fans_full "No active fans available for CPU cooling duty assignment"
		fi # 2/

		only_cpu_fans=true

		# attempt to reassign all fans to CPU cooling duty
		validate_cpu_fan_headers

		# attempt to reconfigure active fan header states
		calibrate_active_fan_headers

		if binary_is_empty "fan_header_active_binary" "cpu"; then # 2/ still no active fans cooling cpu
			bail_with_fans_full "No fans designated for CPU cooling duty"
		fi # 2/

		debug_print 1 "Failsafe CPU fan-only mode engaged"

		# reconfigure fan zone assignments
		calibrate_active_fan_zones
	fi # 1/
}
