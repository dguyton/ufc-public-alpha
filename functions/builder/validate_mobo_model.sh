# confirm motherboard brand, model, and generation.
function validate_mobo_model ()
{
	local bios_version
	local bios_version_cleaned
	local -u mobo_version
	local mobo_manufacturer_first_name

	debug_print 2 "Auto-detect motherboard manufacturer, series, and model information" false true

	# detect motherboard manufacturer and model using dmi files
	if [ -d "/sys/devices/virtual/dmi/id/)" ] && [ -f "/sys/devices/virtual/dmi/id/board_vendor" ] && [ -f "/sys/devices/virtual/dmi/id/board_name" ]; then # 1/ Ubuntu 16/18/20/22
		mobo_manufacturer="$(cat /sys/devices/virtual/dmi/id/board_vendor)" # Ubuntu 16/18/20/22
		mobo_model="$(cat /sys/devices/virtual/dmi/id/board_name)" # Ubuntu 16/18/20/22
	else # 1/ check using /sys/class/dmi/id
		if [ -d "/sys/class/dmi/id/" ] && [ -f "/sys/class/dmi/id/sys_vendor" ] && [ -f "/sys/class/dmi/id/product_name" ]; then # 2/ Linux
			mobo_manufacturer="$(cat /sys/class/dmi/id/sys_vendor)"
			mobo_model="$(cat /sys/class/dmi/id/product_name)"
		else # 2/ fallback to dmidecode
			if command -v dmidecode &>/dev/null; then # 3/
				mobo_manufacturer=$(sudo dmidecode -s baseboard-manufacturer 2>/dev/null)
				mobo_model=$(sudo dmidecode -s baseboard-product-name 2>/dev/null)
			else # 3/ fallback to lshw
				if command -v lshw &>/dev/null; then # 4/
					mobo_manufacturer=$(sudo lshw -class system 2>/dev/null | grep 'vendor:' | awk '{print $2}')
					mobo_model=$(sudo lshw -class system 2>/dev/null | grep 'product:' | awk '{print $2}')
				else # 4/ fallback to hwinfo
					if command -v hwinfo &>/dev/null; then # 5/
						mobo_manufacturer=$(sudo hwinfo --motherboard 2>/dev/null | grep 'Vendor:' | awk -F ': ' '{print $2}')
						mobo_model=$(sudo hwinfo --motherboard 2>/dev/null | grep 'Model:' | awk -F ': ' '{print $2}')
					else # 5/ fallback to uname
						command -v uname &>/dev/null && mobo_model=$(uname -m)
					fi # 5/
				fi # 4/
			fi # 3/
		fi # 2/
	fi # 1/

	mobo_model="${mobo_model//[/\-+;:_]/}" # remove various symbols

	debug_print 3 "Detected motherboard manufacturer: ${mobo_manufacturer^}" false true
	debug_print 3 "Detected motherboard model: $mobo_model" false true

	##
	# Certain manufacturer names can be tricky to parse correctly
	##

	debug_print 4 "Normalize motherboard manufacturer name"

	mobo_manufacturer_first_name="${mobo_manufacturer%% *}" # first word in manufacturer name

	case "$mobo_manufacturer_first_name" in # 1/

		emc)
			mobo_manufacturer="dell"
		;;

		hewlett|hewlett-packard|hp|hpe)
			mobo_manufacturer="hpe" # Hewlett-Packard Enterprise or Hewlett-Packard
		;;

		international)
			mobo_manufacturer="ibm" # international business machines corporation
		;;

		new)
			mobo_manufacturer="h3c" # New H3C
			debug_print 1 "Motherboard manufacturer name changed to: H3C"
		;;

		super)
			mobo_manufacturer="supermicro" # Super Micro Computer or Supermicro
		;;

		# ASRock | ASRock Rack
		# Asus Global | Asus USA
		# Cisco Systems
		# Dell | Dell Technologies | Dell EMC
		# Fujitsu Global | Fujitsu United States
		# GIGABYTE Global
		# Huawei Technologies Company Limited
		# Hyve Solutions
		# IBM | IBM System | International Business Machines
		# Inspur Group
		# Intel Server or similar anecdotal terms after company name
		# Lenovo | Lenovo System
		# MSI USA | MSI Global
		# NEC | NEC Global | NEC Corporation

		*)
			if [ -n "$mobo_manufacturer" ]; then # 1/
				mobo_manufacturer="$mobo_manufacturer_first_name"
			else # 1/
				debug_print 2 warn "Unknown motherboard manufacturer" false true
			fi # 1/
		;;
	esac # 1/

	##
	# Parse model/series/generation
	##

	case "$mobo_manufacturer" in # 1/

		asrock)
			mobo_version="${mobo_model:7}"
		;;

		dell)
			debug_print 1 "Motherboard manufacturer: Dell Technologies"
			debug_print 1 warn "Dell disabled IPMI raw command support as of their 14th generation servers"
			debug_print 1 warn "Dell iDRAC version 3.34.34.34 and later do not permit raw IPMI commands"
			debug_print 1 warn "Last iDRAC version to allow manual fan speed control is 3.30.30.30"
			debug_print 2 caution "You may wish to research using Dell's iDRAC commands as an alternative (e.g.): > racadm set system.thermalsettings.FanSpeedOffset 0"
			debug_print 2 "Additional information: https://www.dell.com/community/PowerEdge-Hardware-General/Dell-ENG-is-taking-away-fan-speed-control-away-from-users-iDrac/td-p/7441702"

			##
			# Parsing Dell model names is challenging due to the large variety of naming conventions.
			#
			# For example, model R730 is gen 13, model C4140 is gen 14.
			##

			# remove 'EMC' or 'PowerEdge' references from model name before parsing
			mobo_model="${mobo_model//EMC/}"
			mobo_model="${mobo_model//POWEREDGE/}"
			mobo_model="${mobo_model#"${mobo_model%%[![:space:]]*}"}" # remove leading whitespace characters
			mobo_model="${mobo_model%"${mobo_model##*[![:space:]]}"}" # remove trailing whitespace characters

			if (( ${#mobo_version} > 2 )); then # 1/

				# F- and M-models are modular servers, which are not compatible
				{ [ "${mobo_model:0:1}" = "F" ] || [ "${mobo_model:0:1}" = "M" ]; } && bail_noop "Dell PowerEdge server model $mobo_model is a modular server, and its fans cannot be controlled via IPMI"

				if [ "${mobo_model:0:1}" = "C" ]; then # 2/ C-model generation is 1st model digit
					mobo_gen="${mobo_model:1:1}" # 1st digit indicates server generation
				else # 2/ most models use 2nd digit to indicate gen
					mobo_gen="${mobo_model:2:1}" # 2nd digit normally indicates server generation
				fi # 2/
			else # 1/
				bail_noop "Failed to parse Dell PowerEdge server model, and therefore compatibility cannot be confirmed"
			fi # 1/

			##
			# Evaluate server generation
			##

			case "$mobo_gen" in # 2/
				0|1|2|3|4|5)
					mobo_gen="1${mobo_gen}" # pre-pend with digit 1 as generation is actually 10-15
					debug_print 2 "Dell motherboard generation: $mobo_gen"
				;;

				##
				# Some gen 15 servers, and server generations after gen 15
				# do not support manual fan speed control.
				##

				6|7)
					debug_print 1 critical "Dell PowerEdge gen $mobo_gen boards do not allow manual fan control via IPMI"
					unset mobo_gen
				;;

				*)
					unset mobo_gen
					debug_print 2 caution "Dell motherboard generation could not be identified, and may not be compatible"
					debug_print 1 warn "Dell motherboard model is unfamiliar. Program functionality may be erratic"
				;;
			esac # 2/

			# confirm is PowerEdge server
			[ "${mobo_model:0:9}" != "poweredge" ] && bail_noop "Incompatible Dell server model: $mobo_model (not PowerEdge)"

			##
			# Evaluate iDRAC generation
			##

			# detect iDRAC generation and version using BIOS information
			bios_version=$(grep -i -m1 "iDRAC" /sys/class/dmi/id/bios_version 2>/dev/null) # retain only 1st matching line with iDRAC version info

			if [ -n "$bios_version" ]; then # 1/
				bios_version_cleaned=$(printf "%s" "$bios_version" | sed 's/^[^0-9]*//' | sed 's/(.*)//g' | xargs) # drop text before first number and anything in parentheses

				# first number is iDRAC generation
				idrac_generation=${bios_version_cleaned%% *}

				# remainder of string is iDRAC version
				idrac_version=${bios_version_cleaned#* } # remove everything up to the first space
				idrac_version=${idrac_version//[^0-9.]/} # filter non-numeric and non-period characters

				debug_print 3 "iDRAC Generation: %s" "$idrac_generation"
				debug_print 3 "iDRAC Version: %s" "$idrac_version"
			else # 1/
				debug_print 2 warn "Failed to collect iDRAC generation and version information"
			fi # 1/

			{ [ -z "$idrac_generation" ] || [ -z "$idrac_version" ]; } && debug_print 2 warn "Manual fan control capability could not be confirmed because iDRAC generation and/or version are unknown"
		;;

		gigabyte)
			debug_print 1 "Motherboard manufacturer: Gigabyte"
			debug_print 2 "Gigabyte motherboards with AST2500/AST2520 BMC chips are supported"
			mobo_model="${mobo_model%% *}" # retain only portion of model name left of first space
		;;

		h3c)
			mobo_manufacturer="h3c"
			debug_print 1 "Motherboard manufacturer name changed to: H3C" # New H3C
		;;

		hpe)
			debug_print 1 "Motherboard brand: Hewlett Packard Enterprise (HPE)"
			debug_print 2 caution "Most ProLiant servers through Gen 10 are compatible"
			debug_print 2 caution "When supported, Hewlett-Packard motherboard fan control should be considered EXPERIMENTAL"
			debug_print 2 caution "Many HPE servers have limited fan controls available only via BIOS or HP's proprietary iLO middleware"

			##
			# HPE has a large variety of server names.
			# Many of their server lines have long or similar model names.
			##

			mobo_gen="${mobo_model##* }" # Yz such as "M5" (generation)
			mobo_gen="$(printf "%.0f" "${mobo_gen//[!0-9.]/}")" # strip non-numeric chars
			mobo_model="$(grep -Eo '[DMS]L[0-9]+' <<< "$mobo_model")" # ProLiant DL/ML/SL models
			(( mobo_model > 10 )) && debug_print 3 warn "Gen $mobo_model likely NOT supported, but will attempt"
		;;

		hyve)
			debug_print 1 "Motherboard manufacturer: Hyve Solutions"
			debug_print 2 warn "Hyve motherboards have limited support, and are considered EXPERIMENTAL if supported"
		;;

		ibm|lenovo)
			debug_print 1 "Motherboard manufacturer: ${mobo_manufacturer_first_name^}"
			mobo_model="${mobo_model%% *}" # retain only portion of model name left of first space
		;;

		inspur)
			debug_print 1 "Motherboard manufacturer: Inspur Electronic Information"
		;;

		intel)
			debug_print 1 "Motherboard manufacturer: Intel"
			debug_print 2 warn "Limited support for Intel motherboards. Supported for some boards is EXPERIMENTAL"
			[ "${mobo_model:0:6}" = "M20NTP" ] && mobo_model="M20NTP" # Intel M20NTP server family
		;;

		quanta)
			debug_print 1 "Motherboard manufacturer: Quanta Computer (QC) || Quanta Cloud Technology (QCT)"
		;;

		sun)
			debug_print 1 "Motherboard manufacturer: Sun Microsystems"
			debug_print 2 warn "Sun Microsystems motherboards are currently not supported"
			mobo_gen="${mobo_model##* }" # sub-version/generation such as "M2"
			mobo_model="${mobo_model%% *}" # drop generation after model number
		;;

		##
		# Default mode for Supermicro is zone based.
		# A very small minority of Supermicro boards allow individual fan control.
		##

		supermicro)
			mobo_gen="${mobo_model:0:3}"

			if [ -n "${mobo_gen//[!BCHMX]/}" ]; then # 1/ isolate motherboard generation prefix
				[ "${mobo_gen:1:1}" != "1" ] && mobo_gen="${mobo_model:0:2}"
			else # 1/ unfamiliar board series
				unset mobo_gen
			fi # 1/
		;;

		tyan)
			debug_print 1 "Motherboard version: $mobo_version"
			debug_print 2 "Tyan motherboard support is EXPERIMENTAL at this time" false true
			mobo_model="$(grep -Eo 'S[0-9]+' <<< "$mobo_model")" # isolate model series from the full model name
		;;
	esac # 1/

	if [ "$mobo_model" ]; then # 1/
		debug_print 1 "Refined $mobo_manufacturer motherboard model: $mobo_model"
	else # 1/
		debug_print 1 warn "Motherboard model: unknown" false true
	fi # 1/
}
