# report current date/time in human-readable date format
function build_date_string ()
{
	local result
	result="$(date +%Y-%b-%d)" # YYYY-MMM-DD (date/time showing date only)
	printf "%s" "$result"
}
