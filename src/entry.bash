#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Get path of the directory this script is included
# ---------------------------------------------------------------------------- #

get_script_path () {
  local SOURCE
  local SCRIPT_PATH
  SOURCE=${BASH_SOURCE[0]}
  # resolve $SOURCE until the file is no longer a symlink
  while [ -L "$SOURCE" ]; do 
    SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
    SOURCE=$(readlink "$SOURCE")
    # if $SOURCE was a relative symlink, resolve it relative to it
    [[ $SOURCE != /* ]] && SOURCE=$SCRIPT_PATH/$SOURCE 
  done
  SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  echo "$SCRIPT_PATH"
}

SCRIPT_PATH=$(get_script_path)
PREPARE_REMOTE_PATH=$(readlink -f "$SCRIPT_PATH/utils/prepare-remote.bash")
SCRIPT_PATH=$(get_script_path)

# --------------------------------------------------------------------------- #
# Entry Check 1: if called inside a git repository
# --------------------------------------------------------------------------- #

IS_GIT_REPO=$(git rev-parse --is-inside-work-tree 2>/dev/null)

if [[ $IS_GIT_REPO != "true" ]]; then
	printf "[Error] Not a git repository.\n"
  "$SCRIPT_PATH/features/usage.bash"
	exit 1
fi

# --------------------------------------------------------------------------- #
# Entry Check 2: if tag prefix is ready
# --------------------------------------------------------------------------- #

if ! "$SCRIPT_PATH/utils/prepare-prefix.bash"; then
	exit 1
fi

# --------------------------------------------------------------------------- #
# Handle highest order argument
# --------------------------------------------------------------------------- #

COMMAND=""
COMMAND_PATH=""
ARGUMENTS=()
REMOTE_NAME=""
VERBOSE_OPTION="false"

if [[ "$#" -eq 0 ]]; then
  printf 'No command is given\n'
  printf 'Usage: git wip <command> [<args>]\n'
  exit 1
fi

while [[ "$#" -gt 0 ]]; do
	case $1 in
    help)
      COMMAND="$1"
			COMMAND_PATH="$SCRIPT_PATH/features/usage.bash"
      shift
      ;;
		create)
      COMMAND="$1"
			COMMAND_PATH="$SCRIPT_PATH/features/create.bash"
      shift;
			;;
		ls)
      COMMAND="$1"
			COMMAND_PATH="$SCRIPT_PATH/features/ls.bash" 
      shift;
			;;
		ls-remote)
      COMMAND="$1"
			COMMAND_PATH="$SCRIPT_PATH/features/ls-remote.bash" 
      shift;
			;;
		restore)
      COMMAND="$1"
			COMMAND_PATH="$SCRIPT_PATH/features/restore.bash" 
      shift;
      ;;
		delete)
      COMMAND="$1"
			COMMAND_PATH="$SCRIPT_PATH/features/delete.bash" 
      shift;
      ;;
    remote)
      COMMAND="$1"
      COMMAND_PATH="$SCRIPT_PATH/features/remote.bash" 
      shift;
      REMOTE_NAME="$1"
      ARGUMENTS+=("$1")
      shift;
      ;;
    --remote=*)
      if [[ "$REMOTE_NAME" != "" ]];then
        printf '[Warn] option --remote is given multiple times, only the last one will be used.\n'
      fi
      if [[ "$1" =~ ^--remote=(.{1,})$ ]]; then
        REMOTE_NAME="${BASH_REMATCH[1]}"
      else
        printf 'Remote name is not given\n'
        exit 1
      fi
      ARGUMENTS+=("$1")
      shift
      ;;
    -v|--verbose)
      VERBOSE_OPTION="true"
      ARGUMENTS+=("$1")
      shift
      ;;
		*)
      if [[ "$1" != "" ]]; then
        ARGUMENTS+=("$1")
      fi
      shift;
			;;
	esac
done

# ---------------------------------------------------------------------------- #
# Filter bad commands
# ---------------------------------------------------------------------------- #

if [[ "$COMMAND" == "" ]]; then
  printf 'Illegal command %s\n' "${ARGUMENTS[0]}"
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Prepare remote
# ---------------------------------------------------------------------------- #

if [[ "$REMOTE_NAME" != "" ]]; then
  PREPARE_REMOTE_ARGUMENTS=("$REMOTE_NAME")
fi

if [[ "$VERBOSE_OPTION" == "true" ]]; then
  PREPARE_REMOTE_ARGUMENTS+=("--verbose")
fi

if ! eval "$PREPARE_REMOTE_PATH ${PREPARE_REMOTE_ARGUMENTS[*]}"; then
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Call command script
# ---------------------------------------------------------------------------- #

if ! eval "$COMMAND_PATH ${ARGUMENTS[*]}"; then
  exit 1
fi

