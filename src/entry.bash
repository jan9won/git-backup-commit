#!/usr/bin/env bash

# --------------------------------------------------------------------------- #
# Get entry script's absolute path
# --------------------------------------------------------------------------- #

get_script_path () {
	local SCRIPT_PATH
	local SOURCE=${BASH_SOURCE[0]}
	while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
		SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
		SOURCE=$(readlink "$SOURCE")
		[[ $SOURCE != /* ]] && SOURCE=$SCRIPT_PATH/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
	printf "$SCRIPT_PATH"
}

SCRIPT_PATH=$(get_script_path)

# --------------------------------------------------------------------------- #
# Check if we're inside a git repository
# --------------------------------------------------------------------------- #

IS_GIT_REPO=$(git rev-parse --is-inside-work-tree 2>/dev/null)

if [[ ! $IS_GIT_REPO = "true" ]]; then
	printf "You're not in a git repository.\n"
	exit 1
fi

# --------------------------------------------------------------------------- #
# Generate Optstring and Replace Long Options
# --------------------------------------------------------------------------- #

OPT_RESULT=($("$SCRIPT_PATH/utils/generate-optstring.bash" "
	-h, --help, false	
	-r, --remote, true
" $@))

# get optstring
OPTSTRING=${OPT_RESULT[0]}

# replaced agruments
OPT_RESULT_ARRAY=("${OPT_RESULT[@]:1}")

# set new arguments
set -- "${OPT_RESULT_ARRAY[@]}"

echo $OPTSTRING
echo $@

# top level options
processed_opts=""
while getopts ":$OPTSTRING" opt
do
	case $opt in
		-h)
			echo "top level help"
			# $SCRIPT_PATH/features/usage.bash $@
			exit 0
			;;
		:)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
		?)
			echo "unknown flag : $opt"
			;;
	esac 
done


MAIN_COMMAND=$1
shift

case $MAIN_COMMAND in
	ls)
		$SCRIPT_PATH/features/ls.bash $@
		;;
	create)
		$SCRIPT_PATH/features/create.bash $@
		;;
	restore)
		$SCRIPT_PATH/features/restore.bash $@
		;;
	prune)
		$SCRIPT_PATH/features/prune.bash $@
		;;
	push)
		$SCRIPT_PATH/features/push.bash $@
		;;
	fetch)
		$SCRIPT_PATH/features/fetch.bash $@
		;;
	*)
		$SCRIPT_PATH/features/usage.bash $@
		;;
esac

# [command option]

# [global option]

