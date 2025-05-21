# LCM = Least Common Multiple
function lcm ()
{
	local g
	local x
	local y

	x=$1
	y=$2

	{ [ -z "$x" ] || [ -z "$y" ]; } && return

	g=$(gcd "$x" "$y") # need the gcd

	printf "%0.f" $(( x * y / g )) # return lcm
}
