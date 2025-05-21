##
# Inventory read fan header names based on formatted IPMI sensor output.
#
# Initial population of all fan headers physically present on the motherboard,
# regardless of whether or not a fan is attached to each and/or running.
#
# 1. Identify all known existing fan headers
# 2. Assign fan header ID number sequentially based on order of discovery.
##

function inventory_fan_headers ()
{
	local fan_id			# numeric fan id number
	local fan_info			# each line of IPMI sensor output to be parsed
	local -u fan_name		# name of fan reported by IPMI

	debug_print 1 "Inventory fan headers"

	fan_id=0 # fan id counter

	while read -r fan_info; do # 1/ parse each line of IPMI fan sensor scan

		if parse_ipmi_column "fan_name" "sensor" "fan" "name" "$fan_info"; then # 1/
			[ -z "$fan_name" ] && continue # 2/ skip lines with no fan name
		else # 1/ parsing call failed
			continue
		fi # 1/

		debug_print 2 "Discovered fan header $fan_name (assigned Fan ID: $fan_id)"

		fan_header_name["$fan_id"]="$fan_name"
		fan_header_id["$fan_name"]="$fan_id" # assign next sequential fan id

		# track every discovered physical fan header regardless of state
		set_ordinal_in_binary "on" "$fan_id" "fan_header_binary"
		((fan_id++)) # increment fan id placeholder

	done <<< "$($ipmitool sensor | grep -i fan)" # 1/ use short-hand IPMI output for brevity

	[ "$fan_id" -eq 0 ] && bail_noop "No fan header names were processed, indicating a problem with fan header name collection logic"
}
