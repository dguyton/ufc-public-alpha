##
# IPMI sensor output parsing
#
# Parse fan header information from a single line of IPMI sensor output.
#
# IPMI sensor fan output is separated by | character between output fields.
# Under very rare circumstances, motherboards may have fan header names labeled
# with space characters included in their name. These spaces are problematic
# from a standpoint of parsing the output, as spaces can and are often used as
# filler in between delimiters (|) separating output fields, to improve human
# legibility of IPMI sensor outputs.
#
# Input arguments:
#
# $1 = name of variable to populate with result of parsing
# $2 = sensor reading application or section of IPMI to use for data inquiry (e.g. sdr or sensor)
# $3 = sensor type (fan | temp )
# $4 = metric; e.g. name, status, etc.
# $5 = single line from sensor output dump to be parsed
# $6 = extended array name: ipmi_{sensor_reader}_column_{object type}_{extension}[{metric}]
#
# The array index 'ipmi_{sensor_reader}_column_{object type}[{metric}]' is expected to
# contain the positional value within the $3 string that is the data requested.
#
# Examples
# 1. Parse fan name from IPMI raw output:
# 	parse_ipmi_column "fan_name" "sensor" "fan" "name" "$fan_info"
##

function parse_ipmi_column ()
{
	if (( $# < 5 )); then # 1/
		debug_print 4 warn "Missing one or more required inputs" true
		return 1
	fi # 1/

	local sensor_reader		# sensor reading application of metric to parse from raw data
	local data_line		# line of raw data to be parsed
	local extension		# extended array name
	local metric			# key inside associative array
	local position
	local target			# name of target variable to set result equal to
	local sensor_type		# metric to parse from raw data

	# ensure target variable name is provided
	if [ -z "$1" ]; then # 1/
		debug_print 2 warn "No target variable name specified for result" true
		return 1
	fi # 1/

	local -n target="$1" # create indirect reference to target variable

	sensor_reader="$2"
	sensor_type="$3"
	metric="$4"
	data_line="$5"
	extension="$6"

	# ensure target variable name is provided
	if [ -z "$data_line" ]; then # 1/
		debug_print 2 warn "No data to parse" true
		return 1
	fi # 1/

	# ensure sensor reading application and sensor type are provided
	if [ -z "$sensor_reader" ]; then # 1/
		debug_print 2 warn "Invalid or unset sensor reading application name variable (\$2): '$2'" true
		return 1
	fi # 1/

	if [ -z "$sensor_type" ]; then # 1/
		debug_print 2 warn "Invalid or unset sensor type variable (\$3): '$3'" true
		return 1
	fi # 1/

	# ensure metric is provided
	if [ -z "$metric" ]; then # 1/
		debug_print 2 warn "Invalid or unset metric variable (\$4): '$4'" true
		return 1
	fi # 1/

	if [ -z "$extension" ]; then # 1/ construct dynamic associative array name
		local -n array_name="ipmi_${sensor_reader}_column_${sensor_type}"

		if ! declare -p array_name &>/dev/null; then # 2/ array name does not exist
			debug_print 3 warn "Invalid or undefined array reference: ipmi_${sensor_reader}_column_${sensor_type}" true
			return 1
		fi # 2/
	else # 1/ construct dynamic associative array name with array name extension
		local -n array_name="ipmi_${sensor_reader}_column_${sensor_type}_${extension}"

		if ! declare -p array_name &>/dev/null; then # 2/
			debug_print 3 warn "Invalid or undefined array reference: ipmi_${sensor_reader}_column_${sensor_type}_${extension}" true
			return 1
		fi # 2/
	fi # 1/

	# verify metric exists in the associative array and contains a numeric value
	if [ -n "${array_name[$metric]}" ]; then # 1/
		position="${array_name[$metric]}"
		position="${position//[!0-9]/}" # strip non-numeric characters

		if (( position > 0 )); then # 2/ ensures position is not null and a valid integer > 0
			target="$(awk -F'|' -v pos="$position" '{gsub(/^[ \t]+|[ \t]+$/, "", $pos); print $pos}' <<< "$data_line")" # extract value from data line using awk
		else # 2/
			debug_print 3 warn "Metric position '${position}' in array is invalid"
			return 1
		fi # 2/
	else # 1/
		debug_print 2 critical "Undefined sensor column: ${array_name[$metric]}"
		debug_print 3 bold "Check configuration files for missing information"
		return 1
	fi # 1/
}
