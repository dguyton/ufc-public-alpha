##
# Examine Service file source code and/or filename to identify its version number.
#
# The function sets the global variable (passed as the first parameter)
# with the program version parsed from full filename path of the file to be examined.
#
# Note: Failure to find a version number is not an indicator of failure. A version
# of null is considered a valid version, as a user may choose to not use program
# versioning.
#
# Parameters:
#   $1 - Name of the global variable to store the resulting file version
#   $2 - Path of the file to be evaluated
#
# Returns:
#   0 program version of file parsed without error
#   1 this subroutine failed due to error
##

function parse_file_version ()
{
	local filename		# filename to scan
	local file_version

	if [ -z "$1" ]; then # 1/
		debug_print 2 warn "Missing target filename (\$1)" true
		return 1
	fi # 1/

	# filename to be evaluated
	filename="$1"

	debug_print 4 "Parse program version related by this file: $filename"

	if ! [ -r "$filename" ]; then # 1/ failsafe check
		debug_print 4 warn "Cannot parse this file because current user lacks permission to read it"
		return 1
	fi # 1/

	# derive program version: find first matching comment reference and parse it
	file_version="$(grep -i -m 1 '^# program_version=' "$filename")"

	##
	# Remove quotation marks around version declaration.
	# Note if it is not quoted, this logic returns the same version info.
	##

	if [ -n "$file_version" ]; then # 1/ parse version string
		file_version="${file_version#*=}" # remove everything before the '='
		file_version="${file_version#*\"}" # remove everything before first quote
		file_version="${file_version%\"*}" # remove everything after last quote
		file_version="${file_version//[!.0-9]/}" # retain only numbers and decimal points

		# version may be null, but this would still be a legitimate result
		debug_print 4 "Program version parsed from file content: $file_version"

		printf "%s" "$file_version"
		return 0
	fi # 1/

	##
	# When source code parsing fails, parse filename.
	# Presumes version number embedded in filename is preceded by "_v" text, and
	# that there may not be a version number.
	##

	debug_print 4 "Program version not found in source code; examining filename for version info"

	file_version="$(grep -i '_v' "$filename")"

	if [ -n "$file_version" ]; then # 1/
		file_version="${file_version#v_}" # remove everything up to and including '_v'
		file_version="${file_version%.*}" # remove everything after first period
		file_version="${file_version//[!.0-9]/}" # retain only numbers and decimal points

		if [ -n "$file_version" ]; then # 2/
			debug_print 4 "Program version parsed from filename: $file_version"
		else # 2/
			debug_print 4 "No program version found, which is OK, but creates risk of program file mis-match"
			file_version=""
		fi # 2/

		printf "%s" "$file_version"
		return 0
	else # 1/
		debug_print 4 "Filename does not contain version info"
		return 1
	fi # 1/
}
