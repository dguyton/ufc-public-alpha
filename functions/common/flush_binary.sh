# reset and re-populate existing or new binary with all zero bits
function flush_binary ()
{
	local binary
	local bit_length
	local position

	bit_length="$1"

	if (( bit_length == 0 )); then # 1/
		debug_print 4 warn "Length of specified binary string not specified" true
		return 1
	fi # 1/

	for (( position=0; position<bit_length; position++ )); do # 1/
		binary+="0"
	done # 1/

	printf "%s" "$binary" # return result
}
