##
# order_fan_headers_by_write_position
#
# This function performs the following tasks:
# 1. Process fan headers in write order expected by BMC
# 2. Validates fan names
# 3. Assigns write positions to each fan ID/name
# 4. Prepares write order for direct and group fan control methods, respectively
#
# Create complete fan header write order templates that maps IPMI data payload write
# position to fan header name, fan header ID, and special data bytes.
#
# This subroutine is applicable for direct and group type fan control methods only.
##

##
# Inputs : $ipmi_fan_write_order[] array containing fan names, populated by 'ipmi_order_fan_header_names' subroutine
#
# Outputs: map fan headers in sequential write order for Direct and Group fan control methods
#	- creates array $ipmi_write_position_fan_name[write_position]=fan_name for group fan control method
#	- creates array $ipmi_write_position_fan_id[write_position]=fan_id for group fan control method
#	- creates array $ipmi_fan_id_write_position[fan_id]=write_position for direct fan control method
#
# Direct fan control method:
#	- $ipmi_fan_id_write_position array maps IPMI read fan header ID to IPMI write fan header position
#		- [$fan_id]=write_position
#		- Provides direct look-up translation
#	- $ipmi_write_position_fan_id[] array also needed by execute function under some circumstances
#
# Group fan control method:
#	- ipmi_write_position_fan_name["$write_position"]="$fan_name"
#		- stores fan name or special byte type for each IPMI data byte, in sequential write-position order
#	- ipmi_write_position_fan_id["$write_position"]="$fan_id"
#		- stores fan id for each write position that is a fan header name
#		- used to create write order template with fan IDs, since this info is static
##

function order_fan_headers_by_write_position ()
{
	##
	# Array $ipmi_fan_write_order[] is the template that controls fan write order
	# through IPMI. It must exist and have at least one element.
	##

	case "$fan_control_method" in # 1/
		group|direct)

			# verify ipmi_fan_write_order array exists and has at least one element
			if [ "${#ipmi_fan_write_order[@]}" -eq 0 ]; then # 1/
				debug_print 2 critical "IPMI fan header write order reference array '\$ipmi_fan_write_order[]' is empty or invalid" true
				return 1
			fi # 1/
		;;

		*)
			debug_print 2 warn "Unsupported fan control method '$fan_control_method'" true
			return 1
		;;
	esac # 1/

	# unset target array in case this function gets called more than once
	ipmi_write_position_fan_name=() # maps sequential fan write position to fan name for direct and group methods fan control; [write position] = fan name
	ipmi_write_position_fan_id=() # maps sequential fan write position to fan ID for group method fan control; [write position] = fan id
	ipmi_fan_id_write_position=() # maps fan header write positions use with the direct fan control method; [fan id] = write position

	local fan_id
	local fan_name
	local write_position

	local -a fans_missing_from_inventory
	local -a fans_missing_from_template

	##
	# Runs thru all fan headers in the write order reference array.
	# Ensures fan names in reference array are not null, and are known fan header names or are placeholders.
	# Builds sequentially ordered fan write list based on fan names (ipmi_write_position_fan_name).
	#
	# 1. Confirm every fan header name mentioned in reference array is a valid fan header name
	#	or special reserved word placeholder.
	# 2. Assign write order position for each fan header name / reserved word.
	# 3. Abort when any reference array value is empty.
	# 4. Flag reference array mentions of fan header names that are not found.
	##

	for write_position in "${!ipmi_fan_write_order[@]}"; do # 1/ template array containing fan header and reserved name placeholder references

		# get next write position fan name in template schema
		fan_name="${ipmi_fan_write_order[$write_position]}"

		##
		# Bail on empty template array element.
		#
		# Template cannot have empty position entries. This indicates an error in the
		# construction of the $ipmi_fan_write_order[] array, as every position in this
		# array should indicate either a header name or reserved word.
		##

		if [ -z "$fan_name" ]; then # 1/ empty reference indicates error in data created by ipmi_order_fan_header_names subroutine
			debug_print 1 critical "Template fan write order array (\$ipmi_fan_write_order[])contains an empty entry at index $write_position"
			bail_noop "Invalid template: contains blank fan name at index $write_position"
		fi # 1/

		fan_id="${fan_header_id[$fan_name]}" # lookup id of fan name (will not exist when fan name is a reserved word)

		##
		# Under ideal circumstances, the fan ID order during IPMI read commands is identical to the
		# fan ID order during IPMI write commands. However, this is not always the case. It is not
		# uncommon for the write order to be different than the read order. Fan sensor reading tools
		# may arrange and report fan header names in a different order than that expected by the BMC
		# when it receives fan header write commands. Therefore, the correct order must be known
		# ahead of time (the template), and regardless of how the fans are ordered on IPMI sensor
		# read operations, they must be ordered explicitly in a particular order (i.e., follow template).
		##

		# normal fan headers take precedence in name matching
		if [ -n "$fan_id" ]; then # 1/ fan header known (has been inventoried and has a fan id)
			debug_print 4 "Confirmed IPMI fan write position '$write_position' is fan header '$fan_name'"
		else # 1/ unknown fan header name (not found in inventory)
			if [ -n "${reserved_fan_name[$fan_name]}" ]; then # 2/ fan name is a recognized reserved word
				debug_print 4 "IPMI fan write position '$write_position' appears to be a reserved word placeholder: $fan_name"
			else # 2/ fan name not found in fan header inventory and not match a reserved word
				fans_missing_from_inventory["$write_position"]+=( "$fan_name" )
				continue
			fi # 2/
		fi # 1/

		case "$fan_control_method" in # 1/

			direct)
				##
				# Proxy arrays required when fan control method = direct
				#
				# $ipmi_write_position_fan_id[] maps write position to fan id
				# $ipmi_fan_id_write_position[] maps fan id to write position
				#
				# Fan ID value will be empty null when fan_name is a placeholder (e.g., DUMMY or CPU_OVERRIDE).
				# Reserved word placeholders do not correspond to actual fan headers and lack fan ID entries.
				#
				# This allows back-filling placeholder bytes when building IPMI raw command instructions.
				##

				ipmi_write_position_fan_id["$write_position"]="$fan_id"
				ipmi_fan_id_write_position["$fan_id"]="$write_position"
			;;

			group)

				##
				# Populate global write position tracker by fan name.
				# This is necessary predominantly to retain context of special reserved word
				# placeholders, such as 'DUMMY' bytes and CPU override byte positions.
				##

				ipmi_write_position_fan_name["$write_position"]="$fan_name"
			;;

		esac # 1/
	done # 1/

	##
	# When the fan control method is 'group' there is more information required in order
	# for UFC to work correctly. More information is required to be known by UFC 
	# regarding the server ecosystem because of the fact fan speed commands have to
	# address ALL fan headers simultaneously. As a result of this fact, there must be a
	# benchmark to which actually inventoried fans can be compared. This ensures that no
	# fan header is left out when the group command is compiled, and it allows factoring
	# unusual, but possible scenarios such as inserting dummy or CPU override bytes into
	# the group IPMI command data payload when necessary.
	#
	# Unfortunately, these facts also make the process a bit more fragile, because if
	# any parameter is unaccounted for, it means there is a significant risk that the
	# pre-compiled list of fan write ordering is faulty. And when that may be true, there
	# is no choice but to abort, as the alternative is to potentially send incorrect fan
	# speed commands to potentially random fan headers, which would lead to unpredictable
	# fan behaviors, not to mention causing the monitoring side of UFC to become grossly
	# out of alignment with the write/execution side of manual fan controls.
	##

	##
	# Cross-reference known fan headers (inventoried) with write order reference template.
	#
	# If any known-to-exist fan headers are not found in the template, it means their write
	# order position is unknown. The most common cause is a mistake on the part of the BMC
	# schema declaration in a config file.
	##

	##
	# Fan names found in inventory, but not present in template array are a showstopper.
	##

	# catalog all fan header names in inventory that do not exist in fan names template array
	for fan_name in "${fan_header_name[@]}"; do # 1/ list of all inventoried fan header names
		[ -n "${ipmi_fan_write_order[$fan_name]}" ] && continue # inventoried fan name is mentioned in template array

		# flag fan header name for info purposes when it is not found in list of expected fan names
		fan_id="${fan_header_id[$fan_name]}"
		fans_missing_from_template["$fan_id"]="$fan_name" # fan appears in inventory but not found in template list
	done # 1/

	# any fans existing in inventory but not the fan name template infers a problem with the designated BMC fan schema
	if [ "${#fans_missing_from_template[@]}" -gt 0 ]; then # 1/ inventoried fan names not found in write order reference array

		debug_print 4 warn "There are discovered (inventoried) fan headers not mentioned in the template array"
		debug_print 2 warn "Fan header name(s) not found in write order reference template:"

		for fan_id in "${!fans_missing_from_template[@]}"; do # 1/
			fan_name="${fan_header_name[$fan_id]}"
			debug_print 2 warn "     --> '$fan_name' (fan ID $fan_id)"
		done # 1/

		##
		# When fans were discovered during inventory processing, but those fan header
		# names cannot be found in the fan write order template, then there is no
		# choice but to bail because the write order of each fan cannot be determined,
		# and therefore the write position of each fan header is unclear.
		#
		# The primary cause of this problem is an incorrect fan schema is declared
		# via the config files.
		##

		debug_print 1 critical "One or more discovered fan headers are unknown to the fan schema template array"
		debug_print 2 bold "Suggest verifying BMC schema as it may be incorrect"
		bail_noop "Unrecoverable error: proper IPMI fan write order cannot not be determined"

	fi # 1/

	##
	# Fan names missing from inventory sweep, but present in fan header template:
	# 1. Do not concern Direct fan control method situations, as UFC can ignore those fan names.
	# 2. Can be resolved when Group fan control method, provided a 'dummy' type placeholder value
	#	is available.
	# 3. If Group fan control method and no default 'dummy' type placeholder value exists, then
	#	the program cannot continue as it is not possible to address the uknown fan header
	#	positions within the group IPMI raw data payload.
	##

	# situation can be salvaged only when dummy value is known from config files
	if [ "$fan_control_method" = "group" ] && [ "${#fans_missing_from_inventory}" -gt 0 ]; then # 1/
		debug_print 3 warn "These fan header names in fan write order template not found in fan inventory:"

		# list of fan header names expected per template, but not found
		for write_position in "${!fans_missing_from_inventory[@]}"; do # 1/
			debug_print 3 "Missing fan header name: ${fans_missing_from_inventory[$write_position]}"
		done # 1/

		# attempt to substitute 'dummy' fan duty value for fan header names missing from fan inventory
		if [ -n "${reserved_fan_name[DUMMY]}" ]; then # 2/ situation can be salvaged when a DUMMY reserved word placeholder exists
			for write_position in "${!fans_missing_from_inventory[@]}"; do # 1/
				debug_print 3 caution "Applying 'DUMMY' placeholder to fan write order position: $write_position"
				ipmi_write_position_fan_name["$write_position"]="${reserved_fan_name[DUMMY]}" # substitute dummy reserved word placeholder in missing write position
			done # 1/
		else # 2/ uncoverable error, cannot proceed further
			debug_print 1 critical "Aborting fan ordering process because one or more fan names expected by write sequence are missing from fan inventory"
			debug_print 2 bold "Suggest verifying BMC schema as it may be incorrect"
			bail_noop "Unrecoverable error: IPMI fan write order could not be determined"
		fi # 2/
	fi # 1/

	debug_print 4 "Fan header write order mapping completed for method '$fan_control_method'"
	return 0
}
