
#------------------------------------------------------------------------------#
# input
#------------------------------------------------------------------------------#
# split CONF
IFS_DEFAULT=$IFS
IFS=$'\n'
CONF_LINES=($1)
IFS=$IFS_DEFAULT
# split ARGS
ARGS=(${@:2})

#------------------------------------------------------------------------------#
# variables
#------------------------------------------------------------------------------#
# option matching patterns
OPT_PAT_LONG="^--([a-zA-Z0-9]+-)*[a-zA-Z0-9]+$"
OPT_PAT_SHORT="^-[a-zA-Z0-9]$"

# CONF_LINE indexes
CONF_IDX_SHORT=0
CONF_IDX_LONG=1
CONF_IDX_ARGS=2

# options
OPT_SHORT=()
OPT_LONG=()

# output
OPTSTRING=""
USEFUL_OPTS=()
REST_OPTS=()
REST_ARGS=()

#------------------------------------------------------------------------------#
# functions
#------------------------------------------------------------------------------#
# clean_config_line(){}
# filter_option_args(){}

organize_options(){
	local IFS=",$IFS" 
	for CONF_LINE in "${CONF_LINES[@]}"; do
		# split line with comma
		CONF_LINE=($CONF_LINE)
		# add to opt
		OPT_SHORT+=("${CONF_LINE[$CONF_IDX_SHORT]}")
		OPT_LONG+=("${CONF_LINE[$CONF_IDX_LONG]}")
		# add to optstring 
		OPTSTRING+="${CONF_LINE[$CONF_IDX_SHORT]:1:1}" # short option
		if [[ "${CONF_LINE[$CONF_IDX_ARGS]}" = "true" ]]; then 
			OPTSTRING+=":" # argument existence
		fi
	done
}

organize_arguments(){
	for ARG in "${ARGS[@]}"; do
		# has right option pattern
		if [[ "$ARG" =~ $OPT_PAT_SHORT || "$ARG" =~ $OPT_PAT_LONG ]]; then
			# is in config
			if [[ " ${OPT_SHORT[*]} " =~ " $ARG " || " ${OPT_LONG[*]} " =~ " $ARG " ]]; then
				USEFUL_OPTS+=($ARG)
			# is not in config
			else
				REST_OPTS+=($ARG)
			fi
			# has arg
		fi

		# is not an option
		if [[ "${ARG:0:1}" != "-" ]]; then
			REST_ARGS+=($ARG)
		fi
	done
}

replace_long_options(){
	for i in "${!USEFUL_OPTS[@]}"; do
		if [[ "${USEFUL_OPTS[$i]}" =~ $OPT_PAT_LONG ]]; then
			unset 'USEFUL_OPTS[$i]'
		fi
	done
}

remove_duplicate_short_options(){
	USEFUL_OPTS=($(printf '%s\n' "${USEFUL_OPTS[@]}" | sort -u))
}

organize_options
organize_arguments
replace_long_options
remove_duplicate_short_options

echo " $OPTSTRING "
echo " ${USEFUL_OPTS[@]} "
echo " ${REST_OPTS[@]} "
echo " ${REST_ARGS[@]} "
exit 0