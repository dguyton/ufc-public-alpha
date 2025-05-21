##
# Prioritize CPU cooling
#
# Verify at least one fan header is assigned to CPU cooling duty.
#
# 1. When no fans were previously designated for CPU cooling,
# force all fans to CPU cooling duty.
#
# 2. When system is flagged for CPU fan cooling only, attempt
# to reassign all non-CPU fan duty fans to CPU fan cooling.
##

function validate_cpu_fan_headers ()
{
	local fan_category
	local fan_id
	local fan_name

	if binary_is_empty "${fan_header_binary[cpu]}"; then # 1/
		debug_print 1 caution "No fans designated for CPU cooling duty"
		debug_print 2 "Non-excluded, non-CPU fan headers will be reassigned to support CPU cooling priority"
		only_cpu_fans=true
	else # 1/ at least one fan header assigned to CPU cooling duty
		if [ "$only_cpu_fans" != true ]; then # 2/ not all fans are assigned to CPU cooling duty
			debug_print 4 "At least one fan header is assigned to CPU cooling duty"
			return # nothing further needed here
		fi # 2/
	fi # 1/

	##
	# Code below only executes when 'only_cpu_fans' = true.
	# (i.e., all fans are dedicated to CPU cooling only).
	##

	debug_print 1 caution "Reassign all non-excluded fans to CPU cooling duty"

	# trap error condition when cpu fan control is not permitted by config settings
	if [ "$cpu_fan_control" = false ]; then # 1/
		bail_noop bail_noop "CPU fan control disabled: cannot reassign fans to CPU duty"
	fi # 1/

	# reassign all non-cpu, non-excluded fans to CPU cooling duty
	for fan_id in "${!fan_header_name[@]}"; do # 1/
		fan_category="${fan_header_category[$fan_id]}"

		case "$fan_category" in # 1/
			cpu|exclude)
				continue # do nothing
			;;

			*)
				if query_ordinal_in_binary "$fan_id" "fan_header_binary" "$fan_category"; then # 1/
					debug_print 4 caution "Reassign '${fan_header_name[$fan_id]}' (fan ID $fan_id) from $fan_category to CPU fan cooling duty"

					# disable fan position in original fan header binary
					set_ordinal_in_binary "off" "$fan_id" "fan_header_binary" "$fan_category"

					# enable fan position in cpu fan header binary
					set_ordinal_in_binary "on" "$fan_id" "fan_header_binary" "cpu"

					# associate fan header to its new duty type
					fan_header_category["$fan_id"]="cpu"
				fi # 1/
			;;
		esac # 1/
	done # 1/

	# still no fans assigned to CPU cooling duty
	if binary_is_empty "${fan_header_binary[cpu]}"; then # 1/
		bail_with_fans_full "No fans available for CPU cooling duty"
	fi # 1/
}
