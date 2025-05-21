# find nearest prime number >= input
function find_next_prime() {
	local index
	local is_prime
	local num

	num="$1"

	if (( num < 2 )); then # 1/
		printf "2" # first prime number is 2
		return
	fi # 1/

	(( num % 2 == 0 )) && (( num++ )) # if even, make it odd (except for 2)

	while true; do # 1/ infinite loop until next prime is found
		is_prime=true

		# check divisibility for numbers up to square root of num (calculated using i*i <= num)
		for (( index=2; index*index <= num; index++ )); do # 2/
			if (( num % index == 0 )); then # 1/ no remainder
				is_prime=false
				break
			fi # 1/
		done # 2/

		if (( is_prime == true )); then # 1/
			printf "%s" "$num"
			return
		fi # 1/

		(( num+= 2 )) # next odd number
	done # 1/
}
