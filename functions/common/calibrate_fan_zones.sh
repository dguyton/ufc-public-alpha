##
# Calibrate fan group/zone binaries: Which fan zones exist?
#
# Service Launcher only.
#
# Cross-references fan group/zone assignments between fan header metadata and fan zone
# binary trackers.
#
# When fan control is not zoned, this process is less important, however it is stil relevant
# because subsequent processes monitor fan group (zone) amalgamation of fan header IDs in order
# to ascertain when support for a particular type of fan duty cooling has gone off-line.
##

##
# Fan group/zone alignment validation.
#
# Cross-reference the fan group/zone ID and fan duty category metadata at the fan
# header level with the fan zone binary records. They should match.
#
# If they do not match, go with the revised zone configurations that are based on current
# environmental conditions, and alert the user they should re-run Builder program.
#
# The fan header metadata is treated as the source-of-truth, because it was originally
# derived from the fan group schemas by the Builder program. Each non-excluded fan
# header should belong to a fan group/zone.
#
# When its fan group/zone ID is known, this means the current fan header is related to
# that group/zone ID. In conjunction with its fan duty category, it should be possible
# to determine its ordinal position and fan zone category binary the fan header belongs
# to. This information can then be cross-referenced against the category specific fan
# zone binaries imported via the Launcher .init file.
#
# When fans are controlled via zones, it is imperative these values are aligned.
# When a mismatch is detected, the program may continue, but this is a danger sign when
# the fan control method is zoned. When this is true, the user should be strongly cautioned
# to re-run the Builder. When fan control is not based on a zoned model, this issue is less
# dire, but still warrants proper correction, which requires re-running the Builder.
#
# The metadata for each fan header includes a reference to the fan zone ID it belongs to,
# so long as its category is not "exclude" (excluded fan header). Therefore, the fan header
# should be flagged in the master fan zone binary and the fan zone binary corresponding
# to the fan duty category to which the fan belongs.
#
# Therefore, it is possible to calibrate or reset these dependencies by simply reviewing
# related fan header metadata, which is treated as the source-of-truth or primary authority.
##

# re-assign each fan header to the fan duty category group/zone type binary it belongs
function calibrate_fan_zones ()
{
	local error_condition

<<>>

--> rename var as it matches a global var name

	local fan_duty_category
	local fan_id
	local fan_name
	local schema_type
	local zone_id

	[ "$fan_control_method" = "zone" ] && schema_type="zone" || schema_type="group"

	debug_print 1 "Validate fan ${schema_type}s"

	# begin with a blank slate regarding which fan zones exist
	debug_print 3 "Flushed master and duty category fan zone binaries"
	fan_zone_binary[master]="$(flush "$fan_zone_binary_length")"

	# flush category-level fan zone binaries
	for fan_duty_category in "${fan_duty_category[@]}"; do # 1/
		[ "$fan_duty_category" = "exclude" ] && continue # do not create an 'exclude' fan zone
		fan_zone_binary["$fan_duty_category"]="$(flush "$fan_zone_binary_length")"
	done # 1/

	##
	# Deterministic logic to identify existing fan headers works by scanning
	# each fan duty category type for fan headers with metadata aligning them
	# to the given fan duty category. Matching fan zone IDs are set for both
	# the specified fan duty category fan zone and the master fan zone binary.
	##

	# avoid dealing with invalid fan category names in fan header metadata
	for fan_duty_category in "${fan_duty_category[@]}"; do # 1/

		# there should be no 'exclude' fan zone binaries
		[ "$fan_duty_category" = "exclude" ] && continue

		# look for fan headers aligned with current fan duty category name
		for fan_id in "${!fan_header_name[@]}"; do # 2/

			fan_name="${fan_header_name["$fan_id"]}"
			fan_category="${fan_header_category["$fan_id"]}"

			# this should have been trapped in prior processes, but also belongs here as a precaution
			if [ -z "$fan_category" ]; then # 1/ should not happen, but trap empty fan category association
				debug_print 2 warn "Excluding fan header '$fan_name' (fan ID $fan_id) because its fan duty category is unknown"
				fan_header_category["$fan_id"]="exclude"
				error_condition=true
				continue
			fi # 1/

			# fan belongs to a different fan duty category than that being screened for ($fan_duty_category)
			[ "$fan_category" != "$fan_duty_category" ] && continue

			zone_id="${fan_header_zone["$fan_id"]}" # fetch fan zone id

			if [ -z "$zone_id" ]; then # 1/ should not happen, but guard against the possibility to prevent errors
				debug_print 2 warn "Excluding fan header '$fan_name' (fan ID $fan_id) because its $schema_type ID is unknown"
				fan_header_category["$fan_id"]="exclude"
				error_condition=true
				continue
			fi # 1/

			# tag zone as existing in master fan zone tracker, when not already set
			if ! query_ordinal_in_binary "$zone_id" "fan_zone_binary" "master"; then # 1/ zone id the fan belongs to has not been tagged yet
				set_ordinal_in_binary "on" "$zone_id" "fan_zone_binary" "master"
				debug_print 3 "Tagged $schema_type ID $zone_id as existing"

			else # 1/ zone id tagged previously (in prior loop iteration) in master zone binary

				##
				# Ensure current fan zone has not been previously assigned to a different
				# fan duty category zone binary. Fan zones may only belong to one fan duty category.
				#
				# When the current fan zone ID is already known to the master fan zone tracker,
				# and yet it is not already known to the current fan duty category binary tracker,
				# then it means this same zone ID must have been previously tagged in a different fan
				# duty category. This is not acceptable as it would mean the same fan zone would
				# be represented by two independent fan duty categories, which is not possible.
				#
				# In other words, the expectation (i.e., happy path) is that if the current fan zone ID
				# has previoulsy been tagged 'on', then any other fan header with that same fan Zone ID
				# must belong to the same fan duty category. If not, there is a mismatch problem.
				##

				if ! query_ordinal_in_binary "$zone_id" "fan_zone_binary" "$fan_duty_category"; then # 2/ not tracked by current fan duty binary
					debug_print 1 warn "${schema_type^} ID $zone_id is associated with more than one non-excluded fan duty category"
					debug_print 1 critical "Re-run Builder to resolve discovered anomalies"
					bail_with_fans_full "Fan ${schema_type}s cannot be assigned to more than one fan duty category"
				fi # 2/
			fi # 1/

			# current zone id should be represented in current fan duty category zone tracker
			if ! query_ordinal_in_binary "$zone_id" "fan_zone_binary" "$fan_duty_category"; then # 1/ ensure zone is also tracked in category-specific binary
				set_ordinal_in_binary "on" "$zone_id" "fan_zone_binary" "$fan_duty_category" # force registration
			fi # 1/
		done # 2/
	done # 1/

	[ "$error_condition" = true ] && debug_print 1 critical "Fan header metadata inconsistencies detected — re-run Builder to restore zone/category integrity" true

	return 0
}
