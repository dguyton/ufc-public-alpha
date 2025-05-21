# stat a file system object and return its current 3-digit permissions level
function stat_file_system_object ()
{
	local permissions
	local file_system_object

	if [ $# -lt 2 ]; then
		debug_print 3 warn "Invalid number of arguments in call to '${FUNCNAME[0]}' function" true
		return 1
	fi # 1/

	if [ -z "$1" ]; then # 1/
		debug_print 3 warn "Missing arg '\$1' (file system object path)" true
		return 1
	fi # 1/

	if [ -z "$2" ]; then # 1/
		debug_print 3 warn "Missing arg \$2 (variable name to set stat permissions level to indirectly)" true
		return 1
	fi # 1/

	file_system_object="$1"
	local -n permissions="$2" # indirect pointer to global variable name of user type

	# get current 3-digit permissions level, return null on error
	if ! permissions="$(stat -c "%a" "$file_system_object" 2>/dev/null)"; then # 1/
		debug_print 3 warn "Failed to 'stat' this file system object for an unknown reason: $file_system_object"
		return 1
	fi # 1/

	# when magic number is 4 digits, drop 1st digit (ignore special function bits as only 3-digit raw permissions level is needed)
	[ ${#permissions} -eq 4 ] && permissions="${permissions:1}"

	if [ ${#permissions} -ne 3 ]; then # 1/
		debug_print 3 warn "Unable to parse 'stat' command output because it returned a non-recognized response"
		unset permissions
		return 1
	fi # 1/
}
