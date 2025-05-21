# extract current .init filename and location from Service Launcher executable
function parse_init_filename ()
{
	local filename		# filename to scan
	local pointer		# derived .init filename pointer

	filename="$1"

	# find the first commented string match and parse it
	pointer="$(grep -i -m 1 'init_filename=' "$filename")"

	##
	# Remove quotation marks around version declaration.
	# Note if it is not quoted, this logic returns the same version info.
	##

	# parse filename of related .init file embedded in source file
	pointer="${pointer#*\"}"
	pointer="${pointer%\"}"

	[ -z "$pointer" ] && debug_print 4 caution "Failed to parse .init filename associated with $filename"

	print "%s" "$pointer"
}
