# return formatted text based on delta value input

function compute_trend() {
	local delta

	delta=$1

	# input must be numeric
	delta="${delta//[!0-9-]/}"

	# default = 0 (equal)
	delta=$(printf "%0.f" "$delta")

	if (( delta > 0 )); then # 1/
		[ "$enable_color_output" = "true" ] && printf "\e[31minc\e[0m" || printf "inc"
	else # 1/
		if (( delta < 0 )); then # 2/
			[ "$enable_color_output" = "true" ] && printf "\e[32mdec\e[0m" || printf "dec"
		else # 2/ equal
			printf "---"
		fi # 2/
	fi # 1/
}
