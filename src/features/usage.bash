#!/usr/bin/env bash

empty="
\n	usage
\n\t	git backup <command> [flags]
\n	command
\n\t	create		\t create new backup branch, commit everything and restore working directory
\n\t	delete		\t delete given backup branch and its commit
\n\t	restore		\t restore working directory from given backup branch
\n\t	ls				\t list all backup branches
\n\t	push			\t push backup branches to configured backup remote
\n\t	fetch			\t fetch backup branches to configured backup remote
\n	flags
\n\t	--help : print help for a given command
"

create="
\n	usage
\n\t	git backup create
\n	description
\n\t	create new backup branch, commit everything and restore working directory
"


case $1 in
	create)
		echo -e $create
	;;
	""|*)
		echo -e $empty
	;;
esac