##
# Evaluate fan headers flagged as suspicious.
#
# A fan header is flagged as 'suspicious' when it is deemed to be
# potentially failing due to a non-nominal status report (fan is
# reported as inactive, no signal, or speed is out of range).
#
# Fan headers may be tagged as suspicious by either of two (2)
# fan validation subroutines:
#	--> active_fan_sweep
#	--> validate_fan_duty_cycle
#
# These functions examine and evaluate the fan headers using
# different logic. Either may flag a fan headers as suspicious.
#
# SUspicious fan headers are monitored. If a fan header trips
# a suspicous flag condition for two (2) consecutive scanning
# cycles, the fan header is flagged for follow-up via this
# subroutine. A specific timer controls when the fan validation
# process (this subroutine) is triggered, which allows for the
# possibility that the suspicious fan validation critera may be
# reset prior to this subroutine being called. These processes
# ensure fan headers are not scrutinized too frequently, given
# the possibility a single reading out of bounds may be a data
# processing error, which could quickly correct itself.
#
# The active fan sweeper function (active_fan_sweep) identifies
# anomalous fan conditions, where the expected fan header state
# does not match the observed fan header state. all fan headers
# are polled and evaluated, including inactive fan headers.
#
# Fan header states are quantified, meaning the raw fan state is
# distilled down to a high-level categorization.
#
# The fan duty cycle validator function (validate_fan_duty_cycle)
# on the other hand, polls each fan header and looks for fans
# reporting operational characteristics outside the bounds of
# expected ranges (e.g. fan speed).
#
# The fan duty cycle validator operates at the fan group level,
# and only examines active fan headers belonging to the target
# fan group (or fan type, e.g. CPU cooling fans).
# 
# This subroutine is responsible for validating the fan status
# anomalies reported by the two aforementioned subroutines.
# It takes into consideration the range of possible anomalies
# which could be reported by either of the other functions.
##

##
# This subroutine may disable active fan headers deemed to be
# acting outside of normal parameters. It will not, if [ -n "$log_filename" ]
# do the opposite (active fan headers marked inactive.
#
# When a fan is failed, the active fan inventory is refreshed,
# and fan zones are also refreshed when zoned fan control is
# utilized. Note this can result in a previously populated fan
# zone being disabled and removed from service, which may in
# turn lead to other consequences.
##

function validate_suspicious_fans ()
{
	local active_fan_list_changed				# only care about changes to active fan headers
	local fan_category						# fan type being evaluated
	local fan_id							# current fan id under evaluation
	local index
	local message							# body of the email message
	local ok_to_send_email					# avoid sending duplicate email notifications to user for same fan header

	##
	# $fan_id is always numeric, but use an associative array just in case
	# in the future there is a desire to modify how Fan IDs are handled.
	##

	local -a need_to_send_suspicious_fan_email

	if [ "${#suspicious_fan_list[@]}" -eq 0 ]; then # 1/ no suspicious fans to evaluate
		unset suspicious_fan_timer
		return 0
	fi # 1/

	##
	# When circumstances have triggered CPU panic mode, searching for
	# suspiciously behaving fans becomes a non-priority. When this
	# occurs, cancel any existing list of potentially suspicious fans
	# and abort the remainder of this subroutine.
	##

	if [ "$device_fan_override" = true ]; then # 1/
		debug_print 4 caution "Reset suspicious fan trackers because CPU panic mode is active"
		unset suspicious_fan_list
		return 0
	fi # 1/

	debug_print 2 caution "Analyzing active fans flagged as suspicious (unreadable or inconsistent fan states)"

	# analyze all fan headers and flag suspicious fans
	active_fan_sweep

	##
	# Fans may be marked as 'suspicious' by the following subroutines:
	#	- active_fan_sweep
	#
	# When a fan header has been flagged twice during two (2) consecutive suspicious
	# fan scans, it gets evaluated here to determine its disposition.
	##

	##
	# Only examine fan headers with two (2) suspicious fan flags for the same fan header id.
	# A minimum of two (2) consecutive suspicious fan strikes are required to force fan header
	# state analysis of an active fan header. This prevents knee-jerk reactions to potentially
	# temporary abnormal reported fan conditions from disqualifying an active fan that could be
	# perfectly fine.
	#
	# When there is only one suspicious flag signal for a given fan header,
	# store the suspicious value as previous value, reset current value,
	# and wait to see if a subsequent, consecutive suspicious flag occurs.
	#
	# When the current suspicious flag is the second consecutive suspicious
	# flag for the same fan header, evaluate the two suspicious fan readings
	# and make a determination of the appropriate disposition of the fan header.
	##

	# compute outcome after two (2) consecutive suspicious readings for the same fan header
	for fan_id in "${!suspicious_fan_list[@]}"; do # 1/ evaluate recently tagged suspicious fan headers

		[ -z "${suspicious_fan_list_old[$fan_id]}" ] && continue # need 2 consecutive alerts before taking further action

		fan_name="$fan_name"
		fan_category="${fan_header_category[$fan_id]}"
<<>>
zone_id="${fan_header_zone[$fan_id]}"

		debug_print 3 caution "1st alert: suspicious fan header '$fan_name' state: ${suspicious_fan_list_old[$fan_id]}"
		debug_print 3 caution "2nd alert: suspicious fan header '$fan_name' state: ${suspicious_fan_list[$fan_id]}"

		# pad existing, pending email message
		[ -n "$message" ] && message+="\n---------------------------------------------------------------------------------\n\n"

		case "${suspicious_fan_list[$fan_id]}" in # 1/ evaluate flag associated with given fan id

			##
			# When active fans exhibit signs of inactivity or failing, this is
			# a likely indicator the fan in question has failed or is in the
			# process of failing.
			#
			# Fans meeting this criteria need to be disqualified from the fan
			# pool.
			#
			# Under rare circumstances, a fan marked as inactive may be flagged
			# as suspicious when it begins to show signs of activity.
			##

			bad|inactive) # flagged by get_fan_info subroutine when odd fan behavior is observed
				case "${suspicious_fan_list_old[$fan_id]}" in # 2/ compare previous suspicious fan state if it exists
					bad|unknown|inactive|error) # retain 'bad' suspicious fan flag

<<>>

--> what are we trying to figure out here?
--> is this active fan that might have stopped working or inactive / excluded fan that might have started working?

if query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "master"; then # 1/

							set_ordinal_in_binary "off" "$fan_id" "fan_header_active_binary" "master" # remove fan header from list of active fan headers
							set_ordinal_in_binary "off" "$fan_id" "fan_header_active_binary" "$fan_category"

							debug_print 4 warn "'${fan_category}' duty type fan '$fan_name' removed from active fan pool"
							debug_print 1 warn "Fan header '$fan_name' state appears to be '${suspicious_fan_list[$fan_id]^^}' and has been removed from active fan roster"

							message+="Removed fan header '$fan_name' from active fan roster due to suspicious state '${suspicious_fan_list[$fan_id]^^}'.\n"
							active_fan_list_changed=true # list of active fans has been modified and various environmental factors need to be re-evaluated
						else # 1/ fan was not active to begin with
							debug_print 4 caution "Fan '$fan_name' marked suspicious, but not currently active"
						fi # 1/

						fan_header_status[fan_id]="inactive" # update current fan state in master fan list array
					;;

					*)
						debug_print 4 warn "Follow-up suspicious fan analysis indicates fan or fan header '$fan_name' is likely faulty"
					;;
				esac # 2/

				message+="Fan $fan_id appears to have failed or otherwise become inactive.\n"
			;;

			unknown) # typically flagged by get_fan_info subroutine when undetermined fan behavior is observed
				case "${suspicious_fan_list_old[$fan_id]}" in # 2/
					bad|unknown|error|inactive)
						suspicious_fan_list[$fan_id]="bad" # avoid a possible scenario of infinite 'unknown' fan state messages
						debug_print 4 warn "Follow-up suspicious fan analysis indicates fan or fan header '$fan_name' is likely failing"
					;;

					*)
						debug_print 4 caution "Suspicious fan analysis cannot determine the state of fan header '$fan_name'"
					;;
				esac # 2/

				message+="Fan $fan_id is exhibiting suspicious behavior, and its current state cannot be determined.\n"
			;;

			error|limit) # reported fan speed exceeds maximum physical limit of the fan or is otherwise reporting a non-sensical value
				case "${suspicious_fan_list_old[$fan_id]}" in # 2/
					error|limit|bad)
						suspicious_fan_list[$fan_id]="bad"
						debug_print 4 warn "Follow-up suspicious fan analysis indicates fan or fan header '$fan_name' may be failing"
					;;

					unknown|inactive)
						suspicious_fan_list[$fan_id]="inactive"
						debug_print 4 warn "Follow-up suspicious fan analysis indicates fan or fan header '$fan_name' may be failing"
					;;
				esac # 2/

				[ "${suspicious_fan_list[$fan_id]}" = "limit" ] && message+="Reported fan '$fan_name' speed is non-sensical.\n"
				[ "${suspicious_fan_list[$fan_id]}" = "error" ] && message+="Fan '$fan_name' reported fan speed exceeds physical limits of the fan.\n"
			;;

			under) # fan speed is slower than minimum allowed RPM based on min allowed duty cycle
				case "${suspicious_fan_list_old[$fan_id]}" in # 2/
					low)
						debug_print 4 warn "Fan '$fan_name' speed is slow and getting slower"
					;;

					under)
						debug_print 4 warn "Fan '$fan_name' is consistently under-speed"
					;;

					bad|unknown)
						debug_print 4 warn "Fan '$fan_name' speed slower than minimum RPM (per minimum duty cycle) and may be failing"
					;;
				esac # 2/

				message+="Fan $fan_id is performing slower than expected given current duty cycle.\n"
			;;

			low) # fan is slower than expected given current duty cycle
				case "${suspicious_fan_list_old[$fan_id]}" in # 2/
					low)
						debug_print 4 warn "Fan '$fan_name' speed consistently running slow"
					;;

					under)
						debug_print 4 warn "Fan '$fan_name' speed consistently running slow, but has improved"
					;;

					bad|unknown)
						debug_print 4 warn "Fan '$fan_name' has been operating below specified duty cycle parameters, and may be failing"
					;;
				esac # 2/

				message+="Fan '$fan_name' is performing slower than expected given current duty cycle.\n"
			;;

			over) # fan is over-speed of maximum allowed RPM based on max allowed duty cycle
				case "${suspicious_fan_list_old[$fan_id]}" in # 2/
					high)
						debug_print 4 warn "Fan '$fan_name' speed consistently running high"
					;;

					over)
						debug_print 4 warn "Fan '$fan_name' speed consistently running over-speed"
					;;

					bad|unknown|error)
						debug_print 4 warn "Fan '$fan_name' speed faster than maximum RPM (per maximum duty cycle) and may be failing"
					;;
				esac # 2/

				message+="Fan '$fan_name' is over-speed of maximum allowed RPM based on max allowed duty cycle.\n"
			;;

			high) # fan is faster than expected given current duty cycle
				case "${suspicious_fan_list_old[$fan_id]}" in # 2/
					high)
						debug_print 4 warn "Fan '$fan_name' speed consistently running high"
					;;

					over)
						debug_print 4 warn "Fan '$fan_name' speed is running high and trending higher"
					;;

					bad|unknown|error)
						debug_print 4 warn "Fan '$fan_name' operating above specified duty cycle parameters and may be failing"
					;;
				esac # 2/

				message+="Fan '$fan_name' is performing faster than expected given current duty cycle.\n"
			;;

			panic) # BMC fan speed thresholds exceeded and BMC fan panic mode has been tripped
				case "${suspicious_fan_list_old[$fan_id]}" in # 2/
					error|limit)
						debug_print 4 caution "Fan '$fan_name' reported in panic mode by BMC, but there may be a problem with the fan or fan header"
					;;

					panic)
						debug_print 4 warn "Fan '$fan_name' still reported in panic mode by BMC" # not a faulty fan state; warn, but otherwise do nothing
					;;
				esac # 2/

				message+="Fan $fan_id appears to be in panic mode, meaning its fan speed exceeds lower or upper BMC fan speed limits.\n"
			;;

			# fans marked as non-active showing signs of activity (edge case)
			active|ok) # inactive fan headers suddenly reporting activity are suspicious
				debug_print 3 caution "Validating suspicious fan '$fan_name' ( fan ID $fan_id ) showing signs of activity, though it is marked inactive"

				if ! query_ordinal_in_binary "$fan_id" "fan_header_active_binary" "master"; then # 1/ fan header not currently marked active
					if ! query_ordinal_in_binary "$fan_id" "fan_header_binary" "exclude"; then # 2/ not currently excluded

						unset fan_category # reset filter in case it was set during previous loop

<<>>

--> is fan_category ever set equal to anything???


						# iterate thru each possible fan duty category (sets $fan_category)
						for index in "${fan_duty_category[@]}"; do # 2/
							local -n index_fan_header_binary="${index}_fan_header_binary"
							query_ordinal_in_binary "$fan_id" "fan_header_binary" "$index" && fan_category="$index"
						done # 2/

						if [ -z "$fan_category" ]; then # 3/ exclude fan headers with no known matching fan category type
							set_ordinal_in_binary "on" "$fan_id" "exclude_fan_header_binary"
							debug_print 3 warn "Fan header '$fan_name' ( fan ID $fan_id ) has an un-recognized duty type and must be excluded"
						else # 3/

							##
							# Consider re-activating fan header if it belongs to a known fan zone,
							# and the fan zone is already considered active. However, if the fan
							# zone it belongs to is inactive, then do not re-activate the fan header.
							##

							# fan header known but not active; confirm fan header is OK before weighing activation
							if [ "$fan_control_method" = "zone" ]; then # 4/
								zone_id="${fan_header_zone[$fan_id]}"

								if [ -n "$zone_id" ]; then # 5/ must have a known, associated fan zone id when fan zone control method
									if query_ordinal_in_binary "$zone_id" "fan_zone_binary" "master"; then # 6/ zone id must be valid

										local -n fan_category_fan_zone_binary="${fan_category}_fan_zone_binary"

										if query_ordinal_in_binary "$zone_id" "$fan_category_fan_zone_binary"; then # 7/ confirm fan zone type (cpu or device)
											if query_ordinal_in_binary "$zone_id" "fan_zone_active_binary" "$fan_category"; then # 8/ zone already active
												debug_print 3 "Fan header '$fan_name' ( fan ID $fan_id ) belongs to existing active fan zone ID $zone_id"
												set_ordinal_in_binary "on" "$fan_id" "fan_header_active_binary" "master"
												set_ordinal_in_binary "on" "$fan_id" "fan_header_active_binary" "$fan_category"

												message+="Added fan header '$fan_name' to active fan roster.\n"
												active_fan_list_changed=true # prompt to re-evaluate fan zones after completing all suspicious fan analysis
											else # 8/ ignore fan because its zone is marked inactive
												debug_print 3 warn "Fan header '$fan_name' ( fan ID $fan_id ) belongs to existing, but inactive fan zone ID $zone_id"
												debug_print 3 warn "Fan header will be ignored, because its fan zone is inactive"
												debug_print 4 "Run Builder to re-inventory fan headers and zones"
												set_ordinal_in_binary "on" "$fan_id" "fan_header_binary" "exclude"
												set_ordinal_in_binary "off" "$fan_id" "fan_header_active_binary" "$fan_category"
											fi # 8/
										else # 7/ unknown fan zone type - cannot continue
											set_ordinal_in_binary "on" "$fan_id" "fan_header_binary" "exclude"
											debug_print 3 warn "Fan header '$fan_name' ( fan ID $fan_id ) indicated fan zone ( ID $zone_id ) type does not exist"
											debug_print 4 warn "Excluded fan header '$fan_name' ( fan ID $fan_id ) from further monitoring"
										fi # 7/
									fi # 6/
								fi # 5/
							else # 4/ fan control type not zoned
								debug_print 4 "Fan header '$fan_name' ( fan ID $fan_id ) cooling duty type $fan_category"
								debug_print 3 "Mark fan header '$fan_name' ( fan ID $fan_id ) as active"
								set_ordinal_in_binary "on" "$fan_id" "fan_header_active_binary" "master"
								set_ordinal_in_binary "on" "$fan_id" "fan_header_active_binary" "$fan_category"
								message+="Added fan header '$fan_name' to active fan roster.\n"
								active_fan_list_changed=true # prompt to re-evaluate fan zones after completing all suspicious fan analysis
							fi # 4/
						fi # 3/
					fi # 2/
				fi # 1/
			;;

			*) # should never happen, but trap any odd suspicious flag values
				debug_print 2 warn "Cannot determine the state or circumstances of fan '$fan_name'"
				debug_print 4 caution "Flagging fan header state as \"unknown\""
				message+="Fan '$fan_name' status is indeterminate or inconclusive, and may be problematic.\n"
			;;
		esac # 1/

		# provide additional contextual information via email for certain conditions
		case "${suspicious_fan_list[$fan_id]}" in

			bad)
				message+="Check fan header $fan_id. Reported speed is impossible (exceeds all known fan speed limits).\n"
				message+="Possible cause 1: 3-pin fan. 3-pin fans tend to confuse IPMI and are not supported by this program.\n"
				message+="Possible cause 2: fan and/or fan header are bad.\n"
				message+="Possible cause 3: temporary IPMI reporting anomaly.\n"
				message+="Fan $fan_id speed ( ${fan_speed[$fan_id]} RPM ) exceeds the physical fan speed limitation of this fan ( ${fan_speed_limit_max[$fan_id]} RPM ).\n"
				message+="Check fan ID $fan_id fan and fan header hardware.\n"
				message+="Potential causes: 1) 3-pin header fan; 2) wiring/plug problem; 3) fan failure; 4) bad fan header; 5) anomaly\n"
			;;

			error)
				message+="Check fan header $fan_id. Reported speed is impossible (exceeds all known fan speed limits).\n"
				message+="Possible cause 1: 3-pin fan. 3-pin fans tend to confuse IPMI and are not supported by this program.\n"
				message+="Possible cause 2: fan and/or fan header are bad.\n"
				message+="Possible cause 3: temporary IPMI reporting anomaly."
			;;

			limit)
				message+="Fan $fan_id speed ( ${fan_speed[$fan_id]} RPM ) exceeds maximum duty cycle threshold ( ${fan_speed_duty_max[$fan_id]} ) significantly.\n"
				message+="Fan $fan_id speed ( ${fan_speed[$fan_id]} RPM ) exceeds the physical fan speed limitation of this fan ( ${fan_speed_limit_max[$fan_id]} RPM )\n"
				message+="Check fan ID $fan_id fan and fan header hardware\n"
				message+="Potential causes: 1) 3-pin header fan; 2) wiring/plug problem; 3) fan failure; 4) bad fan header; 5) anomaly\n"
			;;

			over)
				message+="Fan $fan_id speed ( ${fan_speed[$fan_id]} RPM ) is significantly above its upper limit ( ${fan_speed_duty_max[$fan_id]} RPM ).\n"
				message+="Fan $fan_id speed ( ${fan_speed[$fan_id]} RPM ) exceeds maximum duty cycle threshold ( ${fan_speed[$fan_id]} RPM ).\n"
				message+="Fan $fan_id speed is excessively over-speed ( ${fan_speed[$fan_id]} RPM ) and should be checked."
				message+="Is this a 3-pin fan? (incompatible). If not, fan and/or fan header are bad."
			;;

			under)
				message+="Fan $fan_id speed ( ${fan_speed[$fan_id]} RPM ) below minimum threshold ( ${fan_speed_limit_min[$fan_id]} RPM ).\n"
			;;

			high)
				message+="Fan $fan_id speed ( ${fan_speed[$fan_id]} RPM ) is higher than its upper limit ( ${fan_speed_duty_max[$fan_id]} RPM ).\n"
				message+="Fan $fan_id speed is excessively over-speed ( ${fan_speed[$fan_id]} RPM ) and should be checked.\n"
				message+="Is this a 3-pin fan? (incompatible). If not, fan and/or fan header may be bad.\n"
			;;

			low)
				message+="Fan $fan_id speed ( ${fan_speed[$fan_id]} RPM ) fan speed is below its assigned range.\n"
			;;

			panic)
				message+="Fan $fan_id speed ( ${fan_speed[$fan_id]} RPM ) exceeded Lower CRitical BMC fan threshold (LCR) of ${fan_speed_lcr[$fan_id]} RPM.\n"
			;;
		esac

		# track which fan ids already reported to user
		{ [ -n "$message" ] && [ "${suspicious_fan_email_sent[$fan_id]}" != true ]; } && need_to_send_suspicious_fan_email[$fan_id]=true

		# reset suspicious fan trackers of any processed fan header
		unset "suspicious_fan_list[$fan_id]"
		unset "suspicious_fan_list_old[$fan_id]"

	done # 1/

	##
	# Notify user about suspicious fan headers not previously reported.
	# Keep track of which fan ids we already sent an email about, to
	# avoid spamming user.
	##

	if [ -n "$message" ]; then # 1/
		for fan_id in "${!need_to_send_suspicious_fan_email[@]}"; do # 1/
			if [ "${suspicious_fan_email_sent[$fan_id]}" != true ]; then # 2/ email not previously sent to user about this fan header
				suspicious_fan_email_sent["$fan_id"]=true
				ok_to_send_email=true
			fi # 2/
		done # 1/

		if [ "$ok_to_send_email" = true ]; then # 2/ send it
			send_email_alert "$message" false true # no summary, with verbosity (syslog dump)
		else # 2/
			debug_print 4 caution "Did not send email to user regarding suspicious fan headers because they have been previously reported"
		fi # 2/
	fi # 1/

	##
	# When one or more fans is removed from service, various
	# dependencies must be re-evaluated, and risks must be
	# reconsidered.
	##

	# nothing else to do here when no changes made to active fan list
	[ "$active_fan_list_changed" != true ] && return 0

	# no active fan headers remain
	binary_is_empty "$fan_header_active_binary" && bail_with_fans_optimal "Aborting program because no active fan headers are detected"

	# re-calibrate fan zones
	[ "$fan_control_method" = "zone" ] && calibrate_active_fan_zones

	# validate fan ecosystem is stable and re-calibrate fan duty category assignments of all fan headers
	validate_fan_duty_assignments

	# trigger fan speed change when necessary
	for index in "${fan_duty_category[@]}"; do # 1/
		set_fan_duty_cycle "$index" "${index}_fan_duty"
	done # 1/
}
