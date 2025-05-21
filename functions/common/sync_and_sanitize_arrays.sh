##
# 1. Synchronize a group of arrays by removing keys not found in every array within the group
# 2. Sanitize the value of each retained key, in each array
##

function sync_and_sanitize_arrays ()
{

	local array_names=("$@") # accepts any number of array names as arguments
	local -A key_counts=()
	local -A seen_keys=()
	local total_arrays="${#array_names[@]}"
	local name key

	# first pass: count key occurrences across all arrays
	for name in "${array_names[@]}"; do # 1/

		local -n arr="$name"

		for key in "${!arr[@]}"; do # 2/
			seen_keys["$key"]=1
			key_counts["$key"]=$((key_counts["$key"] + 1))
		done # 2/
	done # 1/

	# second pass: identify and remove incomplete keys
	for key in "${!seen_keys[@]}"; do # 1/
		if [ "${key_counts[$key]}" -ne "$total_arrays" ]; then # 1/
			debug_print 2 warn "Array key '$key' not found in every array within the group, and will be removed"
			array_error=true

			for name in "${array_names[@]}"; do # 2/
				local -n arr="$name"
				unset "arr[$key]"
			done # 2/
		else # 1/

			# sanitize valid key across all arrays
			for name in "${array_names[@]}"; do # 2/
				local -n array_ref="$name"
				local raw="${array_ref[$key]}"
				local clean="${raw//[!0-9.]/}"

				array_ref[$key]="$(printf "%.0f" "$clean")"
			done # 2/
		fi # 1/
	done # 1/

	if [ "$array_error" = true ]; then # 1/
		return 1
	else # 1/
		return 0
	fi # 1/
}
