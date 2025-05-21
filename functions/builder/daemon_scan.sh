##
# Validate daemon service exists and its .service file location.
#
# Scan for known fan controller daemon service.
# Locate corresponding daemon service (.service) file.
#
# When expected daemon name is confirmed and validated, attempt
# to derive its corresponding executable filename.
#
# When no match is found, search for and report possible matches
# based on daemon name filter. Encourage user to investigate high
# probability matches, but do not presume they are valid.
#
# Probable matches are only reported, and are not actioned.
#
# When no confirmed match is found, corresponding global vars are
# not modified.
##

function daemon_scan ()
{
	if (( $# != 4 )); then # 1/
		debug_print 4 warn "Missing one or more required input(s)" true
		return 1
	fi # 1/

	local confidence
	local daemon_property
	local daemon_service_filename
	local daemon_service_name
	local daemon_service_name_list
	local filter
	local pattern
	local version # program version to scan for

	##
	# $1, $2, and $3 must be global variables. They cannot be passed
	# from another function.
	##

	if [ -z "$1" ]; then # 1/
		debug_print 3 warn "Missing name of global variable to populate with daemon service name (\$1)"
		return 1
	fi # 1/

	if [ -z "$2" ]; then # 1/
		debug_print 3 warn "Missing name of global variable to populate with daemon service filename (\$2)"
		return 1
	fi # 1/

	if [ -z "$3" ]; then # 1/
		debug_print 3 warn "Missing name of global variable to populate with daemon service directory (\$3)"
		return 1
	fi # 1/

	if [ -z "$4" ]; then # 1/
		debug_print 3 caution "Daemon service name search filter not defined (\$4)"
		return 1
	fi # 1/

	##
	# NOTE: These indirect variable references work correctly only when
	# any other function calling this function supplies global varible names
	# for these particular arguments ($1, $2, $3).
	##

	if declare -p "$1" &>/dev/null; then # 1/ name of global variable to populate with daemon service name
		local -n daemon_service_name_target="$1"
	else # 1/ object location is literal
		debug_print 3 warn "Invalid global variable name for source daemon service name: $1" true true
		return 1
	fi # 1/

	if declare -p "$2" &>/dev/null; then # 1/ global variable name to populate with daemon .service full filename path
		local -n daemon_service_target_filename="$2"
	else # 1/
		debug_print 3 warn "Invalid global variable name for target daemon service filename: $2" true true
		return 1
	fi # 1/

	if declare -p "$3" &>/dev/null; then # 1/ name of global variable to populate wit parent directory of daemon .service file
		local -n daemon_service_target_dir="$3"
	else # 1/
		debug_print 3 warn "Global variable name for parent directory of target daemon service file is invalid: $3" true true
		return 1
	fi # 1/

	filter="$4" # text to filter daemon names when daemon service name is unknown

	##
	# When daemon service name is known, scan its state, associated
	# daemon .service filename, parent dir.
	#
	# When it is not known, skip down to filter scanning section and attempt to
	# identify a probable matching pre-existing daemon service, if there is one.
	##

	if [ -n "$daemon_service_name_target" ]; then # 1/ expected daemon service name
		if daemon_property="$(get_daemon_property "$daemon_service_name_target" LoadState)"; then # 2/
			if [ "$daemon_property" = "loaded" ]; then # 3/ looking for current daemon state, which should be loaded | not-found
				debug_print 3 "Discovered pre-existing daemon service with default/expected daemon service name"

				# parse exec target filename from .service file
				debug_print 4 "Parse embedded target executable filename"

				# deduce .service filename of daemon service name
				if daemon_service_target_filename="$(parse_daemon_service_filename "$daemon_service_name_target")"; then # 4/ full filename path of .service file parsed and not null
					debug_print 4 ".service file location: $daemon_service_target_filename"

					daemon_service_target_dir="$(dirname "$daemon_service_target_filename")" # set associated global parent daemon dir, indirectly

					if trim_trailing_slash "$daemon_service_target_dir" && [ -n "$daemon_service_target_dir" ]; then # 5/
						return 0
					else # 5/ do not authenticate daemon service file when located in root directory or error occurred parsing parent dir location
						debug_print 4 "Ignoring daemon .service file because it is located in root directory"
						return 1
					fi # 5/
				else # 4/ do not modify global daemon service target dir
					debug_print 4 warn "Program executable filename pointed to by daemon service file appears to be invalid (file not found or inaccessible)"
				fi # 4/
			else # 3/ default daemon service name not found, try filter-based scan below
				debug_print 3 "No pre-existing daemon service found matching expected service name: $daemon_service_name_target"
				unset daemon_service_name_target
			fi # 3/
		else # 2/
			debug_print 4 warn "An error was encountered while attempting to process target daemon property"
			debug_print 4 "Failed to determine daemon service state due to daemon property error"
			debug_print 4 "Disqualify service name '$daemon_service_name_target'"
			unset daemon_service_name_target
		fi # 2/
	fi # 1/

	##
	# When daemon name not known ahead of time ($daemon_service_name_target is null),
	# search for daemon name based on keyword filter ($filter).
	#
	# Look for possible alternate daemon service names that may be related to fan
	# controller.
	#
	# This section only runs when default service name is unknown or was not found.
	##

	if [ -z "$filter" ]; then # 1/
		debug_print 3 warn "Could not scan for related daemon service names because no name search filter was specified" true
		return 1 # failure due to bad filter and no match found in section above
	fi # 1/

	debug_print 3 "Utilize alternate scan method to identify potentially related daemon service names"

	# parse all existing, potentially matching daemon service names
	if ! daemon_service_name_list="$(systemctl list-units --type=service --all | grep -i "$service_name" | grep -i "$filter")" || [ -z "$daemon_service_name_list" ]; then # 1/
		debug_print 3 "Scan filter '$filter' yielded no potential matching daemon service names"
		return 1 # scan failed
	fi # 1/

	##
	# Section below is for informational purposes only.
	#
	# Scan for similar, pre-existing daemon service names when expected name not found.
	# Make suggestions to user (via log file) regarding potential matches that could be
	# investigated further.
	#
	# This outcome is not a definitive success (narrowed down search criteria to a single
	# hit), but is also not a failure. Rather, it is an ambiguous result which the user
	# can and should follow-up on.
	##

	debug_print 4 "Scan for similar, pre-existing daemon service names using word filter when expected name unknown or not found"

	while read -r daemon_service_name; do # 1/ parse each filename
		if daemon_service_filename="$(parse_daemon_service_filename "$daemon_service_name")"; then # 1/ deduced .service filename of daemon service name and it is not null
			debug_print 4 "Processing file: $daemon_service_filename"
		else # 1/
			debug_print 4 caution "Syntax error processing .service filename for daemon service named '$daemon_service_name'"
			continue # failed to locate service file or not a normal file
		fi # 1/

		confidence="LOW" # likelihood this daemon is related to a previous run of fan controller builder or another fan controller

		debug_print 3 "Potential match: $daemon_service_name"
		debug_print 3 "Related .service file location: $daemon_service_filename"
		debug_print 4 "Likely some sort of fan controller daemon? $(grep -qi "fan controller" "$daemon_service_filename" 2>/dev/null && printf "YES" || printf "NO")"

		# check whether or not the potential match file can be scanned
		if ! query_target_permissions "$daemon_service_filename" PERM_READ_ONLY; then # 1/
			debug_print 4 "Skipping this file as current user lacks sufficient file system access rights"
			continue
		fi # 1/

		# validate program version of daemon .service file
		if version="$(parse_file_version "$daemon_service_filename")"; then # 1/
			if [ "$version" = "$builder_program_version" ]; then # 2/
				debug_print 4 "Daemon program version reference matches this Builder"
				confidence="MEDIUM"

				pattern="^# Description=(\"${program_name}\"|${program_name})\$" # match description line containing program name with or without it being bounded by double quotes
				grep -i -E "$pattern" "$daemon_service_filename" 2>/dev/null && confidence="HIGH"
			fi # 2/

			debug_print 3 "Probability this daemon service is a related fan controller: $confidence"
			[ "$confidence" != "LOW" ] && debug_print 4 "Recommend a manual investigation of this daemon service file and its associated ExecStart file"
		else # 1/
			debug_print 4 "Encountered parsing error, skipping this file"
		fi # 1/
	done <<< "$daemon_service_name_list" # 1/

	debug_print 1 bold "See program log for recommendations of pre-existing daemon service references to be investigated" false true
}
