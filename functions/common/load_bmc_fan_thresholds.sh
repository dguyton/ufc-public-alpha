# establish BMC fan speed thresholds for each fan header ID
function load_bmc_fan_thresholds ()
{
	local data # temporary data placeholder
	local fan_id
	local -u fan_name
	local fan_info # single line of text from IPMI sensor output

	while read -r fan_info; do # 1/ parse each each line of IPMI sensor output

		# isolate next fan header name from IPMI sensor scan
		! parse_ipmi_column "fan_name" "sensor" "fan" "name" "$fan_info" && continue
		[ -z "$fan_name" ] && continue # empty fan name

		fan_id="${fan_header_id[$fan_name]}"
		[ -z "$fan_id" ] && continue # no fan id

		! query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "master" && continue # unknown fan header

		# lower fan speed boundaries in the BMC
		if parse_ipmi_column "data" "sensor" "fan" "lnr" "$fan_info"; then # 1/ Lower Non-Recoverable
			fan_speed_lnr["$fan_id"]="$(clean_fan_rpm "$data")"
		else # 1/
			debug_print 3 "Failed to determine Lower Non-Recoverable (LNR) speed for fan header '$fan_name'"
		fi # 1/

		if parse_ipmi_column "data" "sensor" "fan" "lcr" "$fan_info"; then # 1/ Lower Critical
			fan_speed_lcr["$fan_id"]="$(clean_fan_rpm "$data")"
		else # 1/
			debug_print 3 "Failed to determine Lower Critical (LCR) speed for fan header '$fan_name'"
		fi # 1/

		if parse_ipmi_column "data" "sensor" "fan" "lnc" "$fan_info"; then # 1/ Lower Non-Critical
			fan_speed_lnc["$fan_id"]="$(clean_fan_rpm "$data")"
		else # 1/
			debug_print 3 "Failed to determine Lower Non-Critical (LNC) speed for fan header '$fan_name'"
		fi # 1/

		# upper fan speed boundaries in the BMC
		if parse_ipmi_column "data" "sensor" "fan" "unc" "$fan_info"; then # 1/ Upper Non-Critical
			fan_speed_unc["$fan_id"]="$(clean_fan_rpm "$data")"
		else # 1/
			debug_print 3 "Failed to determine Upper Non-Critical (UNC) speed for fan header '$fan_name'"
		fi # 1/

		if parse_ipmi_column "data" "sensor" "fan" "ucr" "$fan_info"; then # 1/ Upper Critical
			fan_speed_ucr["$fan_id"]="$(clean_fan_rpm "$data")"
		else # 1/
			debug_print 3 "Failed to determine Upper Critical (LCR) speed for fan header '$fan_name'"
		fi # 1/

		if parse_ipmi_column "data" "sensor" "fan" "unr" "$fan_info"; then # 1/ Upper Non-Recoverable
			fan_speed_unr["$fan_id"]="$(clean_fan_rpm "$data")"
		else # 1/
			debug_print 3 "Failed to determine Upper Non-Recoverable (UNR) speed for fan header '$fan_name'"
		fi # 1/

		debug_print 4 "Parsed thresholds for $fan_name (ID $fan_id): LNR=${fan_speed_lnr[$fan_id]}, LCR=${fan_speed_lcr[$fan_id]}, LNC=${fan_speed_lnc[$fan_id]}"
		debug_print 4 "Parsed thresholds for $fan_name (ID $fan_id): UNC=${fan_speed_unc[$fan_id]}, UCR=${fan_speed_ucr[$fan_id]}, UNR=${fan_speed_unr[$fan_id]}"

	done <<< "$($ipmitool sensor | grep -i fan)" # 1/
}
