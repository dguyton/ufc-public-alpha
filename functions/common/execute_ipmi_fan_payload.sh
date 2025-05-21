##
# Execute IPMI fan duty command(s).
#
# This subroutine is executed regardless of fan header schema type.
# Logic branching based on motherboard manufacturer and BMC schema.
#
# Called by these subroutines:
#	set_fan_duty_cycle
#	set_all_fans_mode
#
# Required Arguments
# 	- Direct fan control method    : fan duty cycle, fan ID
# 	- Group fan control method     : CPU fan duty cycle, device fan duty cycle
# 	- Universal fan control method : fan duty cycle
# 	- Zone fan control method      : fan duty cycle, zone ID
#
# { $1 = fan duty speed } { $2 = target fan id/zone id when applicable}
#
# input $1 = fan duty cycle to set target to
#
# input $2 = $target = which fan headers need to be updated?
#	--> when group mode, update all fans at once, target range = cpu/device/all
#	--> when universal mode, update all fans at once, target must = all
#	--> when zone mode, update target zone, target = zone id
#	--> when direct mode, update target fan, target = fan id
##

function execute_ipmi_fan_payload ()
{
	local fan_category				# fan cooling type (e.g. cpu, device)
	local fan_duty					# PWM percentage
	local fan_id
	local index
	local ipmi_command_payload		# IPMI command payload construction
	local match
	local target					# target fan header, zone, or type (group fan control method only)
	local write_position			# fan header order for direct and group fan control methods
	local zone_id

	fan_duty="$1"
	target="$2"

	##
	# $target and $fan_duty are irrelevant when fan control method = group
	# because group fan speed payloads are determined before this subroutine
	# is called.
	##

	if [ "$fan_control_method" != "group" ] && [ -z "$fan_duty" ]; then # 1/ must specify new fan duty when control method != group
		debug_print 1 critical "Missing fan duty cycle parameter of fan speed change request" true
		return 1
	fi # 1/

	case "$fan_control_method" in # 1/

		direct)
			# target must be a valid fan id or zone id when fan control method is Direct or Zone
			fan_id="${target//[!0-9]/}" # must be integer

			if (( fan_id >= fan_header_binary_length )); then # 1/
				debug_print 2 critical "Fan ID out of range" true
				unset fan_id
			fi # 1/

			if [ -z "$fan_id" ]; then # 1/ invalid fan id target or out of range or var missing
				debug_print 1 critical "Failed to execute fan speed change: undefined fan header '${2}'" true
				return 1
			fi # 1/

			debug_print 4 "Convert fan ID $fan_id to its fan write position"
			write_position="${ipmi_fan_id_write_position[$fan_id]}" # convert each fan id to its write-order position

			if [ -z "$write_position" ]; then # 1/
				debug_print 3 critical "Write position record not found for this fan ID" true
				return 1
			fi # 1/

			debug_print 4 "Mapped fan ID '${fan_id}' to IPMI fan write order position '${write_position}'"

			# convert specified fan header id to hex
			target=$(printf "0x%x" "$write_position")
		;;

		group)
			# get IPMI data payload prefix bytes
			if ! compile_ipmi_fan_payload "ipmi_command_payload"; then # 1/
				debug_print 1 critical "Unknown fan control methodology '$fan_control_method' for mobo manufacturer '$mobo_manufacturer'"
				bail_noop "Failed to apply correct fan control methodology because BMC schema could not be identified"
			fi # 1/

			# parse array with pre-populated group fan speeds and convert them to hex values
			if ! convert_array_to_hex "ipmi_group_fan_payload"; then # 1/ convert integer values in array to hex values
				bail_noop "Non-recoverable failure while running 'convert_array_to_hex' subroutine to convert fan duty integers to hex values"
			fi # 1/

<<>>

--> 1. call compile_ipmi_fan_payload
--> 2. if it returns status = 0 and -n ipmi_command_payload then we need to build the command, then run it



for index in "${!ipmi_group_fan_payload[@]}"; do # 1/ get first 6 bytes
	ipmi_payload+=" ${ipmi_group_fan_payload[$index]}"
done # 1/

# compile full IPMI raw command and execute it
debug_print 4 "Execute IPMI command payload request: '${ipmi_command_payload}'"
run_command "$ipmitool raw $ipmi_command_payload"
return 0 # success


<<>>

--> this will always be -z when fan control method = group, which is not correct behavior
--> also this is not a problem for group method if we have not yet converted its array into this string ipmi_command_payload
--> so we should not disqualify or bail when method = group until we tried that first

<<>>

--> block below can be moved to group only sub
--> this is a validation of the full group IPMI data payload before we try to run it
--> it converts all the stored new fan duty integer values to hex, which must be done before sending the IPMI command
--> however, this needs to be processed after the matching process above has completed


--> we could add a case here for group that acts differently, and returns when it is finished
	--> 1. call compile_ipmi_fan_payload
	--> 2. do group stuff checks
	--> 3. done

--> when compile_ipmi_fan_payload returns, if it has no error but -z ipmi_command_payload then return 0 as we are done
--> when compile_ipmi_fan_payload returns, if it has error and -z ipmi_command_payload then bail
--> when compile_ipmi_fan_payload returns, if it has error and -n ipmi_command_payload then we have prefix and need to add data payload, and run_command

		;;

		zone)
			# target must be a valid fan id or zone id when fan control method is Direct or Zone
			zone_id="${target//[!0-9]/}" # must be integer

			if [ -z "$zone_id" ]; then # 2/
				debug_print 1 critical "Failed to execute fan speed change: undefined fan zone '${2}'" true
				return 1
			fi # 2/

			if (( zone_id >= fan_zone_binary_length )); then # 1/
				debug_print 2 critical "Fan Zone ID (\$2) is out of range: $zone_id" true
				return 1
			fi # 1/


--> is there a better way to determine which fan category the target zone belongs to?


			if query_ordinal_in_binary "$zone_id" "fan_zone_active_binary" "master"; then # 2/ verify target zone is active
				for fan_category in "${fan_duty_category[@]}"; do # 1/ determine which fan category the zone belongs to
					if query_ordinal_in_binary "$zone_id" "fan_zone_active_binary" "$fan_category"; then # 3/
						match=true
						break
					fi # 3/
				done # 1/
			fi # 2/

			if [ "$match" != true ]; then # 2/ target zone not active
				debug_print 1 warn "Failed to execute fan speed change: fan zone target '${zone_id}' is inactive" true
				return 1
			fi # 2/

			# sanitized zone target
			target="$zone_id"
		;;

		universal)
			# no pre-processing, but is a valid fan control method
		;;

		*)
			# trap when no method mentioned above, and not group fan control method
			bail_noop "Invalid fan control method: $fan_control_method"
		;;

	esac # 1/

	#####################
	# Fan Duty Validation
	#####################

	# fan duty request must be legitimate when it is passed as an argument for this function
	fan_duty="${fan_duty//[!0-9]/}"

	if (( fan_duty < 0 )); then # 1/
		debug_print 2 warn "Negative fan duty speeds are invalid: $fan_duty" true
		return 1
	fi # 1/

	if [ "$fan_duty" -gt "$fan_duty_limit" ]; then # 1/
		debug_print 2 caution "Fan duty exceeds maximum fan duty limit (${fan_duty_limit}%)"
		debug_print 3 "Reset fan duty request to max fan duty limit for all fan types"
		fan_duty="$fan_duty_limit"
	fi # 1/

<<>>

--> fan_category needs to be known when fan_control_method = direct or zone

--> then check:

--> might need to also pass it to compile_ipmi_fan_payload




	if (( fan_duty > fan_duty_max["$fan_category"] )); then # 1/
		debug_print 2 caution "Fan duty exceeds maximum ${fan_category^^} fan duty limit"
		debug_print 3 "Reset new fan duty request to ${fan_category^^} fan duty maximum"
		fan_duty="${fan_duty_max[$fan_category]}"
	fi # 1/

	if (( fan_duty < fan_duty_min["$fan_category"] )); then # 1/
		debug_print 2 caution "Fan duty exceeds minimum ${fan_category^^} fan duty"
		debug_print 3 "Reset new fan duty request to ${fan_category^^} fan duty minimum"
		fan_duty="${fan_duty_min[$fan_category]}"
	fi # 1/

	# default fan duty to hex conversion
	fan_duty_hex="$(printf "0x%x" "$fan_duty")"

	##
	# $ipmi_command_payload only gets populated when it was successfully updated.
	# Therefore, when it is null, something went wrong with IPMI command creation
	# subroutine call.
	##

	if ! compile_ipmi_fan_payload "ipmi_command_payload" "target" "fan_duty"; then # 1/
		debug_print 1 critical "Unknown fan control methodology '$fan_control_method' for mobo manufacturer '$mobo_manufacturer'"
		bail_noop "Failed to apply correct fan control methodology because BMC schema could not be identified"
	fi # 1/

	# compile full IPMI raw command and execute it
	debug_print 4 "Execute IPMI command payload request: '${ipmi_command_payload}'"

	run_command "$ipmitool raw $ipmi_command_payload"

	return 0 # success
}
