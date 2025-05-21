##
# Determine the following metrics regarding CPU temperature:
# 1. Each CPU temperature
# 2. Optionally, each CPU core temp
# 3. Average of all CPU temps
##

##
# IPMI reports only the physical case temperature for each CPU, which is easier to manage.
# if [ -n "$log_filename" ], IPMI is slow.
#
# When available, lm-sensors is quicker and reports more granular data (CPU core temps).
#
# sysctl is not useful, as it does not provide CPU temperature data.
#
# When the 'sensors' command is available (lm-sensors program), CPU temperatures may be
# read as either aggregate (physical) CPU temperature reports, or individual CPU core
# temperatures.
##

##
# 'core' cpu temp reporting mode
# --> only works with lm-sensors and not with ipmitool
# --> treat each cpu temp as highest of all its active core temps
# --> ignore reported physical cpu temp
# --> cpu temp for each cpu is always the highest core temp for that cpu
#
# 'cpu' temp reporting mode tracks physical cpu reported metrics only (i.e. not cpu cores)
#
# sensors_column_cpu_temp[core_id]		= current ID of CPU core being read
# sensors_column_cpu_temp[core_temp]	= current raw temperature in C of CPU core
# sensors_column_cpu_temp[physical]	= current temperature in C of physical CPU
# sensors_column_cpu_temp[high]		= CPU high temperature threshold
# sensors_column_cpu_temp[critical]	= CPU critical temperature threshold
##

##
# Notes:
# 1. CPU core temps can be null. This can happen if a cpu core does not exist or is
# not currently active.
#
# 2. Null temperature is not acceptable for physical CPU team readings.
##

function get_cpu_temp ()
{
	local core_data					# raw stream of core temp data from sensors program output
	local core_id 						# current cpu core temperature
	local core_temp 					# current cpu core temperatures, keyed by cpu core id
	local counter 						# counter to track number of valid arguments
	local cpu_data 					# raw ipmitool output of cpu temperature data
	local cpu_id 						# numeric id of physical cpu currently being examined
	local cpu_temp_average_calc			# current average of all CPU temperatures
	local cpu_temp_current				# current temperature of currrently evaluated CPU ID
	local temperature_sum				# temperature sum of all cpus reporting a valid temperature
	local temperature 					# physical cpu reported temperature (IPMI)
	local key 						# placeholder when time-shifting rolling average data points

	# reset highest/lowest trackers
	cpu_temp_highest=0
	cpu_temp_lowest=0

	if [ "$cpu_temp_sensor" = "sensors" ]; then # 1/ use lm-sensors

		for (( cpu_id=0; cpu_id<=numcpu; cpu_id++ )); do # 1/ cpu id counter from 0 to numcpu (captures start cpu id of 0 or 1)
			debug_print 4 "Get current temperature for CPU $cpu_id"

			if [ "$cpu_temp_method" = "core" ]; then # 2/ core value mode

				cpu_temp_current=0 # reset current physical cpu temperature tracker for each CPU ID in primary loop

				##
				# Parse all cpu cores for current cpu id
				##

				while read -r core_data; do # 2/ parse each line of cpu temp data by cpu core id (more granular than by cpu id)

					[ -z "$core_data" ] && continue # no core data to parse for current CPU ID

					##
					# extract cpu core id
					# ipmi_${category}_column_${type}_${extension} | ipmi_sensor_column_cpu_temp[core_id]
					##

					! parse_ipmi_column "core_id" "sensor" "cpu" "core_id" "$core_data" "temp" && continue

					core_id="${core_id//[!0-9]/}"

					if [ -z "$core_id" ]; then # 3/
						debug_print 3 "Skipping invalid CPU core ID (not an integer)"
						continue
					fi # 3/

					##
					# extract current cpu core temperature
					# ipmi_${category}_column_${type}_${extension} | ipmi_sensor_column_cpu_temp[core_temp]
					##

					! parse_ipmi_column "core_temp" "sensor" "cpu" "core_temp" "$core_data" "temp" && continue

					core_temp="${core_temp//[!.0-9]/}" # strip any char not a number or decimal point

					if [ -z "$core_temp" ]; then # 3/ no data
						debug_print 3 "No temperature data for CPU core ID $core_id"
						continue
					fi # 3/

					core_temp=$(printf "%0.f" "$core_temp") # round off and remove decimal when it exists
					(( core_temp == 0 )) && continue # skip when data is invalid

					# preserve prior core temp reading
					cpu_core_temp_last["$cpu_id:$core_id"]="${cpu_core_temp["$cpu_id:$core_id"]}"

					# store each core temperature for reporting purposes in associative array index {physical cpu id:cpu core id}
					cpu_core_temp["$cpu_id:$core_id"]="$core_temp"

					##
					# Keep track of warmest and coolest CPU cores for current CPU ID
					##

					# set warmest core temp tracker when current core temp is record high for current CPU ID or high temp not tracked yet (null)
					if (( core_temp > cpu_core_temp_highest[$cpu_id] )); then # 3/ warmest core temp record for current cpu
						cpu_core_temp_highest[$cpu_id]="$core_temp"

						# keep track of highest core temperature and align current physical cpu temperature tracker to it
						(( core_temp > cpu_temp_current )) && cpu_temp_current="$core_temp"
					fi # 3/

					# set coolest core temp tracker when current core temp is record low for current CPU ID or lowest temp not tracked yet (null)
					if [ -z "${cpu_core_temp_lowest[$cpu_id]}" ] || (( core_temp < cpu_core_temp_lowest[$cpu_id] )); then # 3/ coolest core temp record for current cpu
						cpu_core_temp_lowest[$cpu_id]="$core_temp"
					fi # 3/

				done <<< "$(sensors "coretemp-isa-00$(printf "%02d" "$cpu_id")" | grep -i "core ")" # 2/ multi-line output of cpu cores belonging to current cpu id

			else # 2/ physical cpu mode (lm-sensors)

				##
				# Calls lm-sensors and keeps only data line of given CPU ID.
				#
				# Even though an attempt is made to just grep a single CPU ID output, it is
				# possible that multiple lines will be returned by the lm-sensors query.
				# Therefore, this section will parse multiple lines of data output if needed.
				##

				while read -r cpu_data; do # 2/ parse each line of cpu temp data by cpu id (less granular than by cpu core id)

					##
					# derive current physical cpu temperature
					# ipmi_sensor_column_cpu_temp[physical]
					##

					! parse_ipmi_column "cpu_temp_current" "sensor" "cpu" "physical" "$cpu_data" "temp" && continue

					# strip any char not a number or decimal point
					cpu_temp_current="${cpu_temp_current//[!.0-9]/}"

					# no data
					[ -z "$cpu_temp_current" ] && debug_print 3 "No temperature data for CPU $cpu_id"

					# round when decimal exists, remove decimal, min value = 0
					cpu_temp_current=$(printf "%0.f" "$cpu_temp_current")

				done <<< "$(sensors | grep -i "package id $(printf "%d" "$cpu_id")")" # 2/ multi-line output of physical cpu ids

			fi # 2/

			##
			# Trap when no temp reading for current CPU ID was derived above, regardless of which method was used.
			#
			# When core temp method is utilized, this occurs when none of the core temps could be read.
			#
			# when physical CPU temp method is utilized, this occurs when the current there
			# was no valid current temperature reading for the current CPU ID.
			#
			# $cpu_temp_current is either highest CPU core temp or highest physical temp, depending on temp calc method.
			##

			if (( cpu_temp_current == 0 )); then # 2/ zero or invalid result, do not update current cpu id temp record

				# apply contextually appropriate debug messages
				if [ "$cpu_temp_method" = "core" ]; then # 3/ core values mode
					debug_print 4 caution "Skipping CPU ID $cpu_id as something went wrong reading current CPU core temperatures"
				else # 3/ physical cpu mode
					debug_print 4 caution "Skipping CPU ID $cpu_id as something went wrong reading current CPU temperature"
				fi # 3/

				continue # stop further processing of outer loop (by CPU ID)
			fi # 2/

			##
			# Continue processing aggregate CPU level data regardless of CPU temp read mode
			##

			# preserve previous temperature reading
			cpu_temp_last["$cpu_id"]="${cpu_temp[$cpu_id]}"

			# set new current cpu temp
			cpu_temp["$cpu_id"]="$cpu_temp_current"

			##
			# Calculate current highest and lowest cpu temps among all CPUs
			#
			# For each CPU ID, check if there is a new recored high or record low temp.
			# Applies regardless of whether using core or physical cpu temp tracking method.
			##

			# tag warmest temp record of current cpu id
			(( cpu_temp_current > cpu_temp_highest )) && cpu_temp_highest="$cpu_temp_current"

			# tag coolest temp record of current cpu id
			{ (( cpu_temp_lowest == 0 )) || (( cpu_temp_current < cpu_temp_lowest )); } && cpu_temp_lowest="$cpu_temp_current"

		done # 1/

	else # 1/ use ipmi sdr method (cpu mode only), which typically begins at CPU ID 1

		##
		# Much different outer logic loop required here due to variations in how IPMI SDR
		# presents the same sensor data. Core metrics are not supported (only physical temps).
		#
		# With IPMI SDR, it is necessary to suss out each CPU ID
		##

		while read -r cpu_data; do # 1/ parse each line of cpu temp data by cpu id (less granular than by cpu core id)

			# parse each CPU ID from ipmitool sdr output
			! parse_ipmi_column "cpu_id" "sdr" "cpu" "id" "$cpu_data" && continue

			cpu_id="${cpu_id//[!0-9]/}" # must be integer
			[ -z "$cpu_id" ] && continue # not a cpu id

			# extract current CPU temperature
			! parse_ipmi_column "temperature" "sdr" "cpu" "temp" "$cpu_data" && continue

			# strip any char not a number or decimal point
			cpu_temp_current="${cpu_temp_current//[!.0-9]/}"

			if [ -z "$cpu_temp_current" ]; then # 2/ no data
				debug_print 3 caution "Invalid temperature data for CPU $cpu_id"
				continue
			fi # 2/

			# round when decimal exists, remove decimal, min value = 0
			cpu_temp_current=$(printf "%0.f" "$cpu_temp_current")
			(( cpu_temp_current == 0 )) && continue # invalid data, skip further processing

			# preserve previous temperature reading
			cpu_temp_last["$cpu_id"]="${cpu_temp[$cpu_id]}"

			# set new current cpu temp
			cpu_temp["$cpu_id"]="$cpu_temp_current"

			##
			# Calculate current highest and lowest cpu temps among all CPUs
			#
			# For each CPU ID, check if there is a new recored high or record low temp.
			# Applies regardless of whether using core or physical cpu temp tracking method.
			##

			# tag warmest temp record of current cpu id
			(( cpu_temp_current > cpu_temp_highest )) && cpu_temp_highest="$cpu_temp_current"

			# tag coolest temp record of current cpu id
			{ (( cpu_temp_lowest == 0 )) || (( cpu_temp_current < cpu_temp_lowest )); } && cpu_temp_lowest="$cpu_temp_current"

		done <<< "$($ipmitool sdr | grep -i 'cpu' | grep -i 'temp')" # 1/
	fi # 1/

	##
	# Trap when all cpu temp calcs failed.
	#
	# If all attempts to determine current CPU temperatures failed, revert
	# current high/low CPU temperature settings to their previous value.
	##

	(( cpu_temp_highest == 0 )) && cpu_temp_highest="$cpu_temp_highest_last"
	(( cpu_temp_lowest == 0 )) && cpu_temp_lowest="$cpu_temp_lowest_last"

	##
	# Calculate average temperature of all CPUs combined.
	#
	# A counter is used instead of simply using known number of CPUs ($numcpu)
	# to calculate overall average CPU temperature, because there is always a
	# possibility for some reason the temperature for a given CPU will be
	# unavailable or invalid during the current sensor read attempt. Thus, by
	# excluding invalid CPU temperature calculated readings from the average
	# CPU temp calculation, the program avoids acting on temporary bad data
	# which could cause sudden and wild swings in fan performance when it is
	# unnecessary.
	##

	for (( cpu_id=0; cpu_id<=numcpu; cpu_id++ )); do # 1/ cycle through each physical cpu
		{ [ -z "${cpu_temp[$cpu_id]}" ] || (( cpu_temp[$cpu_id] < 1 )); } && continue # exclude invalid temperature values
		((counter++)) # increment number of valid data points
		temperature_sum=$(( temperature_sum + cpu_temp[$cpu_id] )) # cumulative cpu temperature degrees
	done # 1/

	if (( temperature_sum == 0 )); then # 1/ no good temp values
		debug_print 4 warn "Average CPU temperature could not be determined" true
		return
	fi # 1/

	##
	# Average temp of all CPUs combined.
	# calculate current average of all CPUs reporting a current temperature.
	##

	if (( counter == 0 )); then # 1/
		debug_print 4 warn "Skipping CPU average calculation due to missing data" true
		return
	fi # 1/

	cpu_temp_average_calc="$(printf "%0.f" "$(awk "BEGIN { print ( $temperature_sum / $counter ) }")")"

	if (( cpu_temp_average_calc == 0 )); then # 1/ should never happen, but trap bad data just in case it does
		debug_print 4 caution "An error occurred, average CPU temperature not calculated" true
		return
	fi # 1/

	##
	# Bump existing array elements to make room for new CPU average
	# temperature record. Limit the number of retained historic records
	# to avoid making the algorithms too slow. On the other hand, the
	# more historic records, the more accurate the rolling average.
	##

	# shuffle the stack
	for (( key=counter; key>0; key-- )); do # 1/ bump array contents in reverse order from end of array indeces
		cpu_temp_average[$key]="${cpu_temp_average[$((key-1))]}"
	done # 1/

	##
	# Add most recent CPU temperature average to bottom of the list.
	# Then, calculate new average value of all average temperatures,
	# to derive 'rolling' average of averages.
	##

	# add most recent average to bottom of stack (newest record)
	cpu_temp_average[1]="$cpu_temp_average_calc" # append new record to bottom of array

	# count number of existing elements in rolling cpu temp array
	counter="${#cpu_temp_average[@]}"

	# pop the stack (remove oldest record until limit no longer exceeded)
	while (( counter >= cpu_temp_rolling_average_limit )); do # 1/
		unset "cpu_temp_average[-1]"
		((counter--))
	done # 1/

	# reset numerator
	temperature_sum=0

	# sum recent historical averages
	for (( key=1; key<=counter; key++ )); do # 1/
		temperature_sum=$(( temperature_sum + cpu_temp_average[$key] ))
	done # 1/

	# calculate rolling average
	cpu_temp_rolling_average="$(printf "%0.f" "$(awk "BEGIN { print ( $temperature_sum / $counter ) }")")"

	debug_print 4 "CPU temp rolling average: $cpu_temp_rolling_average C"
}
