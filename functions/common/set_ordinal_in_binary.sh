##
# Set specified ordinal bit on or off in specified binary string.
# For all other ordinals, retain incumbent value (on or off).
#
# If the operation is aborted, no changes are made to target
# variable or array.
#
# Ordinal 0 (bit 0) is the far left-most bit.
##

function set_ordinal_in_binary ()
{
	local array_name	# name of associative binary array to modify (e.g., fan_header_binary[] array)
	local bit_length
	local current_binary
	local key			# array key (e.g., cpu)
	local ordinal		# bit position (e.g., 2)
	local switch		# on/off requested setting

	switch="$1"
	ordinal="$2"
	array_name="$3"
	key="$4"

	case "$switch" in # 1/
		off|0)
			switch=0
			;;

		on|1)
			switch=1
			;;

		*)
			debug_print 4 warn "Invalid switch disposition type: $switch" true
			return 1
			;;
	esac # 1/

	if [ -z "$array_name" ]; then # 1/
		debug_print 2 warn "Missing binary string array name to evaluate" true
		return 1 # false positive
	fi # 1/

	if [ -z "$key" ]; then # 1/
		debug_print 2 warn "Binary string key/index name is empty or undefined" true
		return 1
	fi # 1/

	if ! declare -p "$array_name" 2>/dev/null | grep -q 'declare -A'; then # 1/
		debug_print 2 warn "Name of binary string array name to be modified is invalid: \$$array_name" true
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

	# validate ordinal is non-negative integer within bounds of current_binary length
	if [ "$ordinal" != "${ordinal//[!0-9]/}" ] || (( ordinal >= bit_length )) || (( ordinal < 0 )); then # 1/ abort on invalid parameters
		debug_print 4 warn "Invalid ordinal value ($2); must be in range 0 to $((bit_length - 1))" true
		return 1
	fi # 1/

	binary_array["$key"]="${current_binary:0:$ordinal}${switch}${current_binary:$((ordinal + 1))}"
	debug_print 4 "Updated \$$array_name[$key]: ${binary_array[$key]}"
	return 0
}
