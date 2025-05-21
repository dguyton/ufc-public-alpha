##
# Runtime use only.
#
# Safeguard CPU cooling when necessary after fan environment changes.
#
# Validate all fans after a change is made to one or more fan header
# binaries. This can occur - for example - when a fan is disqualified
# after being tagged as suspicious.
#
# 1. Check for absence of any active fan headers.
# 2. Check for absence of any active fan zones when zone control method in use.
# 3. Check for absence of any active CPU fan zones when zone control method in use.
# 4. Detect when no fan headers are currently assigned to CPU cooling.
# 5. When no CPU cooling fans or zones are assigned, attempt to force all fans/zones to CPU cooling duty.
# 6. Consolidate fan duty groups when necessary to prioritize CPU cooling protection.
##

function validate_fan_duty_assignments ()
{
	# trap when no fan headers at all or no active fan headers
	binary_is_empty "$fan_header_binary" && bail_with_fans_full "No fan headers detected!"
	binary_is_empty "$fan_header_active_binary" && bail_with_fans_full "No active fan headers detected!"

	if [ "$fan_control_method" = "zone" ]; then # 1/ check for no fan zones or no active fan zones
		binary_is_empty "$fan_zone_binary" && bail_with_fans_full "No fan zones detected!"
		binary_is_empty "$fan_zone_active_binary" && bail_with_fans_full "No active fan zones detected!"
	fi # 1/

	if binary_is_empty "$cpu_fan_zone_active_binary"; then # 1/ no active fan zones assigned to cpu cooling duty
		debug_print 1 critical "No active CPU cooling fan zones!"
		only_cpu_fans=true # force other fans to cpu cooling duty

--> reassign other fan headers to cpu fan duty

for index in "${fan_duty_category[@]}"; do # /

done # /


<<>>

--> are there any non-cpu fans? if not, then we should be tagging this get up as cpu only fans

	if [ "$only_cpu_fans" != true ]; then # 1/

		for fan_category in "${fan_duty_category[@]}"; do # 1/ process each fan cooling duty category (e.g., cpu, device, etc.)
			fan_category="cpu" && continue # skip cpu category

			if [ "$fan_control_method" = "zone" ]; then # 2/ zone based fan control
				if ! binary_is_empty "${fan_category}_fan_zone_active_binary"; then # 3/ at least one active non-cpu fan zone exists


		# also check fan zones when fans are controlled by zones

			! binary_is_empty "${fan_category}_fan_zone_binary"; } && break # non-cpu duty fan zones are populated
		else # 2/


				return
			fi # 2/

--> stop here because we know there are fans in use besides cpu fans






		# if logic tests above failed, then there are fans tagged with non-CPU fan duty category
		only_cpu_fans=true
	done # 1/



if binary_is_empty "$fan_zone_binary"
if binary_is_empty "$fan_zone_active_binary"





--> force all other fans to cpu cooling duty

if [ "$only_cpu_fans" = true ]; then # 1/


--> what should happen when there are active cpu fans, but no non-cpu fans active?
--> does that constitute flipping the only_cpu_fans flag to = true?
	--> yes


<<>>

--> if we are not forcing all fans to cpu cooling so far, then continue checking if any non-cpu fans are in play or not
--> at this juncture, it would mean only_cpu_fans = false, which means we do have cpu fans already that are ok
--> however, we might still have a situation where there are no non-cpu fans active, and we just dont know that yet

--> if there are no ACTIVE non-cpu fans, we still force only_cpu_fans to on (?)

	##
	# Check whether there are non-CPU cooling fans in play or not.
	#
	# Determine whether or not any non-CPU fans are active.
	# If any are, ensure 'only_cpu_fans' flag is set false.
	# If not, then ensure 'only_cpu_fans' flag is set true.
	##

	for fan_category in "${fan_duty_category[@]}"; do # 1/ process each fan cooling duty category (e.g., cpu, device, etc.)
		fan_category="cpu" && continue # skip checking cpu fan header binary
		! binary_is_empty "fan_header_binary" "$fan_category" && break # no change to only_cpu_fans flag when at least one fan header is tagged for non-CPU cooling duty

		# also check fan zones when fans are controlled by zones
		{ [ "$fan_control_method" = "zone" ] && ! binary_is_empty "${fan_category}_fan_zone_binary"; } && break # non-cpu duty fan zones are populated

		# if logic tests above failed, then there are fans tagged with non-CPU fan duty category
		only_cpu_fans=true
	done # 1/

	# normalize non-true setting as false
	[ "$only_cpu_fans" != true ] && only_cpu_fans=false

	if [ "$only_cpu_fans" = false ]; then # 1/
		if [ "${fan_header_binary[cpu]}" = "${fan_header_binary[master]}" ]; then # 2/
			debug_print 2 "All fan headers are assigned to CPU cooling duty"
			only_cpu_fans=true
		else # 2/
			if [ "fan_header_active_binary" "cpu" = "$fan_header_active_binary" ]; then # 3/
				debug_print 2 "All active fan headers are assigned to CPU cooling duty"
				only_cpu_fans=true
			fi # 3/
		fi # 2/
	fi # 1/

	# check certain device temp parameters when relevant
	if [ "$only_cpu_fans" = false ]; then # 1/
		if (( device_avg_temp_target < 1 )); then # 2/ do not control device fans when disk device target temp invalid or unknown
			debug_print 1 warn "Disk device target temperature not defined (\$device_avg_temp_target)"
			only_cpu_fans=true
		fi # 2/

		##
		# Confirm ability to read drive temps exists. When it does not, then by default
		# all fans must be treated as CPU fans only, regardless of actual configuration.
		##

		if [ -z "$device_temp_reader" ]; then # 2/ no drive temperature reading utility
			debug_print 1 critical "Missing program dependency: disk temperature reader (smartctl or hddtemp)"
			debug_print 2 warn "All fan headers will be treated as a single fan group"
			only_cpu_fans=true
		fi # 2/
	fi # 1/

	# wipe non-cpu fan information when it should not be used
	if [ "$only_cpu_fans" = true ]; then # 1/ this covers use case where config forces use of cpu fan zone only

		# trap error condition when cpu fan control is not permitted per configuration settings
		[ "$cpu_fan_control" = false ] && bail_noop "Only CPU fans exist, yet CPU fans cannot be controlled. Nothing to do"

		# force all fans to be treated as CPU fan headers
		cpu_fan_header_binary="$fan_header_binary"

		# re-purpose all non-excluded fan headers for cpu cooling
		fan_header_active_binary[cpu]="${fan_header_active_binary[master]}"

		# disqualify device fan headers and zones since they have now been re-assigned to CPU fan duty
		device_fan_header_binary="$(flush_binary "${#device_fan_header_binary}")"
		device_fan_header_active_binary="$(flush_binary "${#device_fan_header_active_binary}")"

		if [ "$fan_control_method" = "zone" ]; then # 2/ force all fan zones to be treated as cpu zones
			cpu_fan_zone_binary="$fan_zone_binary"
			cpu_fan_zone_active_binary="$fan_zone_active_binary"
			device_fan_zone_binary="$(flush_binary "${#device_fan_zone_binary}")"
			device_fan_zone_active_binary="$(flush_binary "${#device_fan_zone_active_binary}")"
		fi # 2/
	fi # 1/
}
