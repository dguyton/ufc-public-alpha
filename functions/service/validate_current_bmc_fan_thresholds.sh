##
# Valdiate current BMC fan speed thresholds against those established by Builder.
#
# Service Launcher only.
##

function validate_current_bmc_fan_thresholds ()
{
	local fan_id		# fan header ID to process
	local fan_info		# single line of text from IPMI sensor output

	# backup original fan threshold arrays
	local -A fan_speed_lnr_backup
	local -A fan_speed_lcr_backup
	local -A fan_speed_lnc_backup
	local -A fan_speed_unc_backup
	local -A fan_speed_ucr_backup
	local -A fan_speed_unr_backup

	local -a fan_array

	debug_print 2 "Validate BMC fan speed thresholds"

	convert_binary_to_array "${fan_header_active_binary[master]}" "fan_array"

	for fan_id in "${!fan_array[@]}"; do # 1/
		fan_speed_lnr_backup["$fan_id"]=${fan_speed_lnr["$fan_id"]}
		fan_speed_lcr_backup["$fan_id"]=${fan_speed_lcr["$fan_id"]}
		fan_speed_lnc_backup["$fan_id"]=${fan_speed_lnc["$fan_id"]}
		fan_speed_unc_backup["$fan_id"]=${fan_speed_unc["$fan_id"]}
		fan_speed_ucr_backup["$fan_id"]=${fan_speed_ucr["$fan_id"]}
		fan_speed_unr_backup["$fan_id"]=${fan_speed_unr["$fan_id"]}
	done # 1/

	# reload thresholds (updates the main arrays)
	load_bmc_fan_thresholds

	##
	# Warn if current BMC threshold values differ from what they were when the Builder was run.
	##

	for fan_id in "${!fan_speed_lnr_backup[@]}"; do # 1/
	    [ "${fan_speed_lnr_backup["$fan_id"]}" != "${fan_speed_lnr["$fan_id"]}" ] && debug_print 4 "LNR for fan $fan_id changed: ${fan_speed_lnr_backup["$fan_id"]} → ${fan_speed_lnr["$fan_id"]}"
	    [ "${fan_speed_lcr_backup["$fan_id"]}" != "${fan_speed_lcr["$fan_id"]}" ] && debug_print 4 "LCR for fan $fan_id changed: ${fan_speed_lcr_backup["$fan_id"]} → ${fan_speed_lcr["$fan_id"]}"
	    [ "${fan_speed_lnc_backup["$fan_id"]}" != "${fan_speed_lnc["$fan_id"]}" ] && debug_print 4 "LNC for fan $fan_id changed: ${fan_speed_lnc_backup["$fan_id"]} → ${fan_speed_lnc["$fan_id"]}"
	    [ "${fan_speed_unc_backup["$fan_id"]}" != "${fan_speed_unc["$fan_id"]}" ] && debug_print 4 "UNC for fan $fan_id changed: ${fan_speed_unc_backup["$fan_id"]} → ${fan_speed_unc["$fan_id"]}"
	    [ "${fan_speed_ucr_backup["$fan_id"]}" != "${fan_speed_ucr["$fan_id"]}" ] && debug_print 4 "UCR for fan $fan_id changed: ${fan_speed_ucr_backup["$fan_id"]} → ${fan_speed_ucr["$fan_id"]}"
	    [ "${fan_speed_unr_backup["$fan_id"]}" != "${fan_speed_unr["$fan_id"]}" ] && debug_print 4 "UNR for fan $fan_id changed: ${fan_speed_unr_backup["$fan_id"]} → ${fan_speed_unr["$fan_id"]}"
	done # 1/
}
