#!/usr/bin/env bash


# Get current script's absolute path.
# If it's a symlink, it'll be resolved to its source.
# get_script_path_resolve_symlink () {
# 	local SCRIPT_PATH
# 	local SOURCE=$1
# 	while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
# 		SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
# 		SOURCE=$(readlink "$SOURCE")
# 		[[ $SOURCE != /* ]] && SOURCE=$SCRIPT_PATH/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
# 	done
# 	SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
# 	echo "$SCRIPT_PATH"
# }



SOURCE=${BASH_SOURCE[0]}
while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
	SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
	SOURCE=$(readlink "$SOURCE")
	[[ $SOURCE != /* ]] && SOURCE=$SCRIPT_PATH/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )