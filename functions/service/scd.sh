# find smallest common divisor (SCD) of all input_parameters
function scd ()
{
	local common_divisor
	local divisor
	local number
	local smallest

	local -a input_parameters

	input_parameters=("$@")
	common_divisor="${input_parameters[0]}"

	# calculate GCD of all input parameters
	for number in "${input_parameters[@]}"; do # 1/
		common_divisor=$(gcd "$common_divisor" "$number")
		[ "$common_divisor" -eq 1 ] && break
	done # 1/

	# find smallest common divisor greater than 1
	for ((divisor = 2; divisor <= common_divisor; divisor++)); do # 1/
		if [ $((common_divisor % divisor)) -eq 0 ]; then # 1/
			printf "%s" "$divisor"
			return
		fi # 1/
	done # 1/

    # if no common divisor found greater than 1, return the smallest number
	smallest="${input_parameters[0]}"

	for number in "${input_parameters[@]}"; do # 1/
		if [ "$number" -lt "$smallest" ]; then # 1/
			smallest=$number
		fi # 1/
	done # 1/

	# when no common divisor found greater than 1, return smallest number
	printf "%s" "$smallest"
}
