##
# Determine when a binary string stores no value, because all of
# its ordinals have an OFF (zero bit) state.
#
# Returns true (0) when all ordinal bit flags of given binary are disabled.
# Returns false (1) when string is invalid (not binary, undefined, etc.)
#
# Note: False positive errors are possible. False positives are favored over
# false negative returns, because in this case they are more defensive.
##

function binary_is_empty ()
{
	local array_name	# name of associative binary array to modify (e.g., fan_header_binary[] array)
	local bit_length
	local current_binary
	local key			# array key (e.g., cpu)
	local ordinal		# bit position (e.g., 2)

	array_name="$1"
	key="$2"

	if [ -z "$array_name" ]; then # 1/
		debug_print 2 warn "Missing binary string array name to evaluate" true
		return 0 # false positive
	fi # 1/

	if [ -z "$key" ]; then # 1/
		debug_print 2 warn "Binary string key/index name is empty or undefined" true
		return 1
	fi # 1/

	# create a nameref to the associative array of binary strings
	local -n binary_array="$array_name"

	if ! [ -v binary_array["$key"] ]; then # 1/
		debug_print 2 warn "Specified binary string '$array_name[$key]' is undefined" true
		return 1
	fi # 1/

	# grab current binary string to be modified
	current_binary="${binary_array[$key]}"

	if [ -z "$current_binary" ]; then # 1/ no binary string to modify
		debug_print 2 warn "Specified binary string is empty" true
		return 1
	fi # 1/

	bit_length="${#current_binary}"

	for (( ordinal=0; ordinal<bit_length; ordinal++ )); do # 1/
		[ "${current_binary:ordinal:1}" = "1" ] && return 1 # return false (binary string not empty)
	done # 1/

	return 0 # ensure default return status is true (not false)
}
