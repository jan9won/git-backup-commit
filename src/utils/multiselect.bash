#!/usr/bin/env bash
multiselect(){

	IFS=$' ,\t\n'
	
	# param 1 : whitespace separated string of options
	OPTIONS=("$1")
	# param 2 : whitespace separated string of descriptions
	OPTIONS_DESCRIPTION=("$2")

	echo ${#OPTIONS}
	echo ${OPTIONS[@]}
	exit 0
	# check if param 1 is an array
	for i in "${!OPTIONS[@]}"
	do
		echo $i
		printf "${OPTIONS_DESCRIPTION[$i]} "
		printf "[${OPTIONS[$i]}]"
		if (( ${#OPTIONS[@]} > $i + 1 )); then
			printf " / "
		fi
	done

	read local SELECTED_OPTION

	if [[ $SELECTED_OPTION = "x" ]]; then
		printf "Exiting installaion process\n"
		exit
	else
		printf "Invalid input\n"
		get_script_directory_name
	fi
}
multiselect $@