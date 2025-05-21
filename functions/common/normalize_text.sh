# parse delimiters
function normalize_text ()
{
	printf "%s" "${1//[,.:;|\/\\-]/ }";
}
