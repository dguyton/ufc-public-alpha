##
# Assign BMC command schema version ($bmc_command_schema) when not already
# assigned.
#
# Schema may have been previously assigned via config file settings. When
# this is not the case, attempt to determine what it should be.
#
# The schema reference value is derived from examining the motherboard
# manufacturer and motherboard model. It may also be declared explicitly
# via config (.conf) files corresponding to motherboard manufacturer and/or
# model. When the schema is not explicitly declared in a relevant config
# file, this subroutine attempts to determine which BMC schema is
# applicable, if any.
#
# Some manufacturers - such as Dell - can be derived from various metadata
# when the schema version is not pre-defined.
#
# Some manufacturers are known to be incompatible and will be forced to an
# invalid/incompatible state.
##

# post .config and .zone import, follow-on clean-up
function validate_bmc_command_schema ()
{
	##
	# If BMC command schema is declared explicitly in config file,
	# always presume it is valid.
	##

	[ -n "$bmc_command_schema" ] && return

	# otherwise, continue with process of estimating correct BMC schema
	case "$mobo_manufacturer" in # 1/
		dell)
			##
			# Dell boards need to be vetted based on iDRAC version, when known.
			# When iDRAC version is unknown or invalid, the motherboard is considered incompatible.
			##

			local known_version

			local -a known_versions
			local -a min_version
			local -a max_version

			# iDRAC 6
			min_version[6]="1.00"
			max_version[6]="1.99" # Modular iDRAC 6 versions (2.00+) are not supported

			# iDRAC 7
			min_version[7]="1.00.00.00"
			max_version[7]="2.65.65"

			# iDRAC 8
			min_version[8]="2.00.00.00"
			max_version[8]="2.86.86.86"

			# iDRAC 9
			min_version[9]="2.00.00.00"
			max_version[9]="9.99.99.99"

			if [ "$idrac_generation" -lt 6 ]; then # 1/
				debug_print 2 warn "Dell iDRAC generations prior to Gen 6 do not allow IPMI manual fan control"
				return
			fi # 1/

			if [ "$idrac_generation" -gt 9 ]; then # 1/
				debug_print 2 warn "Dell iDRAC generations after Gen 9 do not allow IPMI manual fan control"
				return
			fi # 1/

			# iDRAC version less than known minimum
			if [ "$(printf '%s\n%s\n' "$idrac_version" "${min_version[$idrac_generation]}" | sort -V | head -n1)" = "$idrac_version" ]; then # 1/ version less than min version
				debug_print 4 warn "iDRAC $idrac_generation version $idrac_version is invalid: less than minimum possible version (${min_version[$idrac_generation]})"
				unset idrac_version
				return
			fi # 1/

			# iDRAC version greater than known maximum
			if [ "$(printf '%s\n%s\n' "$idrac_version" "${max_version[$idrac_generation]}" | sort -V | head -n1)" != "$idrac_version" ]; then # 1/ version greater than max version
				debug_print 4 warn "iDRAC $idrac_generation version $idrac_version is invalid: greater than maximum possible version (${max_version[$idrac_generation]})"
				unset idrac_version
				return
			fi # 1/

			# filter compatibility based on iDRAC generation
			case "$idrac_generation" in # 2/

				6)
					##
					# min_version="1.00"
					# max_version="1.99"
					# good = "1.40" "1.41" "1.90"
					# no = all others
					##

					known_versions=("1.00" "1.30" "1.40" "1.41" "1.85" "1.90")

					# known compatible iDRAC versions
					for known_version in "${known_versions[@]}"; do # 1/
						if [ "$version" = "$known_version" ]; then # 1/ version is explicitly valid
							bmc_command_schema="dell-v1"
							return
						fi # 1/
					done # 1/

					# disqualify any other iDRAC version as incompatible
					debug_print 2 warn "iDRAC $idrac_generation version $idrac_version is NOT compatible with IPMI manual fan speed control"
				;;

				7)
					##
					# 1.0.0 = min
					# 2.65.65 = max
					# 1.57.57 = confirmed ok
					# < 1.60.60 = presumed ok
					# everything else = no
					##

					# known compatible iDRAC versions
					if [ "$(printf '%s\n1.60.60\n' "$idrac_version" | sort -V | head -n1)" = "$idrac_version" ]; then # 1/ versions prior to 1.60.60 are supported
						bmc_command_schema="dell-v1"
					else # 1/ any other result not likely to work well
						debug_print 2 warn "iDRAC $idrac_generation version $idrac_version is NOT compatible with IPMI manual fan speed control"
					fi # 1/
				;;

				8)
					##
					# 2.0.0.0 = lowest possible value
					# 2.86.86.86 = highest possible value
					# < 2.40.40.40 = ok
					# 2.40.40.40 - 2.52.52.52 = no
					# 2.60.60.60 - 2.70.70.70 = maybe (unknown)
					# > 2.70.70.70 = no
					##

					# iDRAC version < 2.40.40.40 good
					if [ "$(printf '%s\n2.40.40.40\n' "$idrac_version" | sort -V | head -n1)" = "$idrac_version" ]; then # 1/ iDRAC < 2.40.40.40
						debug_print 2 warn "iDRAC $idrac_generation version $idrac_version is compatible with IPMI manual fan speed control"
						bmc_command_schema="dell-v1"
						return
					fi # 1/

					# iDRAC version > 2.52.52.52 and < 2.75.75.75 may work, but will not be attempted
					if [ "$(printf '%s\n2.52.52.52\n' "$idrac_version" | sort -V | head -n1)" != "$idrac_version" ] && [ "$(printf '%s\n2.75.75.75\n' "$idrac_version" | sort -V | head -n1)" = "$idrac_version" ]; then # 1/
						debug_print 2 warn "iDRAC $idrac_generation version $idrac_version IPMI manual fan speed control compatibility is UNKNOWN"
						debug_print 3 bold "To force useage, create a config (.conf) file in the Dell configuration sub-directory"
					else # 1/ any other result means version incompatible
						debug_print 2 warn "iDRAC $idrac_generation version $idrac_version is NOT compatible with IPMI manual fan speed control"
					fi # 1/
				;;

				9)
					##
					# 2.0.0.0 = lowest possible value
					# ? = highest possible value (still in active development)
					# < 2.10.10.10 = no
					# 2.10.10.10 - 3.32.32.32 = ok
					# > 3.32.32.32 = no
					##

					# compatible version numbers must be in range 2.10.10.10 (> 2.02.00.00) to 3.32.32.32 (< 3.34.34.34)
					if [ "$(printf '%s\n2.02.02.02\n' "$idrac_version" | sort -V | head -n1)" != "$idrac_version" ] || [ "$(printf '%s\n3.34.34.34\n' "$idrac_version" | sort -V | head -n1)" = "$idrac_version" ]; then # 1/ iDRAC versions > 2.02.02.02 and < 3.34.34.34 are good
						bmc_command_schema="dell-v1"
					else # 1/ iDRAC version < 2.10.10.10 or > 3.32.32.32 are incompatible
						debug_print 2 warn "iDRAC $idrac_generation version $idrac_version is NOT compatible with IPMI manual fan speed control"
					fi # 1/
				;;
			esac # 2/
		;;

		ibm|lenovo)
			if [ "${mobo_model:0:1}" = "X" ]; then # 1/ IBM System x series
				mobo_gen="${mobo_model##* }" # Yz such as "M5"
				mobo_model="${mobo_model%% *}" # Xnnnn such as "x3450"

				case "$mobo_model" in # 2/
					x3100|x3105|x3200|x3250|x3300|x3350|x3400|x3450|x3455|x3500|x3530|x3550|x3620|x3630|x3650|x3650T|x3655|x3690|x3750|x3755|x3800|x3850|x3950)
						[ "$mobo_manufacturer_first_name" = "ibm" ] && debug_print 2 critical "Supported IBM Systems X-series servers are considered experimental at this time"
						[ "$mobo_manufacturer_first_name" = "lenovo" ] && debug_print 2 critical "Supported Lenovo X-series servers are considered experimental at this time"
					;;

					*)
						[ "$mobo_manufacturer_first_name" = "ibm" ] && debug_print 2 critical "IBM Systems X-series model $mobo_model is NOT supported at this time"
						[ "$mobo_manufacturer_first_name" = "lenovo" ] && debug_print 2 critical "Lenovo X-series model $mobo_model is NOT supported at this time"
					;;
				esac # 2/
			else # 1/
				bail_noop "Non-X class IBM motherboards are NOT supported at this time"
			fi # 1/
		;;

		inspur)
			bail_noop "IEI (Inspur) motherboards are NOT supported at this time"
		;;

		h3c|new)
			bail_noop "H3C motherboards are NOT supported at this time"
		;;

		sun)
			bail_noop "Sun Microsystems motherboards are NOT supported at this time"
		;;

		supermicro)

			# force filtration of known conditions that supercede other factors
			case "$mobo_gen" in # 2/ assign schema when mobo generation is recognized
				X8)
					bail_noop "Supermicro X8 and earlier generation motherboards are NOT supported at this time"
				;;
			esac # 2/

			if [ -n "$bmc_command_schema" ]; then # 1/ stop here when BMC command schema already known
				debug_print 3 "BMC command schema declared via config file; skipping automated filter"
				return
			fi # 1/

			case "$mobo_gen" in # 2/ assign schema when mobo generation is recognized
				X9)
					[ -z "$zone_model_file" ] && debug_print 2 caution "Most (but not all) Supermicro X9 motherboards are supported" # no model specific zone file available
					bmc_command_schema="supermicro-v1"
				;;

				X10)
					debug_print 2 "Most Supermicro $mobo_gen motherboards are supported"
					bmc_command_schema="supermicro-v2"
				;;

				X11)
					debug_print 2 "Most Supermicro X11 motherboards are supported"

					##
					# There is conflicting information on whether FULL or OPTIMAL
					# fan mode is required as pre-cursor for IPMI manual fan
					# control. Therefore, X11 boards are currently reserved here
					# in case this value needs to be adjusted in the future.
					#
					# For now, X11/H11 boards are treated as X10 boards, meaning
					# they are presumed to require FULL fan mode as a pre-requisite.
					# This shall remain their incumbent behavior here and in other
					# subroutines until proven otherwise.
					##

					bmc_command_schema="supermicro-v2"
				;;

				X12)
					debug_print 2 "Most Supermicro $mobo_gen motherboards are supported"
					bmc_command_schema="supermicro-v3"
				;;

				X13|X14)
					debug_print 2 critical "Supermicro X13 and later motherboards are considered experimental at this time"
					bmc_command_schema="supermicro-v2"
				;;

				H11)
					debug_print 2 warn "Supermicro H11 boards generally follow X11 board behavior, and will be treated as such"
					bmc_command_schema="supermicro-v2"
				;;

				H12)
					debug_print 2 warn "Supermicro H12 boards generally follow X12 board behavior, and will be treated as such"
					bmc_command_schema="supermicro-v3"
				;;

				H13|H14)
					debug_print 2 critical "Supermicro H13 and H14 follow X13/X14 board behavior, and are considered experimental"
					bmc_command_schema="supermicro-v2"
				;;

				B|C)
					debug_print 2 critical "Supermicro B-series and C-series boards are NOT supported at this time"
					unset bmc_command_schema
				;;

				M11|M12)
					debug_print 2 warn "Supermicro ${mobo_gen} board support is experimental at this time, and will be treated as X11 boards"
					bmc_command_schema="supermicro-v2" # same as H11/X11 protocol
				;;

				*)
					debug_print 2 warn "Default BMC schema version could not be determined programatically"
					debug_print 4 "Consider creating or modifying a custom config file (.conf)"
				;;
			esac # 2/
		;;
	esac # 1/
}
