#!/usr/bin/env bash

VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -*)
      printf 'Illegal option %s\n' "$1"
      exit 1
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#ARGS[@]} -gt 1 ]]; then
  printf 'Too many arguments, expected 1\n'
  exit 1
fi

if [[ ${#ARGS[@]} -eq 0 ]]; then
  printf 'Argument is required\n'
  exit 1
fi

if [[ ${#ARGS[@]} -eq 1 ]]; then
  REMOTE_NAME=${ARGS[0]}
  shift
fi

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
USAGE_PATH=$(readlink -f "$SCRIPT_PATH/usage.bash") 
LS_PATH=$(readlink -f "$SCRIPT_PATH/ls.bash")

# ---------------------------------------------------------------------------- #
# Compare remote WIP tags with local WIP tags
# ---------------------------------------------------------------------------- #

REMOTE_PUSH_COMMAND="git push $REMOTE_NAME"
readarray -t REMOTE_WIP_TAGS < <("$LS_PATH" "--remote=$REMOTE_NAME" "--format=short")
readarray -t LOCAL_WIP_TAGS < <("$LS_PATH" "--format=short")

# echo "${REMOTE_WIP_TAGS[@]}"
# echo "${LOCAL_WIP_TAGS[@]}"

for local in "${LOCAL_WIP_TAGS[@]}"; do
  for remote in "${REMOTE_WIP_TAGS[@]}"; do
    if [[ "$local" == "$remote" ]]; then
      continue 2
    fi
  done
  REMOTE_PUSH_COMMAND+=" tag $local"
done


# ---------------------------------------------------------------------------- #
# Delete
# ---------------------------------------------------------------------------- #

if ! $REMOTE_PUSH_COMMAND; then
  exit 1
fi

