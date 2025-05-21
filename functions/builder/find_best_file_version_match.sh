##
# Within a specified directory, identify the filename which best matches
# a given version.
#
# Only the first first filename with a matching detected program version is
# returned. Thus, when more than one file in the target directory matches the
# search string, the filename with the most recent date/time stamp will be
# returned as the best match.
#
# If no version number is supplied, then the filename with the most recent
# timestamp and with no version number will be returned as the best match.
# This behavior is expected when the Builder has no discernable version number.
#
# Result returned:
# --> filename (full path) when a match is discovered (best/first match)
# --> null when no file is found with matching version
# --> null when no files exist to be compared
##

find_best_file_version_match ()
{
	local depth
	local directory
	local filename
	local file_ext
	local -l target_string
	local target_version
	local version

	local -a source_file_list	# array of service program file candidates

	directory="$1"				# directory to scan [required]
	target_string="$2"			# text in filename, such as 'launcher' (case insensitive) [optional]
	target_version="$3"			# version string trying to match; null value is OK [optional]
	file_ext="$4"				# file extension (default = sh) [optional]
	depth="$5"				# number of levels to limit search depth (null = no limit) [optional]

	if [ -z "$directory" ]; then # 1/
		debug_print 3 warn "Target directory is missing (\$1)"
		return 1
	fi # 1/

	if [ -z "$target_string" ]; then # 1/
		debug_print 3 "Match string not defined (\$2)"
	fi # 1/

	[ -z "$file_ext" ] && file_ext="sh"

	[ -n "$depth" ] && depth="${depth//[!0-9]/}" # numeric only

	(( depth == 0 )) && unset depth # 0 means no limit

	# normalize target version
	if [ -n "$target_version" ]; then # 1/
		target_version="${target_version#*=}"          # remove everything before the '='
		target_version="${target_version#*\"}"         # remove everything before first quote
		target_version="${target_version%\"*}"         # remove everything after last quote
		target_version="${target_version//[!.0-9]/}"   # retain only numbers and decimal points
	fi # 1/

	debug_print 4 "Find newest filename matching search string ($target_string), program version ($target_version), and file extension (.${file_ext})"

	if ! set_target_permissions "$directory" PERM_READ_TRAVERSE; then # 1/ dir perms check
		debug_print 3 warn "Current user has insufficient file system permissions to access source files"
		return 1
	fi # 1/

	if ! trim_trailing_slash "directory"; then # 1/
		debug_print 3 warn "Proposed source file search location directory trim failed for an unknown reason" true
		return 1
	fi # 1/

	if [ -z "$directory" ]; then # / root dir
		debug_print 3 warn "Proposed source file search location is root directory, which is not allowed"
		return 1
	fi # 1/

	if [ -n "$target_string" ]; then # 1/ sort files in dir by name (text) inclusion, then by file extension, then by date/time stamp, with newest files first
		if [ -n "$depth" ]; then # 1/ depth restricted
			readarray -d '' -t source_file_list < <(find "$directory" -maxdepth "$depth" -iname '*'"$target_string"'*' -name '*.'"$file_ext" -type f -printf "%T@ %p\0" | sort -z -r -k1,1 | cut -z -d' ' -f2-)
		else # 2/ not depth restricted
			readarray -d '' -t source_file_list < <(find "$directory" -iname '*'"$target_string"'*' -name '*.'"$file_ext" -type f -printf "%T@ %p\0" | sort -z -r -k1,1 | cut -z -d' ' -f2-)
		fi # 2/
	else # 1/ sort files in dir by file extension, then by date/time stamp, with newest files first
		if [ -n "$depth" ]; then # 1/
			readarray -d '' -t source_file_list < <(find "$directory" -maxdepth "$depth" -name '*.'"$file_ext" -type f -printf "%f\t%T@\t%p\0" | sort -z -k1,1 -k2,2nr | cut -z -f3-)
		else # 2/
			readarray -d '' -t source_file_list < <(find "$directory" -name '*.'"$file_ext" -type f -printf "%f\t%T@\t%p\0" | sort -z -k1,1 -k2,2nr | cut -z -f3-)
		fi # 2/
	fi # 1/

	# examine version of each Service file (per source code or filename)
	debug_print 3 "Number of potential matches: ${#source_file_list[@]}"

	if [ "${#source_file_list[@]}" -eq 0 ]; then # 1/
		debug_print 4 caution "No potential file matches"
		return 1
	fi # 1/

	debug_print 3 "Parse target file(s) to determine if any match specified version"

	# compare each source file in order to target version
	for filename in "${source_file_list[@]}"; do # 1/
		version="$(parse_file_version "$filename")" && [ "$version" = "$target_version" ] && break # break on first match
	done # 1/

	if [ "$version" = "$target_version" ]; then # 1/
		debug_print 3 "Program file versions match!"
	else # 1/
		debug_print 3 "No match found"
		return 1 # no matches found
	fi # 1/

	debug_print 4 "Return matching filename: $filename"	
	printf "%s" "$filename" # return best match filename
}
