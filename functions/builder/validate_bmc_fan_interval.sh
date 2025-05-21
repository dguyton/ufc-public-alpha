##
# Determine whether or not BMC fan interval threshold can be calculated or verified.
# Whether or not this is possible depends on whether or not the fan hysteresis can be detected.
#
# Calculate lowest common multiple bmc fan speed threshold interval among all fan headers.
# Populates global $bmc_threshold_interval used to calculate proper BMC fan threshold settings.
##

function validate_bmc_fan_interval ()
{
	local bmc_interval	# calculated BMC threshold interval
	local fan_hysteresis
	local fan_hysteresis_positive
	local fan_hysteresis_negative
	local fan_id
	local fan_info
	local fan_name

	local -a fan_array

	if [ "$bmc_threshold_interval" -gt 0 ]; then # 1/
		debug_print 3 "Validate pre-existing BMC threshold interval value declared in configuration ($bmc_threshold_interval RPM)"
	else # 1/
		debug_print 3 "Auto-detect BMC fan hysteresis"
	fi # 1/

	bmc_interval=0

	##
	# Attempt to validate BMC fan threshold interval when it is declared
	# in the config file or a .zone file.
	#
	# If not declared in either, attempt to determine its value.
	#
	# If fan hysteresis is detected, override the declared hysteresis value
	# or apply the fan hysteresis if no value was declared.
	#
	# When auto-detection of fan hysteresis is possible, attempt to determine
	# both positive and negative fan hysteresis values, and find their lowest
	# common denominator, and apply it as the fan hysteresis. Set the BMC fan
	# threshold interval to the fan hysteresis.
	##

	case "$mobo_manufacturer" in # 1/
		asrock|dell|gigabyte|hpe|ibm|intel|lenovo|quanta|supermicro|tyan)

			##
			# There are multiple possible methods of auto-detecting fan hysteresis for a particular fan header.
			# The preferred method is to parse IPMI sensor data based on pre-defined data column, when declared
			# in config file.
			##

			if [ "${ipmi_sensor_column_fan[hysteresis]}" -gt 0 ]; then # 1/

				while read -r fan_info; do # 1/ parse each line of IPMI fan sensor scan

					if parse_ipmi_column "fan_hysteresis" "sensor" "fan" "hysteresis" "$fan_info"; then # 2/
						fan_hysteresis="${fan_hysteresis//[!0-9.]/}"
						fan_hysteresis="${fan_hysteresis%.*}"
					fi # 2/

					# sanitize result
					fan_hysteresis="$(clean_fan_rpm "$fan_hysteresis")"

					if [ -n "$fan_hysteresis" ] && [ "$fan_hysteresis" -gt 0 ]; then # 2/ discovered valid fan hysteresis value
						if [ "$fan_hysteresis" -ne "$bmc_interval" ]; then # 3/ not equivalent to previously discovered fan hysteresis
							if parse_ipmi_column "fan_name" "sensor" "fan" "name" "$fan_info"; then # 4/ parse targetted sensor data
								if [ -n "$fan_name" ] && ! query_ordinal_in_binary "${fan_header_id[$fan_name]}" "fan_header_binary" "exclude"; then # 5/ do not process excluded fan headers
									if [ "$bmc_interval" -gt 0 ]; then # 6/ not first discovered fan hysteresis value
										bmc_interval="$(lcm $((bmc_interval)) $((fan_hysteresis)))"
									else # 6/ first discovered value
										bmc_interval="$((fan_hysteresis))"
										break # all records will have same value since fan hysteresis set by BMC and is shared by all fan headers
									fi # 6/
								fi # 5/
							fi # 4/
						fi # 3/
					fi # 2/
				done <<< "$($ipmitool sensor | grep -i fan)" # 1/

			else # 1/ ipmi sensor column is not an option, try alt methods
				debug_print 4 "Primary method not available, trying alt method 1 (pos/neg average)"

				##
				# Alt method: Parse hysteresis values of each fan header.
				# Average them when both positive and negative are detectable. Otherwise, apply
				# one or the other, or neutral (non-signed) indicated hysteresis value.
				##

				convert_binary_to_array "${fan_header_binary[master]}" "fan_array"

				for fan_id in "${!fan_array[@]}"; do # 1/
					query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude" && continue # skip excluded fan headers
					fan_hysteresis=0 # reset

					# attempt to parse positive and negative hysteresis values if they exist
					fan_hysteresis_positive="$($ipmitool sensor get "${fan_header_name[$fan_id]}" | grep -i 'Positive Hysteresis')"
					fan_hysteresis_positive="${fan_hysteresis_positive//[!0-9.]/}" # strip non-numeric characters
					fan_hysteresis_positive="${fan_hysteresis_positive%.*}" # retain only left of decimal point

					fan_hysteresis_negative="$($ipmitool sensor get "${fan_header_name[$fan_id]}" | grep -i 'Negative Hysteresis')"
					fan_hysteresis_negative="${fan_hysteresis_negative//[!0-9.]/}"
					fan_hysteresis_negative="${fan_hysteresis_negative%.*}"

					if [ -n "$fan_hysteresis_positive" ] && [ "$fan_hysteresis_positive" -gt 0 ]; then # 2/ positive value exists
						if [ -n "$fan_hysteresis_negative" ] && [ "$fan_hysteresis_negative" -gt 0 ]; then # 3/ negative value also exists
							fan_hysteresis="$(lcm $((fan_hysteresis_positive)) $((fan_hysteresis_negative)))" # calculate least common multiplier
						else # 3/ only positive value found
							fan_hysteresis="$fan_hysteresis_positive"
						fi # 3/
					else # 2/ no positive value found
						if [ -n "$fan_hysteresis_negative" ] && [ "$fan_hysteresis_negative" -gt 0 ]; then # 3/ only negative value exists
							fan_hysteresis="$fan_hysteresis_negative"
						else # 3/ no positive or negative value found, try generic query
							fan_hysteresis="$($ipmitool sensor get "${fan_header_name[$fan_id]}" | grep -i 'Hysteresis' | head -1)" # evaluate first line only
							fan_hysteresis="${fan_hysteresis//[!0-9.]/}"
							fan_hysteresis="${fan_hysteresis%.*}"
						fi # 3/
					fi # 2/

					if [ "$fan_hysteresis" -gt 0 ]; then # 2/ valid fan hysteresis identified for current fan header
						if [ "$bmc_interval" -gt 0 ]; then # 3/ not first result
							if [ "$fan_hysteresis" -ne "$bmc_interval" ]; then # 4/ check if current fan interval differs from previously discovered interval
								bmc_interval="$(lcm "$bmc_interval" "$fan_hysteresis")" # assign lowest common multiplier as new interval value
							else # 4/ first valid hit
								bmc_interval="$fan_hysteresis" # save first result
							fi # 4/
						fi # 3/
					else # 2/
						debug_print 4 warn "Unable to determine fan hysteresis for fan header ${fan_header_name[$fan_id]}"
					fi # 2/
				done # 1/
			fi # 1/
		;;

		*)
			debug_print 3 "Fan hysteresis detection method for this motherboard manufacturer is undefined or unknown"
		;;

	esac # 1/

	##
	# When BMC fan hysteresis interval could be deduced from IPMI fan info, and
	# a user-specified fan hysteresis value exists in config file, compare them.
	#
	# When BMC fan hysteresis interval could not be deduced from fan metadata,
	# retain user-specified fan hysteresis value from config file, when it exists.
	#
	# possible result outcomes:
	# 	--> 1. fan interval is provided in config, and is detected, and they match
	#	--> 2. fan interval is provided in config, and is detected, and they do not match
	#	--> 3. fan interval is provided in config, and is not detected
	#	--> 4. fan interval is not provided in config, and is detected
	#	--> 5. fan interval is not provided in config, and is not detected
	##

	if [ "$bmc_interval" -gt 0 ]; then # 1/ common fan hysteresis detected successfully (1,2,4)
		if [ "$bmc_threshold_interval" -gt 0 ]; then # 2/ bmc interval was declared in config (1,2)
			if [ "$fan_hysteresis" -ne "$bmc_threshold_interval" ]; then # 3/ detected fan interval does not match user-declared fan interval value (2)
				debug_print 3 warn "Detected BMC fan hysteresis does not agree with BMC fan speed interval declared in configuration. Detected value will be applied"
				debug_print 4 "Modifying BMC threshold interval ($bmc_threshold_interval) to a common multiple of detected common hysteresis interval ($fan_hysteresis)"
				bmc_threshold_interval="$(lcm "$bmc_threshold_interval" "$bmc_interval")" # assign least common multiplier as new fan interval value
			else # 3/ they match (1)
				debug_print 4 "Confirmed BMC fan interval declared in configuration matches fan hysteresis reported by BMC"
			fi # 3/
		else # 2/ fan interval = 0 (not declared in config), but is detected (4)
			bmc_threshold_interval="$bmc_interval"
			debug_print 3 "Validated BMC fan interval (fan hysteresis) will be applied: $bmc_threshold_interval RPM"
		fi # 2/
	else # 1/ bmc fan interval not identified via automation (3,5)
		if [ "$bmc_threshold_interval" -gt 0 ]; then # 2/ bmc interval declared in config, presume it is accurate (3)
			debug_print 3 caution "Unable to detect BMC fan hysteresis. Using config-provided interval if available."
		else # 2/ pre-existing fan interval not declared in config and could not be detected automatically (5)
			debug_print 3 "BMC fan interval (fan hysteresis) could not be determined, therefore related functions will be skipped"
		fi # 2/
	fi # 1/

	# disable automatically setting BMC fan thresholds when fan hysteresis could not be determined
	if [ "$bmc_threshold_interval" -eq 0 ]; then # 1/
		auto_bmc_fan_thresholds=false
		debug_print 2 "Automatic BMC fan threshold setting disabled"
		debug_print 3 "BMC fan threshold interval (fan hysteresis) could not be validated (if specified in config) or identified (via automation)"
	fi # 1/
}
