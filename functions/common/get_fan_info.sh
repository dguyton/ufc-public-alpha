##
# This subroutine takes a snapshot of current fan header metadata.
#
# Poll IPMI for fan data of one or more fan headers.
# Filter results based on indicated target.
# Update fan speed and status for specified target.
#
# Input parameters:
#
#	1. target fan header name or fan cooling type
#	2. verbosity level
#	3. true/false flag to simplify fan status
#
# Target options indicate request to gather metadata for all active fan headers in:
#
# 	--> all				all active fan headers
#	--> empty/null			all active fan headers
# 	--> category name		peripheral device (non-CPU) fans only, if any
# 	--> fan header name 	single, specific fan header id, regardless of fan header state
#
# Verbosity mode levels (i.e., be verbose or quiet):
#
#	--> verbose			be verbose in debug log, report statistics for all fan headers (even inactive)
#	--> quiet				do not report fan speeds to debug log; limit scope to active fan headers only
#	--> anything else		default; limit scope to active fan headers only; do post fan speeds in debug log
#
# Fan state summary:
#	--> when true, simplify fan state
##

function get_fan_info ()
{
	local fan_category
	local fan_id				# fan header id placeholder
	local fan_info				# full text blob returned from IPMI query
	local temp_var				# temporary variable placeholder for some calculations

	local -u fan_name			# force uppercase for consistency of each fan name in IPMI output
	local -l use_simplified_state	# summarizes fan state (versus detailed state type)
	local -l target			# for what to determine status (single fan header, only specific fan duty category, or all fan headers)
	local -l verbosity			# verbosity mode (verbose, quiet, or normal)

	target="$1"				# individual or group of fan headers to gather info about
	verbosity="$2"				# verbosity level
	use_simplified_state="$3"	# simplify fan state when true

	debug_print 4 "Refresh fan header metadata"

	##
	# Ascertain target type.
	#
	# When target is not a specific fan header name, it must reference one of the following:
	#
	# 1. valid fan duty category name; or
	# 2. 'all' (process all fan headers); or
	# 3. a single valid fan header ID
	#
	# Note: When target = all fans, the current fan ID is simply correlated to the master list of
	# valid fan header IDs, and if the current fan ID is valid, it will be processed.
	##

	# presume all fans when no target specified
	[ -z "$target" ] && target="all"

	if [ "$target" != "all" ]; then # 1/ target is more specific than "every fan"
		if [ -n "${target//[0-9]/}" ]; then # 2/ target should be fan header name or fan duty category name
			if validate_fan_category_name "$target"; then # 3/ is target a valid fan duty category name?
				debug_print 3 "Target is a fan duty category name: $target"
				fan_category="$target"
			else # 3/ target might be a fan header name
				if [ -n "${fan_header_id[$target]}" ]; then # 4/ is target a valid fan header name?
					debug_print 3 "Target is a fan header name: $target"
				else # 4/ not a valid target
					debug_print warn 3 "Erroneous fan header/duty type target specified: $target" true
					return 1 # this is not the fan you're looking for
				fi # 4/
			fi # 3/
		else # 2/ target should be a fan header id (numbers only)
			if query_ordinal_in_binary "$target" "fan_header_binary" "master"; then # 3/ is target a known fan header id?
				debug_print 3 "Convert target fan header ID ($target) to corresponding fan header name"
				target="${fan_header_name[$target]}"
				debug_print 3 "Target fan header name: $target"
			else # 3/
				debug_print warn 3 "Invalid fan header ID target specified: $target" true
			fi # 3/
		fi # 2/
	fi # 1/

	# clear existing data to ensure fresh snapshot
	debug_print 4 "Clear existing fan header states and fan speeds before gathering current data"
	fan_header_status=()
	fan_header_speed=()

	if [ -n "$verbosity" ]; then # 1/
		debug_print 3 "Fan polling verbosity mode: ${verbosity^}"
		[ "$verbosity" != "verbose" ] && debug_print 4 "Fan polling scope: active fan headers only"
	fi # 1/

	# tag this debug with trace_debug flag in case there is ever a reason to scrutinize its log data
	debug_print 3 "Parse raw fan metadata snapshot" true

	##
	# Parse raw fan header data from IPMI
	##

	while read -r fan_info; do # 1/ parse each fan header from each line of output

		##
		# Stage 1: Parse each fan name and position reported by IPMI sensor query
		##

		# isolate next fan header name from current IPMI scan
		! parse_ipmi_column "fan_name" "sensor" "fan" "name" "$fan_info" && continue # skip on function call failure

		[ -z "$fan_name" ] && continue # skip empty fan names

		##
		# When a fan header is detected, but not recognized, it means the fan header
		# has no fan header ID. Fan headers without a mapped ID cannot be monitored.
		#
		# This may occur for one of these reasons:
		#	1. User needs to re-run Builder program due to a hardware change
		#	2. Erroneous IPMI output
		#	3. Erroneous IPMI output parsing
		##

		# lookup id of parsed fan name
		fan_id="${fan_header_id[$fan_name]}"

		##
		# Stage 2: Skip fans not matching target criteria
		#
		# - Filter out fan headers that do not meet screening criteria
		# - Filter fan header IDs not matching target fan ID or target fan duty category
		# - Ignore inactive fan headers unless force-update is enabled
		##

		if [ -z "$fan_id" ]; then # 1/ unknown/non-recognized fan header name
			debug_print 3 warn "Fan header name '$fan_name' not recognized (no fan ID)"
			continue
		fi # 1/

		# skip further processing of excluded fan headers
		if query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude"; then # 1/
			debug_print 4 "Skipping fan header '$fan_name' is excluded"
			continue
		fi # 1/

		# skip further processing of inactive fans unless in verbose mode
		if [ "$verbosity" != "verbose" ] && ! query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "master"; then # 1/
			debug_print 4 "Ignoring fan header '$fan_name' because it is not flagged as active in master active fan header binary"
			continue
		fi # 1/

		# trap improbable edge case where fan metadata exists, but master fan binary is unaware of the fan header
		if ! query_ordinal_in_binary "$fan_id" "fan_header_binary" "master"; then # 2/ fan header id not recognized
			debug_print 1 critical "Unexpected fan ID '$fan_id' with data but no binary registration!"
			return 1 # fail as this should never occur
		fi # 2/

		# auto-pass when 'all' fans requested (note 'target' is auto-lowercased)
		if [ "$target" != "all" ]; then # 2/ filter when target is more specific than "all fans"
			if [ -n "$fan_category" ]; then # 3/ target is fan duty category
				if [ "${fan_header_category[$fan_id]}" != "$fan_category" ]; then # 4/ current fan header does not belong to target fan duty category
					debug_print 4 "Fan '$fan_name' does not match target criteria"
					continue
				fi # 4/
			else # 2/ target must be fan header name
				if [ "$fan_name" != "$target" ]; then # 3/ not the fan header name looking for
					debug_print 4 "Fan '$fan_name' does not match target criteria"
					continue
				fi # 3/
			fi # 2/
		fi # 1/

		##
		# Stage 3: Get raw fan header state
		##

		# Input arguments:
		#
		# $1 = sensor type; e.g. fan or temp (short form for temperature)
		# $2 = metric; e.g. name, status, etc.
		# $3 = single line from sensor output dump to be scanned
		##

		if parse_ipmi_column "temp_var" "sensor" "fan" "status" "$fan_info"; then # /1 raw fan header state
			fan_header_status["$fan_id"]="$temp_var"
		fi # 1/

		##
		# Stage 4: Parse fan speed
		##

		##
		# When speed = 0 returned it means one of two things:
		#	1. 0 RPM speed reading; or
		#	2. garbage, null, or incorrect text returned from sensor column parser
		#
		# Latter (#2) will be true when corresponding sensor column not supported
		# by BMC on motherboard, OR if wrong sensor column position indicated in
		# .zone file pointer, OR if there is no reference to the fan speed pointer
		# in .zone file or config file (i.e. undefined).
		##

		if parse_ipmi_column "temp_var" "sensor" "fan" "speed" "$fan_info" # 1/ get speed and convert to integer (default = 0)
			fan_header_speed["$fan_id"]="$(clean_fan_rpm "$temp_var")"
		fi # 1/

		##
		# Stage 5: Refine fan header state
		#
		# There are three (3) possible fan state types:
		#
		# 1. Raw
		# 2. Modified
		# 3. Simple
		#
		# Raw = the raw fan state reported by IPMI, which varies by motherboard manfucturer, and sometimes by model
		# Modified = standardized raw state, which normalizes different manufacturer terms for the same status
		# Simple = basic active/inactive which keeps it simple and to the point
		#
		# Process the fan header state to get a uniform status label using fan state
		# parsing subroutine.
		#
		# Simplify the fan state to a status of active or inactive. The majority of
		# program functions only need to know whether fans are active or inactive, so
		# that inactive fans may be ignored.
		##

		# return modified (summary = false) or simplified (summary = true) fan state
		fan_header_status["$fan_id"]="$(parse_fan_state "$fan_id" "$use_simplified_state")"

		[ "$verbosity" != "quiet" ] && debug_print 3 "$fan_name reported fan speed: ${fan_header_speed[$fan_id]} RPM"
		(( fan_header_speed[$fan_id] == 0 )) && debug_print 3 warn "Failed to detect speed of fan '$fan_name' (fan ID $fan_id)"

	done <<< "$($ipmitool sensor | grep -i fan)" # 1/

	if [ ${#fan_header_status[@]} -eq 0 ]; then # 1/ something went wrong - no data collected
		debug_print 2 warn "No valid metadata collected for target fan headers" true
		return 1
	fi # 1/
}
