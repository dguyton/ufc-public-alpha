##
# Normalize raw fan state.
#
# Examine raw fan header state (input).
# Convert it to a uniform output.
# On request, simplify output further to status of active or inactive.
#
# Most program functions only need to know whether fans are active or inactive,
# though in some cases the raw or partial uniformity of a more detailed fan
# status is useful.
#
# Possible raw fan status meanings (input values):
#	ok = normal | device present
# 	ns = no signal | no reading
# 	na = not availalbe
# 	nc = non-critical
# 	cr = critical
# 	nr = non-recoverable
#
# Possible refined states returned by this subroutine (output):
# --> ok			fan exists and is operating within normal parameters
# --> bad			fan exists, but appears to be malfunctioning
# --> inactive		no fan detected (not attached) to specified fan header
# --> panic		current fan exceeded an upper or lower critical threshold, and has triggered BMC fan panic mode
# --> unknown		an unrecognized fan status was reported by BMC / IPMI tool
#
# inputs: { $2 = raw fan state to be parsed } { $2 = level of detail requested }
##

function parse_fan_state ()
{
	local fan_id
	local -u fan_name
	local -l fan_status		# raw fan state to process
	local simplify_fan_state	# return simplified level of detail when = true (optional field)

	fan_id="$1"
	simplify_fan_state="$2"	# when true return simple result of active or inactive

	if [ -z "$fan_id" ]; then # 1/
		debug_print 2 warn "Cannot parse fan state: fan header ID is missing" true
		return
	fi # 1/

	fan_id="$(printf "%0.f" "$fan_id")"

	if (( fan_id > fan_header_binary_length )); then # 1/
		debug_print 2 warn "Invalid fan header ID reference (exceeds \$fan_header_binary_length): $fan_id" true
		return
	fi # 1/

	if query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude"; then # 1/ fan header is excluded
		debug_print 4 warn "${fan_header_name[$fan_id]} (ID $fan_id) ignored fan state request because fan header is excluded"
		printf "inactive"
		return
	fi # 1/

	fan_name="${fan_header_name[$fan_id]}"
	fan_status="${fan_header_status[$fan_id]//[!a-z]}" # strip non-alpha chars for uniformity (also removes leading and trailing spaces for consistency)

	if [ "$fan_status" = "active" ] || [ "$fan_status" = "inactive" ]; then # 1/
		debug_print 4 "Fan $fan_id state: $fan_status" # echo back current state and return
		return
	fi # 1/

	debug_print 4 "$fan_name (ID $fan_id) raw fan state: $fan_status"

	case "$fan_status" in # 1/
		ok|nominal|normal|devicepresent) # includes 'device present'
			fan_status="ok"
		;;

		ns|absent|noreading) # no signal, no reading
			debug_print 3 warn "NO SIGNAL on fan header $fan_name (ID $fan_id) - is fan disconnected, bad fan, or bad motherboard fan header?"
			fan_status="inactive"
		;;

		na|init) # not available
			debug_print 3 caution "Fan header $fan_name (ID $fan_id) reported as NOT AVAILABLE"
			if [ "$mobo_manufacturer" = "dell" ]; then # 1/
				fan_status="bad"
			else # 1/
				fan_status="inactive"
			fi # 1/
		;;

		nc|lnc|unc) # non-critical alert
			fan_status="ok"
		;;

		cr|nr|lcr|lnr|ucr|unr) # critical or non-recoverable (i.e. BMC is in panic mode)
			fan_status="panic"
		;;

		*) # not recognized or empty (no value)
			[ -z "$fan_status" ] && debug_print 4 warn "No fan state (null)" true
			fan_status="unknown"
		;;
	esac # 1/

	debug_print 4 "$fan_name modified fan state: $fan_status"

	# override most other states when fan speed is known and negative
	if [ "$fan_status" != "unknown" ] && [ "$fan_status" != "inactive" ] && [ "$fan_status" != "bad" ]; then # 1/ fan header not already flagged as problematic
		if [ -z "${fan_header_speed[$fan_id]}" ]; then # 2/ occurs when speed detection was by-passed for some reason
			fan_status="unknown"
			debug_print 4 warn "Data anomaly: fan header $fan_name has no recorded rotational speed reading" true
		else # 2/
			if [ "${fan_header_speed[$fan_id]}" -lt 1 ]; then # 3/ reported fan speed makes no sense
				if [ "${fan_header_speed[$fan_id]}" -eq 0 ]; then # 4/ ok fan state but no fan speed is odd
					debug_print 4 caution "Changing fan header $fan_name (fan ID $fan_id) state to UNKNOWN because its reported speed is 0 RPM"
					fan_status="unknown"
				else # 4/ negative speed normally indicates bad or failing fan
					fan_status="bad"
					debug_print 4 warn "Fan $fan_name may have failed or be failing: invalid fan speed reading (${fan_header_speed[$fan_id]} RPM)"
				fi # 4/
			fi # 3/
		fi # 2/
	fi # 1/

	[ "$fan_status" = "bad" ] && debug_print 3 caution "Fan header $fan_name may be inactive. Is fan connected???"

	if [ "$simplify_fan_state" = true ]; then # 1/ simplified result is requested (else retain more detailed result determined above)
		case "$fan_status" in # 1/
			ok|panic)
				fan_status="active"
			;;

			*)
				fan_status="inactive"
			;;
		esac # 1/
		debug_print 4 "$fan_name simplified fan state: $fan_status"
	fi # 1/

	printf "%s" "$fan_status" # return fan state result
}
