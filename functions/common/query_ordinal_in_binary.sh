##
# Query the specified bit position in a binary string stored in an associative array.
# Returns 0 (success) if bit is ON (1), or 1 (failure) if bit is OFF (0) or invalid.
#
# Ordinal 0 is the far left-most bit.
##

function query_ordinal_in_binary ()
{
	local array_name	# name of associative array
	local binary_string	# fetch binary string
	local bit_length
	local current_binary
	local key			# key for binary string in associative array
	local ordinal		# bit position to check

	ordinal="$1"
	array_name="$2"
	key="$3"

	# input validation
	if [ -z "$array_name" ]; then # 1/
		debug_print 2 warn "Missing binary string array name to evaluate" true
		return 1
	fi # 1/

	if [ -z "$key" ]; then # 1/
		debug_print 2 warn "Binary string key/index name is empty or undefined" true
		return 1
	fi # 1/

	if ! declare -p "$array_name" 2>/dev/null | grep -q 'declare -A'; then # 1/
		debug_print 2 warn "Name of binary string array name to be queried is invalid: \$$array_name" true
		return 1
	fi # 1/

	# create a nameref to the associative array of binary strings
	local -n binary_array="$array_name"

	if ! [ -v binary_array["$key"] ]; then # 1/
		debug_print 2 warn "Specified binary string '$array_name[$key]' is undefined" true
		return 1
	fi # 1/

	# grab current binary string to be evaluated
	current_binary="${binary_array[$key]}"

	if [ -z "$current_binary" ]; then # 1/ no binary string to modify
		debug_print 2 warn "Specified binary string is empty" true
		return 1
	fi # 1/

	bit_length="${#current_binary}"

	# validate ordinal is non-negative integer within bounds of current_binary length
	if [ "$ordinal" != "${ordinal//[!0-9]/}" ] || (( ordinal >= bit_length )) || (( ordinal < 0 )); then # 1/ abort on invalid parameters
		debug_print 4 warn "Invalid ordinal value ($1); must be in range 0 to $((bit_length - 1))" true
		return 1
	fi # 1/

	case "${current_binary:ordinal:1}" in # 1/
		0)
			debug_print 4 "Ordinal '$ordinal' in binary string '${array_name}[$key]' is OFF"
			return 1
			;;
		1)
			debug_print 4 "Ordinal '$ordinal' in binary string '${array_name}[$key]' is ON"
			return 0
			;;
		*)
			debug_print 4 warn "Invalid character found in binary string '${array_name}[$key]' at ordinal $ordinal: '${current_binary:ordinal:1}'" true
			return 1
			;;
	esac # 1/
}
