##
# Trim trailing slahs from directory, when it exists
#
# NOTE: this will cause root file_system_object ("/") to be treated as null
##

function trim_trailing_slash ()
{
	if [ -z "$1" ]; then # 1/
		debug_print 4 warn "Missing arg '\$1'" true
		return 1
	fi # 1/

	local -n file_system_object="$1" # pointer to global variable containing file system object to be parsed

	if [ "${file_system_object: -1}" = "/" ]; then # 1/
		file_system_object="${file_system_object:: -1}" # drop trailing forward slash when there is one
		debug_print 4 "Removed trailing slash from directory name"
	fi # 1/

	# warn user the file_system_object cannot be root
	if [ -z "$file_system_object" ]; then # 1/
		debug_print 3 caution "Use of 'root' directory for this purpose is not permitted"
		return 1
	else # 1/
		return 0
	fi # 1/
}
