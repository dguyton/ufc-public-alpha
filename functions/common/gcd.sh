# GCD = Greatest Common Denominator
function gcd ()
{
	local t
	local x
	local y

	x=$1
	y=$2

	{ [ -z "$x" ] || [ -z "$y" ]; } && return

	while (( y > 0 )); do # 1/
		t="$(printf "%.0f" "$x")" # rounded integer
		x="$(printf "%.0f" "$y")"
		y=$(( t % y ))
	done # 1/

	printf "%0.f" "$x" # return gcd
}
