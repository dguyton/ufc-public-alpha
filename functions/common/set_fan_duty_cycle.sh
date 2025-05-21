# set new fan speed target for a given fan duty group/type (e.g., cpu or device fans)
function set_fan_duty_cycle ()
{
	local fan_duty_new		# target duty cycle expressed as PWM percentage
	local fan_id			# numeric ID number of a fan (normally starts with 0)
	local -l force			# when true, force fan speed updates even when requested speed equals current speed
	local -l fan_category_name		# category of fans to control
	local target_fan_duty_last
	local target_fan_duty_max
	local target_fan_duty_min
	local write_position	# write order position for direct and group fan control methods
	local zone_id 			# zone ID number

	local -a fan_array
	local -a -l target_fan_duty_category
	local -a zone_array

	fan_category_name="$1"	# fan type to set speed for: cpu or device fans
	fan_duty_new="$2"		# duty cycle (percentage) to set fan zone $zone
	force="$3"			# force update flag

	debug_print 4 "Execute_ipmi_fan_payload --> fan target: $fan_category_name"
	debug_print 4 "Process new fan duty request for target: ${fan_duty_new}%"

	# when true, 'force' flag forces fan speed change regardless of whether it is changing or not
	if [ -n "$force" ]; then # 1/
		[ "$force" = "force" ] && force=true
		[ "$force" != true ] && force=false
	fi # 1/

	############################
	# Fan Duty Validation Checks
	############################

	if [ -z "$fan_duty_new" ]; then # 1/
		debug_print 3 warn "Fan duty cycle parameter of fan speed change request missing or invalid: $2" true
		return 1
	fi # 1/

	# sanitize fan duty PWM speed to ensure input is numeric
	fan_duty_new="${fan_duty_new//[!0-9.]/}"
	fan_duty_new="$(printf "%.0f" "$fan_duty_new")"

	if [ "$fan_duty_new" -lt 0 ]; then # 1/
		debug_print 3 warn "Negative fan duty speeds are invalid: $fan_duty_new" true
		return 1
	fi # 1/

	if [ "$fan_duty_new" -gt "$fan_duty_limit" ]; then # 1/ cannot exceed universal maximum
		debug_print 2 caution "Fan duty input (${fan_duty_new}%) cannot exceed max fan duty limit (${fan_duty_limit}%)"
		debug_print 3 "Reset new fan duty request to equal max fan duty limit"
		fan_duty_new="$fan_duty_limit"
	fi # 1/

	###################################
	# Target Fan Type Validation Checks
	###################################

	case "$fan_control_method" in # 1/
		universal)
			# when fan_control_method = universal, there is no target distinction
			execute_ipmi_fan_payload "$fan_duty_new"
			return 0
		;;

		*)
			case "$fan_category_name" in # 2/
				all)
					# all active fan duty categories
					target_fan_duty_category=( "${fan_duty_category[@]}" )
				;;

				*)
					# target must be a fan group type (e.g., cpu, device, etc.)
					if [ -z "$fan_category_name" ]; then # 1/ only universal mode does not use target fan type
						debug_print 1 critical "Missing target fan duty category name parameter of fan speed change request (\$2) missing" true
						return 1
					fi # 1/

					# non-exclusionary single fan duty category
					if validate_fan_category_name "$fan_category_name"; then # /
						debug_print 4 "Target fan type to be modified: $fan_category_name"
					else # 1/ target is unrecognized fan type
						debug_print 1 critical "Target fan duty category name of fan speed change request (\$2) is invalid: $fan_category_name" true
						debug_print 3 "Binary string for fan cooling type does not exist: \$${fan_category_name}_fan_header_active_binary"
						return 1
					fi # 1/

					target_fan_duty_category=( "$fan_category_name" )
				;;
			esac # 2/
		;;
	esac # 1/

	##############################################
	# Filter Fan Duty Request by Cooling Duty Type
	##############################################

	##
	# Process each fan cooling duty type as follows:
	#	0. Ignore CPU fan speed requests when CPU fans are not manually controlled
	#	1. Ensure new fan duty request is within allowed range
	#	2. Confirm target is valid (active fan header or zone binary exists)
	#	3. Compile IPMI data payload
	#	4. Implement fan speed change via IPMI command execution subroutine
	##

	for fan_category_name in "${target_fan_duty_category[@]}"; do # 1/ process each target fan cooling type (e.g. cpu or device)

		##
		# When CPU fan control is not permitted, exclude CPU cooling duty type from
		# the fan duty categories under consideration. When this results in no other fan
		# duty types remaining, then there is nothing to do here.
		##

		# 0. ignore requests to change CPU fan speeds when CPU fan control is disabled
		if [ "$fan_category_name" = "cpu" ] && [ "$cpu_fan_control" != true ]; then # 1/ skip attempting to control cpu fans when disallowed
			debug_print 3 caution "CPU fan speed change request ignored because CPU fan control is disabled"
			continue
		fi # 1/

		# 1. Ensure new fan duty request is within allowed range
		target_fan_duty_min="${fan_duty_min[$fan_category_name]}"

		if (( fan_duty_new < target_fan_duty_min )); then # 1/ check fan_duty against minimum speed for fan duty category
			debug_print 3 caution "${fan_category_name^^} fan duty change request fan speed (${fan_duty_new}%) is too low; increased to minimum: $((target_fan_duty_min))%"
			fan_duty_new=$((target_fan_duty_min))
		fi # 1/

		target_fan_duty_max="${fan_duty_max[$fan_category_name]}"

		if (( fan_duty_new > target_fan_duty_max )); then # 1/ cannot exceed fan type maximum
			debug_print 3 caution "${fan_category_name^^} fan duty change request fan speed (${fan_duty_new}%) is too high; decreased to maximum: $((target_fan_duty_max))%"
			fan_duty_new=$((target_fan_duty_max))
		fi # 1/

 		# specific target type fan duty limit exists
		target_fan_duty_last="${fan_duty_last[$fan_category_name]}"
		if [ "$force" != true ] && (( fan_duty_new == target_fan_duty_last )); then # 1/ # do not force fan speed command when there is no change
			debug_print 4 "Bypassing '${fan_category_name^^}' cooling duty type because current fan duty level = requested level"
			continue
		fi # 1/

		# 2. Confirm target is valid (active fan header or zone binary exists, write position is known for direct and group methods)
		case "$fan_control_method" in # 1/
			direct|group)
				if ! declare -p "${fan_category_name}_fan_header_active_binary" &>/dev/null; then # 1/ fan header binary corresponding to cooling fan duty category does not exist
					debug_print 2 warn "Invalid fan duty category: ${fan_category_name^^}"
					continue
				fi # 1/

				local -n binary_pointer="${fan_category_name}_fan_header_active_binary"

				if binary_is_empty "$binary_pointer"; then # 1/ no active fan headers of specified type
					debug_print 3 warn "No active fan headers assigned to this duty type: ${fan_category_name^^}"
					continue
				fi # 1/
			;;

			zone)
				if ! declare -p "${fan_category_name}_fan_zone_active_binary" &>/dev/null; then # 1/ fan zone binary corresponding to cooling fan duty category does not exist
					debug_print 2 warn "Invalid fan duty category: ${fan_category_name^^}"
					continue
				fi # 1/

				local -n binary_pointer="${fan_category_name}_fan_zone_active_binary"

				if binary_is_empty "$binary_pointer"; then # 1/ no active fan headers of specified type
					debug_print 3 warn "No active fan zones assigned to this duty type: ${fan_category_name^^}"
					continue
				fi # 1/
			;;

			*)
				bail_noop "Program error occurred: uncontrolled \$fan_control_method state" true
				return 1
		esac # 1/

		#####################################################################
		# Final IPMI Payload Prep | Send to IPMI Command Execution Subroutine
		#####################################################################

		# 1. Send each fan ID for relevant fan header type(s)
		# 2. Implement fan speed change via IPMI command execution subroutine

		debug_print 4 "Set '${fan_category_name}' cooling duty fan(s) to ${fan_duty_new}% fan duty"

		case "$fan_control_method" in # 1/
			direct)

				##
				# Because fan headers are actioned directly by IPMI, a separate write command must be
				# executed for each fan header ID of the given fan cooling duty type.
				##

				# set new fan duty for each fan header belonging to specified target fan duty category
				convert_binary_to_array "${fan_header_active_binary[$fan_category_name]}" "fan_array"

				# update each fan header individually
				for fan_id in "${!fan_array[@]}"; do # 2/ set all active fans in fan group to specified fan duty
					debug_print 4 "Set fan duty level for fan header ID '${fan_id}' to ${fan_duty_new}%"
					execute_ipmi_fan_payload "$fan_duty_new" "$fan_id"
				done # 2/
			;;

			group)
				# compile IPMI data payload global array
				compile_group_duty_cycle_payload "$fan_category_name" "$fan_duty_new"

				if (( ipmi_data_payload_length > 0 )); then # 1/ ipmi data payload required length is defined
					if (( ${#ipmi_group_fan_payload[@]} < ipmi_data_payload_length )); then # 2/ array length is insufficient
						if [ "$fan_category_name" = "cpu" ]; then # 3/
							if [ -n "$device_fan_duty" ]; then # 4/
								compile_group_duty_cycle_payload "device" "$device_fan_duty"
							else # 4/
								if [ -n "$device_fan_duty_start" ]; then # 5/
									compile_group_duty_cycle_payload "device" "$device_fan_duty_start"
								else # 5/
									bail_noop "Indeterminate fan speed for non-CPU fan headers"
								fi # 5/
							fi # 4/
						else # 3/
							if [ "$fan_category_name" = "device" ]; then # 4/
								if [ -n "$cpu_fan_duty" ]; then # 5/
									compile_group_duty_cycle_payload "cpu" "$cpu_fan_duty"
								else # 5/
									if [ -n "$cpu_fan_duty_start" ]; then # 6/
										compile_group_duty_cycle_payload "cpu" "$cpu_fan_duty_start"
									else # 6/
										bail_noop "Indeterminate fan speed for CPU fan headers"
									fi # 6/
								fi # 5/
							fi # 4/
						fi # 3/
					fi # 2/

					if (( ${#ipmi_group_fan_payload[@]} < ipmi_data_payload_length )); then # 2/ array length is still insufficient
						bail_noop "Cannot continue because incumbent fan speeds for one or more fan duty categories could not be determined"
					fi # 2/
				fi # 1/

				execute_ipmi_fan_payload
			;;

			zone)
				# suss out every fan zone for target duty type and set each related zone to new duty level
				convert_binary_to_array "${fan_zone_active_binary[$fan_category_name]}" "zone_array"

				for zone_id in "${!zone_array[@]}"; do # 2/ set all active fans in fan group to specified fan duty
					debug_print 4 "Set new fan duty level for fan zone '${zone_id}'"
					debug_print 4 "Setting fan duty level for fan zone ID '${zone_id}' to ${fan_duty_new}%"

					execute_ipmi_fan_payload "$fan_duty_new" "$zone_id"
				done # 2/
			;;
		esac # 1/
	done # 1/
}
