#!/usr/bin/env bash

SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
	SOURCE=$(readlink "$SOURCE")
	[[ $SOURCE != /* ]] && SOURCE=$SCRIPT_PATH/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )

# --------------------------------------------------------------------------- #
# Check if we're inside a git repository
# --------------------------------------------------------------------------- #

IS_GIT_REPO=$(git rev-parse --is-inside-work-tree 2>/dev/null)

if [[ ! $IS_GIT_REPO = "true" ]]; then
	printf "You're not in a git repository.\n"
	exit 1
fi

# --------------------------------------------------------------------------- #
# handle "-h|--help" option
# --------------------------------------------------------------------------- #

# Generate Optstring and Replace Long Options
OPT_RESULT=($("$SCRIPT_PATH/utils/generate-optstring.bash" "
	-h, --help, false
" $@))

OPTSTRING=${OPT_RESULT[0]}
OPT_RESULT_ARRAY=("${OPT_RESULT[@]:1}")

# set replaced arguments
set -- "${OPT_RESULT_ARRAY[@]}"

# handle -h option, or remove all other options
while getopts ":$OPTSTRING" opt
do
	case $opt in
		h)
			shift
			$SCRIPT_PATH/features/usage.bash $@
			exit 0
			;;
		?)
			echo "unknown flag : $1"
			shift
			;;
	esac 
done

# --------------------------------------------------------------------------- #
# prepare branch prefix
# --------------------------------------------------------------------------- #

$SCRIPT_PATH/utils/prepare-prefix.bash
BACKUP_BRANCH_WAS_SET=$?
if [[ BACKUP_BRANCH_WAS_SET = 3 ]]; then
	exit 0
fi

# --------------------------------------------------------------------------- #
# run main commands with the most significant argument
# --------------------------------------------------------------------------- #

case $1 in
	"")
		$SCRIPT_PATH/features/usage.bash
		;;
	create)
		$SCRIPT_PATH/features/create.bash $@
		;;
	ls)
		$SCRIPT_PATH/features/ls.bash $@
		;;
	push)
		$SCRIPT_PATH/features/push.bash $@
		;;
	fetch)
		$SCRIPT_PATH/features/fetch.bash $@
		;;
	restore)
		$SCRIPT_PATH/features/restore.bash $@
		;;
	delete)
		$SCRIPT_PATH/features/delete.bash $@
		;;
	*)
		echo "bad command $1"
		$SCRIPT_PATH/features/usage.bash
		;;
esac
