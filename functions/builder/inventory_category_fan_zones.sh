##
# Establish fan duty category type fan group/zone binaries.
#
# This function assigns each non-excluded fan header to its respective fan duty category zone binary
# (e.g., cpu_fan_zone_binary, disk_fan_zone_binary, etc.), based on its metadata.
#
# Builder program only.
#
# These rules apply regardless of fan control method. When fan control is not zoned, this information assists
# UFC in keeping track of which types of fan cooling duty categories are currently supported by the system.
#
# 1. Every non-excluded fan header will be assigned to one category-specific fan group/zone.
# 2. Fan headers may not belong to more than one fan duty category.
# 3. Fan headers may not belong to more than one fan zone or more than one fan zone category type.
# 4. Fan headers may not be tagged as belonging to more than one fan duty category type.
# 5. Zone IDs that are part of fan header metadata indicate the fan zone ID to which the fan belongs.
# 6. Excluded fans are not included in any fan zone binary.
# 7. If present, excluded fan legacy fan zone id data indicates only its original fan schema group ID.
#
# Pre-requisites:
# 1. Master fan zone binary assignments made during fan group schema parsing.
# 2. CPU fan header validation.
##

# assign each fan header to the fan duty category group/zone type binary it belongs to
function inventory_category_fan_zones ()
{
	local zone_binary_pointer
	local fan_category
	local fan_id
	local fan_name
	local match_found
	local schema_type
	local zone_category
	local zone_id

	[ "$fan_control_method" = "zone" ] && schema_type="zone" || schema_type="group"

	##
	# Flush category-level binaries to prevent any potential data pollution
	# from unknown sources (e.g., noise data inserted into .init file created
	# by Builder or manually inserted by a user).
	##

	# flush category-level fan header binaries to ensure they have no pre-sets
	debug_print 4 "Flush fan duty category fan $schema_type binaries"

	for zone_category in "${fan_duty_category[@]}"; do # 1/
		[ "$zone_category" = "exclude" ] && continue

		local -n zone_binary_pointer="${zone_category}_fan_zone_binary"
		zone_binary_pointer="$(flush "$fan_zone_binary_length")"
	done # 1/

	# assign each fan header to the fan duty category zone binary it belongs to
	for fan_id in "${!fan_header_name[@]}"; do # 1/

		fan_category="${fan_header_category[$fan_id]}" # prefix of fan group/zone binary to manipulate
		fan_name="${fan_header_name[$fan_id]}"

		if [ -z "$fan_category" ]; then # 1/ should not happen, but trap any fan missing fan category association
			debug_print 2 warn "Excluding fan header '$fan_name' (fan ID $fan_id) because its fan duty category is unknown"
			fan_header_category["$fan_id"]="exclude"
			continue
		fi # 1/

		[ "$fan_category" = "exclude" ] && continue

		zone_id="${fan_header_zone[$fan_id]}" # fan zone id current fan header is assigned to

		if [ -z "$zone_id" ]; then # 1/ should not happen, but guard against the possibility to prevent errors
			debug_print 2 warn "Forcibly excluding fan header '$fan_name' (fan ID $fan_id) because its fan $schema_type ID is unknown"
			fan_header_category["$fan_id"]="exclude"
			continue
		fi # 1/

		##
		# Trap invalid fan category names in fan header metadata
		##

		# verify fan_category mentioned in fan metadata is a valid fan category
		unset match_found

		for zone_category in "${fan_duty_category[@]}"; do # 1/
			if [ "$zone_category" = "$fan_category" ]; then # 1/
				match_found=true
				break
			fi # 1/
		done # 1/

		if [ "$match_found" != true ]; then # 1/
			debug_print 2 warn "Forcibly excluding fan header '$fan_name' (fan ID $fan_id) because its fan category name '$fan_category' is invalid"
			fan_header_category["$fan_id"]="exclude"
			continue
		fi # 1/

		# concatenate fan zone binary string name
		zone_binary_pointer="${fan_category}_fan_zone_binary"

		# set category type zone presence when not already set
		if ! query_ordinal_in_binary "$zone_id" "zone_binary_pointer" "master"; then # 1/
			set_ordinal_in_binary "on" "$zone_id" "zone_binary_pointer"
			debug_print 4 "Fan $schema_type ID $zone_id assigned to '$fan_category' cooling duty type"
		fi # 1/

	done # 1/
}
