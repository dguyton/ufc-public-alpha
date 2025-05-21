##
# Convert contents of an array to hex values. Presumes all array values are integers.
#
# Input: name of array to convert
# Output: swaps integer values in array with hexadecimal equivalent values
#
# Note: treats non-integer values as 0 (zero)
##

function convert_array_to_hex ()
{
	local index
	local value

	local array_name="$1"

	debug_print 3 "Convert array '$1' values to hex equivalents"

	# ensure array name is provided
	if [ -z "$array_name" ]; then # 1/ name of array to populate with results
		debug_print 2 warn "Name of array to parse (\$1) is missing" true
		return 1
	fi # 1/

	# validate provided variable is indexed array
	if ! declare -p "$array_name" 2>/dev/null | grep -q 'declare -a'; then # 1/
		debug_print 2 warn "Array name (\$1) to parse is invalid: \$$array_name" true
		return 1
	fi # 1/

	if [ -z "$fan_duty_limit" ]; then # 1/
		debug_print 2 warn "\$fan_duty_limit not defined"
		return 1
	fi # 1/

	local -n array_name_pointer="$array_name"

	(( ${#array_name_pointer[@]} == 0 )) && return 1 # array is empty

	# iterate over indices and convert values to hexadecimal
	for index in "${!array_name_pointer[@]}"; do # 1/

		value="${array_name_pointer[$index]//[!0-9]/}" # sanitize current array element

		if [ -n "$value" ]; then # 1/
			if [ "$value" -gt "$fan_duty_limit" ]; then # 2/
				value="$fan_duty_limit"
				debug_print 4 "Reducing '\$$array_name[$index]' value ($value) because it exceeds \$fan_duty_limit"
			else # 2/
				debug_print 4 "Converting '${array_name_pointer[$index]}' to '$value'"
			fi # 2/
		else # 1/ not an integer
			value=0
			debug_print 3 caution "Array '$array_name' index '$index' value is undefined or not an integer" true
			debug_print 4 "Treating as '0' (zero)"
		fi # 1/

 		# convert each integer value to hexadecimal
		array_name_pointer[$index]="$(printf "0x%x" "$value")"

	done # 1/

	debug_print 3 "Array '$array_name' values successfully converted to hexadecimal"

	return 0 # success
}
