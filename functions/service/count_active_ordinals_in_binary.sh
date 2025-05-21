# count number of active ordinals in binary
function count_active_ordinals_in_binary ()
{
	local array_name		# name of associative array
	local current_binary	# current value of binary string to evaluate
	local key				# key for binary string in associative array
	local result_var		# name of variable to populate with result

	array_name="$1"
	key="$2"
	result_var="$3"

	# input validation
	if [ -z "$array_name" ]; then # 1/
		debug_print 2 warn "Missing binary string array name to evaluate" true
		return 1 # false positive
	fi # 1/

	if ! declare -p "$array_name" 2>/dev/null | grep -q 'declare -A'; then # 1/
		debug_print 2 warn "Name of associative array to evaluate is invalid: \$$array_name" true
		return 1
	fi # 1/

	if [ -z "$key" ]; then # 1/
		debug_print 2 warn "Binary string key/index name is empty or undefined" true
		return 1
	fi # 1/

	if [ -z "$result_var" ]; then # 1/
		debug_print 2 warn "Missing name of variable to populate with result" true
		return 1
	fi # 1/

	# bind namerefs only after validation
	local -n binary_array="$array_name"
	local -n result_pointer="$result_var"

	# grab current binary string to be evaluated
	current_binary="${binary_array[$key]}"

	if [ -z "$current_binary" ]; then # 1/ no binary string to modify
		debug_print 2 warn "Specified binary string is empty" true
		return 1
	fi # 1/

	result_pointer=0

	# count active bits
	for (( ordinal=0; ordinal < ${#current_binary}; ordinal ++ )); do # 1/ test only active fan headers of target binary string
		[ "${current_binary:$((ordinal)):1}" = "1" ] && ((result_pointer++))
	done # 1/

	return 0
}
