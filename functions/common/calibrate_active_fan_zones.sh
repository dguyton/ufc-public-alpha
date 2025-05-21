# Refresh active fan zone binaries
function calibrate_active_fan_zones ()
{
	local fan_category
	local fan_id
	local schema_type
	local status
	local zone_binary_pointer
	local zone_id

	[ "$fan_control_method" = "zone" ] && schema_type="zone" || schema_type="group"

	for fan_id in "${!fan_header_name[@]}"; do # 1/

		# check fan state: is it active?
		status="${fan_header_status[$fan_id]}"

		# if not active then skip
		[ "$status" != "active" ] && continue

		# lookup its group/zone id
		zone_id="${fan_header_zone[$fan_id]}"

		# lookup its fan duty category
		fan_category="${fan_header_category[$fan_id]}"

		# trap excluded fans to skip further processing
		[ "$fan_category" = "exclude" ] && continue

		# is zone_id ordinal in master active fan zone binary already set on? if yes, then skip
		query_ordinal_in_binary "$zone_id" "fan_zone_active_binary" "master" && continue

		# set zone_id ordinal in master active fan zone binary to on
		set_ordinal_in_binary "on" "$zone_id" "fan_zone_active_binary"

		debug_print 4 "Tagged $schema_type ID $zone_id as active in master active fan zone binary"

		# set zone_id ordinal in fan_category active fan zone binary to on
		local -n zone_binary_pointer="${fan_category}_fan_zone_active_binary"
		set_ordinal_in_binary "on" "$zone_id" "zone_binary_pointer"

		debug_print 4 "Tagged $schema_type ID $zone_id as active in category-specific active fan zone binary: \$${!zone_binary_pointer}"

	done # 1/
}
