##
# Organize fan headers in write-order.
#
# Required for group fan control method.
#
# Builder program only.
##

##
# This subroutine is required for Direct and Group fan control methods.
# It establishes the correct write fan order, including required special data bytes (e.g. dummy,
# cpu override).
#
# These settings govern the order in which fan header fan duties are sent to the BMC when an IPMI
# fan write command is executed. Ensuring the correct order is applied is crucial to the correct
# operation of the PID fan controller service. When the order is not defined correctly, write
# commands will be sent out of order, leading to unpredictable and potentially undesirable results.
#
# Fan headers are ordered by UFC at the time they are inventoried. This ordering is
# dependent on the IPMI fan read process. UFC has no control over the order.
#
# It is common for the write-order of Direct and Group fan control methods to differ
# from the read-order. This is because the BMC fan controller expects to receive fan
# speed commands either in a specific, pre-defined order (for Group method), or it has
# a hard-coded internal translation table that maps a specific command byte value to a
# specific fan header.
#
# The write table produced by this subroutine is static as it maps physical fan header
# positions on the motherboard. This table will not change regardless of the addition or
# subtraction of fan headers. It is a map to relative position based on physically present
# fan headers (not fans), and therefore whether a fan is plugged into a given fan header
# or not does not affect the table construct.
##

function ipmi_order_fan_header_names ()
{
	debug_print 3 "Calculate IPMI fan header ordered write map"

	case "$fan_control_method" in # 1/

		direct)
			# trap in case program attempts to run this sub more than once
			if [ "${#ipmi_write_position_fan_id[@]}" -gt 0 ]; then # 1/ array already defined
				debug_print caution "Sequential write-ordered fan header array already defined"
				return 0
			fi # 1/
		;;

		group)
			if [ "${#ipmi_write_position_fan_name[@]}" -gt 0 ]; then # 1/
				debug_print caution "Sequential write-ordered fan header array already defined"
				return 0
			fi # 1/
		;;

		*)
			# applicable to direct and group fan control methods only
			debug_print 3 "Skipping... irrelevant fan control method: $fan_control_method"
			return 0
		;;

	esac # 1/

	##
	# Parse all fan headers to determine their fan group and hierarchical position order
	# within their fan group.
	##

	##
	# Configure write position/fan id associations.
	#
	# Creates ipmi_write_position_fan_name[] array so the compile_group_duty_cycle_payload subroutine
	# has a pre-defined write map to work with. This array is a sequentially ordered list of
	# fan ids, aligned to the IPMI write command data payload. In other words, this write map
	# defines the order of fan header positions as the data payload of IPMI raw write commands.
	##

	#################################################
	# Quantify Fan Header Write-Order: Custom Schemas
	#################################################

	##
	# Create write position array based on known schema per motherboard manufacturer/model combination.
	#
	# Map known fan header names ipmi data payload write-order.
	##

	if [ "${#ipmi_fan_write_order[@]}" -eq 0 ]; then # 1/ not pre-defined (declared in a config file)

		# known fan write position mappings by fan control method + motherboard manufacturer + model
		case "$fan_control_method" in # 1/

			##############################
			# Group Method Fan Write Order
			##############################

			group)

				case "$mobo_manufacturer" in # 2/

					asrock)

						case "$bmc_command_schema" in # 3/

							asrock-ast2300-v1)
								# requires 2x command lines with 8-byte payloads
								# part 1: {cpu_1 override} {CPU_FAN1_1} {REAR_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3}
								# part 2: {cpu_2 override} {CPU_FAN2_1} {REAR_FAN2} {FRNT_FAN4} {dummy byte} {dummy byte}

								##
								# This schema requires an uncommon 2-stage process to write fan speeds.
								# Here, the fan headers are treated as a comprehensive 12-byte string to identify fan header IDs.
								# However, the actual write process is unusual in that it requires a 2-stage command structure.
								# This 12-byte fan write order compilation derived here will need to be split into 2x 6-byte
								# strings for the actual write implementation process (handled later).
								##

								# expected fan header names, in correct write order
								ipmi_fan_write_order=( "CPU_OVERRIDE" "CPU_FAN1_1" "REAR_FAN1" "FRNT_FAN1" "FRNT_FAN2" "FRNT_FAN3" "CPU_OVERRIDE" "CPU_FAN2_1" "REAR_FAN2" "FRNT_FAN4" )
								ipmi_payload_byte_count=12 # total data payload byte count, auto-padded with 2 dummy bytes at end (will be split correctly during command execution phase)
							;;

							asrock-ast2300-v2)
								# {CPU_FAN1} {CPU_FAN2} {REAR_FAN1} {REAR_FAN2} {FRNT_FAN1} {FRNT_FAN2} {dummy byte} {dummy byte}
								ipmi_fan_write_order=( "CPU_FAN1" "CPU_FAN2" "REAR_FAN1" "REAR_FAN2" "FRNT_FAN1" "FRNT_FAN2" )
								ipmi_payload_byte_count=8 # +2 dummy bytes at end of string
							;;

							asrock-ast2300-v3)
								# ipmitool raw 0x3a 0x01 {CPU_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {FRNT_FAN4} {FRNT_FAN5}
								ipmi_fan_write_order=( "CPU_FAN1" "FRNT_FAN1" "FRNT_FAN2" "FRNT_FAN3" "FRNT_FAN4" "FRNT_FAN5" )
								ipmi_payload_byte_count=8 # no dummy bytes at end of string
							;;

							asrock-ast2300-v4)
								# ipmitool raw 0x3a 0x01 {CPU_FAN1} {dummy byte} {REAR_FAN1} {dummy byte} {FRNT_FAN1} {dummy byte} {dummy byte} {dummy byte}
								# note: these dummy bytes after fan speeds could possibly be override bytes (i.e. incorrectly tagged atm as dummy bytes)
								ipmi_fan_write_order=( "CPU_FAN1" "DUMMY" "REAR_FAN1" "DUMMY" "FRNT_FAN1" )
								ipmi_payload_byte_count=8 # 3 dummy bytes at end of string
							;;

							asrock-ast2400-v1)
								# ipmitool raw 0x3a 0x01 {CPU1_FAN1} {REAR_FAN1} {FRNT_FAN1} {dummy byte} {dummy byte} {dummy byte} {dummy byte} {dummy byte}
								ipmi_fan_write_order=( "CPU1_FAN1" "REAR_FAN1" "FRNT_FAN1" )
								ipmi_payload_byte_count=8 # 5 dummy bytes at end of string
							;;

							asrock-ast2500-v1)
								# ipmitool raw 0x3a 0x01 {CPU1_FAN1} {CPU2_FAN1} {REAR_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {FRNT_FAN4} {dummy byte}
								ipmi_fan_write_order=( "CPU1_FAN1" "CPU2_FAN1" "REAR_FAN1" "FRNT_FAN1" "FRNT_FAN2" "FRNT_FAN3" "FRNT_FAN4" )
								ipmi_payload_byte_count=8 # 1 trailing dummy byte at end of string
							;;

							asrock-ast2500-v2)
								# ipmitool raw 0x3a 0xd6 {CPU_FAN1} {FRNT_FAN1} {FRNT_FAN2} {13x dummy bytes}
								ipmi_fan_write_order=( "CPU_FAN1" "FRNT_FAN1" "FRNT_FAN2" )
								ipmi_payload_byte_count=16 # 13 dummy bytes at end of string
							;;

							asrock-ast2500-v3|asrock-ast2500-v5)
								# ipmitool raw 0x3a 0xd6 {CPU_FAN1} {SYSTEM_FAN1} {SYSTEM_FAN2} {SYSTEM_FAN3} {SYSTEM_FAN4} {SYSTEM_FAN5} {10x dummy bytes}
								ipmi_fan_write_order=( "CPU_FAN1" "SYSTEM_FAN1" "SYSTEM_FAN2" "SYSTEM_FAN3" "SYSTEM_FAN4" "SYSTEM_FAN5" )
								ipmi_payload_byte_count=16 # 10 dummy bytes at end of string
							;;

							asrock-ast2500-v4)
								# ipmitool raw 0x3a 0x01 {CPU_FAN1} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {REAR_FAN1} {REAR_FAN2} {10x dummy bytes}
								ipmi_fan_write_order=( "CPU_FAN1" "FRNT_FAN1" "FRNT_FAN2" "FRNT_FAN3" "REAR_FAN1" "REAR_FAN2" )
								ipmi_payload_byte_count=16 # 10 dummy bytes at end of string
							;;

							asrock-ast2500-v6)
								# ipmitool raw 0x3a 0xd6 {CPU1_FAN1} {dummy byte} {REAR_FAN1} {REAR_FAN2} {FRNT_FAN1} {FRNT_FAN2} {FRNT_FAN3} {FRNT_FAN4}
								# dummy byte possibly placeholder for CPU2 fan, but boards do not have 2nd CPU (these are single chip EPYC boards)
								ipmi_fan_write_order=( "CPU1_FAN1" "DUMMY" "REAR_FAN1" "REAR_FAN2" "FRNT_FAN1" "FRNT_FAN2" "FRNT_FAN3" "FRNT_FAN4" )
							;;

							asrock-ast2500-v7)
								# ipmitool raw 0x3a 0x01 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {2x dummy bytes}
								ipmi_fan_write_order=( "FAN1" "FAN2" "FAN3" "FAN4" "FAN5" "FAN6" )
								ipmi_payload_byte_count=8 # 2 dummy bytes at end of string
							;;

							asrock-ast2500-v8|asrock-ast2500-v9|asrock-ast2500-v13)
								# ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {10x dummy bytes}
								ipmi_fan_write_order=( "FAN1" "FAN2" "FAN3" "FAN4" "FAN5" "FAN6" )
								ipmi_payload_byte_count=16 # 10 dummy bytes at end of string
							;;

							asrock-ast2500-v10)
								# ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {12x dummy bytes}
								ipmi_fan_write_order=( "FAN1" "FAN2" "FAN3" "FAN4" )
								ipmi_payload_byte_count=16 # 12 dummy bytes at end of string
							;;

							asrock-ast2500-v11)
								# ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {13x dummy bytes}
								ipmi_fan_write_order=( "FAN1" "FAN2" "FAN3" )
								ipmi_payload_byte_count=16 # 13 dummy bytes at end of string
							;;

							asrock-ast2500-v12|asrock-ast2600-v1)
								# ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {FAN7} {9x dummy bytes}
								ipmi_fan_write_order=( "FAN1" "FAN2" "FAN3" "FAN4" "FAN5" "FAN6" "FAN7" )
								ipmi_payload_byte_count=16 # 9 dummy bytes at end of string
							;;

							asrock-ast2500-v14)
								# ipmitool raw 0x3a 0xd6 {FAN1} {FAN2} {FAN3} {FAN4} {FAN5} {FAN6} {FAN7} {FAN8} {8x dummy bytes}
								ipmi_fan_write_order=( "FAN1" "FAN2" "FAN3" "FAN4" "FAN5" "FAN6" "FAN7" "FAN8" )
								ipmi_payload_byte_count=16 # 8 dummy bytes at end of string
							;;

						esac # 3/ end ASRock BMC schemas
					;;

				esac # 2/ end ASRock
			;;

			###############################
			# Direct Method Fan Write Order
			###############################

			##
			# __PLACEHOLDER__ for Direct fan control methods logic.
			#
			# Should there be a need to specify write order position schemas for
			# any Direct fan control methods, insert them here.
			#
			# Generally, this should be unnecessary as the rules below will accomodate
			# typical fan write ordering required by moterboards using the Direct method.
			##

			# direct)
			# ;;

		esac # 1/ end Group fan control method

	fi # 1/ end ipmi_fan_write_order[] array definition

	##
	# Leverage raw mappings to determine full data payload sequence
	# with properly positioned fan IDs and special data bytes.
	##

	if [ "${#ipmi_fan_write_order[@]}" -gt 0 ]; then # 1/ skip when there write order is not yet defined (fall thru to generic schema logic)
		if order_fan_headers_by_write_position; then # 2/ confirm when fan ordering process successful

			# was ipmi data payload order mapped successfully by order_fan_headers_by_write_position subroutine?
			case "$fan_control_method" in # 1/

				direct)
					if [ "${#ipmi_write_position_fan_id[@]}" -gt 0 ]; then # 1/
						debug_print 3 "Successfully mapped and ordered IPMI data payload"
						return 0
					fi # 1/
				;;

				group)
					if [ "${#ipmi_write_position_fan_name[@]}" -gt 0 ]; then # 1/
						debug_print 3 "Successfully mapped and ordered IPMI data payload"
						return 0
					fi # 1/
				;;

			esac # 1/

		fi # 2/
	fi # 1/

	#################################################
	# Quantify Fan Header Write-Order: Generic Schema
	#################################################

	##
	# Order fans using algorithm or generic method when explicit fan map not found above
	##

	##
	# IPMI data payload order not mapped successfully by order_fan_headers_by_write_position subroutine.
	#
	# Force default `position:fan` mapping when solution not found above.
	##

	local -a -u ipmi_fan_order_cha		# sub-group of CHA tagged fan headers
	local -a -u ipmi_fan_order_cpu		# sub-group of CPU tagged fan headers
	local -a -u ipmi_fan_order_fan		# sub-group of FAN tagged fan headers
	local -a -u ipmi_fan_order_front		# sub-group of FRoNT tagged fan headers
	local -a -u ipmi_fan_order_pump		# sub-group of PUMP tagged fan headers
	local -a -u ipmi_fan_order_rear		# sub-group of REAR tagged fan headers
	local -a -u ipmi_fan_order_side		# sub-group of SIDE tagged fan headers
	local -a -u ipmi_fan_order_sys		# sub-group of SYStem tagged fan headers
	local -a -u ipmi_fan_order_other		# placeholder sub-group for other fan header types

	# gather list of existing fan headers by fan id
	convert_binary_to_array "${fan_header_binary[master]}" "fan_array"

	for fan_id in "${!fan_array[@]}"; do # 1/ loop thru all possible fan header IDs

		fan_name="${fan_header_name[$fan_id]}"

		# should never happen but trap condition just in case
		if [ -z "$fan_name" ]; then # 1/ no matching fan header name
			debug_print 4 caution "Skipping fan header ID $fan_id: associated fan name not found"
			continue
		fi # 1/

		##
		# Organize fan headers sequentially and by fan sub-group.
		#
		# Set sequential order of how fan duty speeds should be written via IPMI fan
		# controller write commands, by fan group. Applicable only when fan control
		# method is Group or Direct.
		#
		# Fan sub-arrays are based on prefix of fan header names as read by IPMI during
		# the fan inventory process performed by the Builder program.
		#
		# There are eight (8) default fan groups:
		#	1. CHA
		#	2. CPU
		#	3. SYS
		#	4. FAN
		#	5. REAR
		#	6. FRNT (FRONT)
		#	7. SIDE
		#	8. PUMP
		#
		# The following are the most common:
		#	1. CPU
		#	2. SYS
		#	3. FAN
		##

		# parse fan name prefix to determine which fan group it belongs to and add it to respective fan sub-array
		case "$fan_name" in # 1/

			CHA*) # chassis fans
				ipmi_fan_order_cha+=( "$fan_name" )
			;;

			CPU*) # cpu fans
				ipmi_fan_order_cpu+=( "$fan_name" )
			;;

			FAN*) # generic
				ipmi_fan_order_fan+=( "$fan_name" )
			;;

			FR*) # FRONT or FRNT
				ipmi_fan_order_front+=( "$fan_name" )
			;;

			PUMP*) # radiator pump fans
				ipmi_fan_order_pump+=( "$fan_name" )
			;;

			REAR*) # FRONT or FRNT
				ipmi_fan_order_rear+=( "$fan_name" )
			;;

			SIDE*) # side fans
				ipmi_fan_order_side+=( "$fan_name" )
			;;

			SYS*) # system fans
				ipmi_fan_order_sys+=( "$fan_name" )
			;;

			*) # anything else or indeterminate
				ipmi_fan_order_other+=( "$fan_name" )
				debug_print 2 warn "Fan header $fan_name (ID $fan_id) may not be parsed correctly for IPMI write commands"
				debug_print 3 warn "Fan header $fan_name (ID $fan_id) is part of an unfamiliar or excluded fan group"
			;;
		esac # 1/
	done # 1/

	##
	# Fallback sorting logic for boards with unknown fanwrite-order schema.
	#
	# For each known fan group (e.g., CPU, FAN, SYS, etc.):
	#   1. Sort all fan headers within that group lexicographically by name.
	#      This ensures a predictable and deterministic order, such as FAN1 < FAN2 < FAN10.
	#
	# Then:
	#   2. Append the groups together in a predefined order to build the final
	#      IPMI write-order array. The default order is:
	#      CPU → FAN → SYS → CHA → FRONT → SIDE → REAR → OTHER → PUMP
	#
	# This generic scheme ensures consistent IPMI write-order construction
	# on motherboards where no vendor-specific schema is defined.
	#
	# Assumes fan names follow the format: "cpu1", "sys2", "pch1", etc.
	#
	# - Sorting is by characters starting at the 4th position (e.g., the digit in "cpu1")
	# - Ensures a predictable, stable fan write order within each category
	##

	# re-order fan header sub-arrays lexographically
	readarray -t ipmi_fan_order_cha < <(printf "%s\n" "${ipmi_fan_order_cha[@]}" | sort -t'_' -k1.4,1.4 -k2,2n -k3,3n)
	readarray -t ipmi_fan_order_cpu   < <(printf "%s\n" "${ipmi_fan_order_cpu[@]}"   | sort -t'_' -k1.4,1.4 -k2,2n -k3,3n)
	readarray -t ipmi_fan_order_fan   < <(printf "%s\n" "${ipmi_fan_order_fan[@]}"   | sort -t'_' -k1.4,1.4 -k2,2n -k3,3n)
	readarray -t ipmi_fan_order_front < <(printf "%s\n" "${ipmi_fan_order_front[@]}" | sort -t'_' -k1.4,1.4 -k2,2n -k3,3n)
	readarray -t ipmi_fan_order_pump  < <(printf "%s\n" "${ipmi_fan_order_pump[@]}"  | sort -t'_' -k1.4,1.4 -k2,2n -k3,3n)
	readarray -t ipmi_fan_order_rear  < <(printf "%s\n" "${ipmi_fan_order_rear[@]}"  | sort -t'_' -k1.4,1.4 -k2,2n -k3,3n)
	readarray -t ipmi_fan_order_side  < <(printf "%s\n" "${ipmi_fan_order_side[@]}"  | sort -t'_' -k1.4,1.4 -k2,2n -k3,3n)
	readarray -t ipmi_fan_order_sys   < <(printf "%s\n" "${ipmi_fan_order_sys[@]}"   | sort -t'_' -k1.4,1.4 -k2,2n -k3,3n)
	readarray -t ipmi_fan_order_other < <(printf "%s\n" "${ipmi_fan_order_other[@]}" | sort -t'_' -k1.4,1.4 -k2,2n -k3,3n)

	debug_print 2 caution "No specific model write order schema specified"
	debug_print 2 "Apply $mobo_manufacturer default fan order when known"

	##
	# Check for manuacturer-specific formula.
	# If none, fallback to generic model.
	##

	case "$mobo_manufacturer" in # 1/ compile fan order sequentially

		asrock) # do not edit
			##
			# Default fan group order for ASRock motherboards.
			# Specifies sequential order in IPMI write commands, relative to how the BMC expects
			# to receive fan write commands when more than one fan group type is present.
			##

			# combine sorted sub-arrays into single combined array
			ipmi_fan_write_order=( "${ipmi_fan_order_cpu[@]}" "${ipmi_fan_order_sys[@]}" "${ipmi_fan_order_fan[@]}" "${ipmi_fan_order_rear[@]}" "${ipmi_fan_order_front[@]}" )
		;;

		*) # default order for non-ASRock boards (could be changed)
			debug_print 2 warn "Manufacturer-specific write order template not found; falling back to default order method"

			##
			# Fallback to guessing based on fan suffix numbers/letters.
			# Number suffixes are prioritized before letters.
			##

			# combine sorted arrays into combined array
			ipmi_fan_write_order=( "${ipmi_fan_order_cpu[@]}" "${ipmi_fan_order_fan[@]}" "${ipmi_fan_order_sys[@]}" "${ipmi_fan_order_cha[@]}" "${ipmi_fan_order_front[@]}" "${ipmi_fan_order_side[@]}" "${ipmi_fan_order_rear[@]}" "${ipmi_fan_order_other[@]}" "${ipmi_fan_order_pump[@]}" )
		;;

	esac # 1/

	# populate arrays with fan header names and IDs in sequential write order
	! order_fan_headers_by_write_position && bail_noop "Failed to determine fan header IPMI write order"

	# cannot continue when $ipmi_write_position_fan_name[] array was not built successfully
	case "$fan_control_method" in # 1/

		direct)
			[ "${#ipmi_write_position_fan_id[@]}" -eq 0 ] && bail_noop "Failed to determine IPMI write order by fan header ID"
		;;

		group)
			[ "${#ipmi_write_position_fan_name[@]}" -eq 0 ] && bail_noop "Failed to determine IPMI write order by fan header name"
		;;

	esac # 1/

	return 0
}
