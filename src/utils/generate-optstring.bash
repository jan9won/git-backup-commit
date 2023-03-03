# # usage
#
#	Positional Argument $1 : Newline separated set of comma separated strings.
#	Positional Argument $2 : Original arguments with long options you want to replace with short options.
#
# 	create_optstring "
#			[short option], [long option], [has argument (true/false)]
#			[short option], [long option], [has argument (true/false)]
#			...
#		" [arguments with long options]
#
# # example
#
# 	create_optstring "
#			-h, --help, false
#			-r, --route, true
#			...
#		" --help -r
#
# # returns
#
#		"hr: -h -r"
#

OPTSTRING=""

# split config string into lines
IFS=$'\n'
CONFIG_LINES=($1)
shift

for CONFIG_LINE in "${CONFIG_LINES[@]}"; do
	
	# split config lines with comma
	IFS=$','
	CONFIG_PAIR=($CONFIG_LINE)
	
	# trim whitespace
	CONFIG_PAIR_TRIMMED=()
	for arg in "${CONFIG_PAIR[@]}"; do
		CONFIG_PAIR_TRIMMED+=($(echo $arg | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'))
	done

	# replace long option with short option
	for arg in "$@"; do
		shift
		if [[ $arg = ${CONFIG_PAIR_TRIMMED[1]} ]]; then
			set -- "$@" ${CONFIG_PAIR_TRIMMED[0]}
		else
			set -- "$@" "$arg"
		fi
	done

	# optstring : add short option
	OPTSTRING+=${CONFIG_PAIR_TRIMMED[0]:1}

	# optstring : add argument mark
	if [[ ${CONFIG_PAIR_TRIMMED[2]} = "true" ]]; then
		OPTSTRING+=":"
	fi
done

# return concatenated results
echo "$OPTSTRING $@"