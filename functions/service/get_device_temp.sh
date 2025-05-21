# return minimum, maximum, average temperature for each disk, and current average temp of all disks combined
function get_device_temp ()
{
	local counter				# count of devices to use when averaging valid (non-zero) drive temperatures
	local delta				# delta of average temperature change between current and previous averages
	local disk_dev				# disk device name or id
	local device_name			# device name (e.g. sda)
	local temperature			# current temperature of a given device
	local temperature_sum		# sum of all temperatures

	counter=0
	temperature_sum=0

	if [ "$device_count" -eq 0 ]; then # 1/ no disks to evaluate
		debug_print 2 caution "Nothing to do. No drives found."
		unset device_avg_temp
		unset device_highest_temp
		unset device_lowest_temp
		unset warmest_drive
		return
	fi # 1/

	# no device temp reader available
	[ -z "$device_temp_reader" ] && return

	##
	# Capture current temp for each disk device.
	# Convert invalid temperature readings to 0.
	# Ignore 0 degree readings when calculating average drive temp.
	##

	{ [ -z "$device_lowest_temp" ] || [ "$device_lowest_temp" -lt 1 ]; } && device_lowest_temp=99 # reset global var

	for device_name in "${device_list_array[@]}"; do
		disk_dev="/dev/$device_name"

		# store previous temp reading to support temp delta tracking
		device_temp_last["$device_name"]="${device_temp[$device_name]}" # save previous reading
		[ -z "${device_temp_last[$device_name]}" ] && device_temp_last["$device_name"]=0 # convert null to explicit zero

		# get current drive temp, normalize it, and store it
		if [ "$device_temp_reader" = "smartctl" ]; then # 1/
			temperature="$(smartctl -A "$disk_dev" | grep -i temperature | awk '{print $(NF)}')" # grab only the last column
		else # 1/
			if [ "$device_temp_reader" = "hddtemp" ]; then # 2/
				temperature="$(hddtemp "$disk_dev" | awk '{print $(NF)}')" # last column data should be disk temp in Centigrade
			fi # 2/
		fi # 1/

		temperature="$(printf "%.0f" "${temperature//[!.0-9]/}")" # strip non-numeric characters, truncate right of decimal, round result
		[ -z "$temperature" ] && temperature=0 # force empty string to explicit zero
		device_temp["$device_name"]=$((temperature)) # preserve each current disk temp reading

		debug_print 4 "Disk $device_name temp: ${device_temp[$device_name]} C"

		# track number of drive temp data points, average drive temp, lowest/highest drive temps
		if (( temperature > 0 )); then # 1/ ignore invalid readings
			((counter++))
			temperature_sum=$(( temperature_sum + temperature ))

			# ensure lowest temp gets tracked from first reading or if previous reading was bad
			(( device_temp_low["$device_name"] == 0 )) && device_temp_low["$device_name"]=$((temperature))

			# check if current device sets new highest/lowest device temps
			(( temperature > device_temp_high["$device_name"] )) && device_temp_high["$device_name"]=$((temperature))
			(( temperature < device_temp_low["$device_name"] )) && device_temp_low["$device_name"]=$((temperature))

			# all devices highest/lowest temps
			(( $(printf "%s" "$temperature $device_highest_temp" | awk '{print ($1 > $2)}') )) && device_highest_temp=$((temperature))
			(( $(printf "%s" "$temperature $device_lowest_temp" | awk '{print ($1 < $2)}') )) && device_lowest_temp=$((temperature))

			if (( $(printf "%s" "$temperature $device_highest_temp" | awk '{print ($1 > $2)}') )); then # 2/
				device_highest_temp=$((temperature))
				warmest_drive="$device_name"
			fi # 2/
		fi # 1/
	done

	if (( counter == 0 )); then # 1/
		debug_print 2 warn "No disk storage devices detected!"
		unset device_avg_temp
		unset device_highest_temp
		unset device_lowest_temp
		unset warmest_drive
		return
	fi # 1/

	device_avg_temp_last=$((device_avg_temp)) # preserve previous average disk temperature
	device_avg_temp="$(printf "%0.f" "$(awk "BEGIN { print ( $temperature_sum / $counter ) }")")" # calc average disk temp and round it to nearest integer

	if (( device_avg_temp < 1 )); then # 1/ average temp is invalid
		device_avg_temp=$((device_avg_temp_last)) # restore last valid temp and recycle it as current temp
		return
	fi # 1/

	debug_print 3 "Average drive temperature is $device_avg_temp degrees Celsius"

	[ -n "$warmest_drive" ] && debug_print 3 "Warmest drive is ${warmest_drive^^} at $device_highest_temp degrees Celsius"

	##
	# Temperature change between polling intervals (delta) is calculated using mean (average) disk temperature readings.
	# It is possible to use max temp readings as an alternative to calculate the temperture delta. if [ -n "$log_filename" ], average
	# temp readings are recommended, because they tend to result in smoother fan speed changes.
	#
	# Most use cases will see results of drive tempertures remaining well within acceptable ranges of the target temp
	# (set point) for all drives. if [ -n "$log_filename" ], if a user has one or more drives that tend to run significantly hotter than
	# their other disks - perhaps due to a mixture of drives in the same server - it may be advantageous to modify this
	# script to utilize highest drive temps instead of average drive temps.
	##

	device_avg_temp_delta_last=$(( device_avg_temp_last - device_avg_temp_target )) # deviation of previous average disk temp from target average disk temp
	device_avg_temp_delta=$(( device_avg_temp - device_avg_temp_target )) # deviation of average disk temp from target mean disk temperature

	# sign (+/-) info reported in log
	debug_print 4 "Average disk temperature deviation from target: $( (( device_avg_temp_delta > 0 )) && printf "+" )${device_avg_temp_delta} degrees Celsius"
}
