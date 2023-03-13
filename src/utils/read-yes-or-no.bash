read_yes_or_no(){
	printf "[Y/N] "
	read ANSWER
	if [[ $ANSWER =~ ^[yY]$ ]]; then
		return 0
	elif [[ $ANSWER =~ ^[nN]$ ]]; then
		return 1
	else
		printf "Bad input $ANSWER\n"
		read_yes_or_no
	fi
}

read_yes_or_no