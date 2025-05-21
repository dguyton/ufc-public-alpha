##
# Convert a binary string to a list of active ordinal positions.
#
# Populate target array with the results.
#
# Ordinal positions begin with 0 (zero), starting from the left-most bit position.
# A 0 (zero) bit state in a binary represents an 'off' state.
# A 1 (one) bit state in a binary represents an 'on' state.
#
# Bit 'on' in test binary indicates a positive (true) result.
# Bit 'off' in test binary indicates a negative result.
#
# 'On' binary positions result in creating a key:value pair in the target array.
# 'Off' positions do not create a key:value pair in the target array.
#
# Thus, one may scan the existing array index (elements) of the target array in order
# to determine which bits are 'on' in the source binary.
#
# The target array must be an indexed type. Each element of the array
# corresponds to an ordinal position in the binary string. When an ordinal
# position in the binary contains a value of '1' (an "on" bit), its
# corresponding array index is created, and its value is set to = TRUE.
#
# When an ordinal (bit) position is 0 ("off"), the ordinal position is
# skipped and its corresponding array element is not created in the target
# array.
##

function convert_binary_to_array ()
{
	local array_name
	local binary_string
	local binary_array_name
	local bit_length
	local ordinal

	binary_string="$1"
	array_name="$2" # name of ordinal indexed array to populate with contents of binary

	# ensure binary string is provided
	if [ -z "$binary_string" ]; then # 1/ binary string to convert
		debug_print 2 warn "Binary string to be parsed is empty (\$1)" true
		return 1
	fi # 1/

	# validate binary string (only 0s and 1s are allowed)
	if [ -n "$(printf "%s" "${binary_string//[01]/}")" ]; then # 1/
		debug_print 2 warn "Provided binary string (\$1) contains invalid characters: $binary_string" true
		return 1
	fi # 1/

	# ensure array name is provided
	if [ -z "$array_name" ]; then # 1/ name of array to populate with results
		debug_print 2 warn "Name of array to populate with result  (\$array_name) is missing" true
		return 1
	fi # 1/

	# validate provided variable is indexed array
	if ! declare -p "$array_name" 2>/dev/null | grep -q 'declare -a'; then # 1/
		debug_print 2 warn "Name of array to populate with results (\$$array_name) is invalid: \$$array_name" true
		return 1
	fi # 1/

	local -n output_array_name="$array_name"

	bit_length="${#binary_string}"

	# clear target array before populating it
	output_array_name=()

	# iterate over binary string from left to right
	for (( ordinal=0; ordinal<bit_length; ordinal++ )); do # 1/ examine binary from left-most bit to right-most bit
		[ "${binary_string:ordinal:1}" = "1" ] && output_array_name["$ordinal"]=true # only create a target array element when current binary bit is on
	done # 1/
}
