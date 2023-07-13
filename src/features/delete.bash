#!/usr/bin/env bash

# git wip delete 
# git push <remote> --delete <tag-name>

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
VERIFY_TIMESTAMP=$(readlink -f "$SCRIPT_PATH/../utils/verify-timestamp.bash")
HELP_PATH=$(readlink -f "$SCRIPT_PATH/usage.bash")
LS_PATH=$(readlink -f "$SCRIPT_PATH/ls.bash")

# ---------------------------------------------------------------------------- #
# Parse arguments
# ---------------------------------------------------------------------------- #

VERBOSE=false
ALL=false
TIME_BEFORE=""
TIME_AFTER=""
KEYWORD_LIST=()

while [[ $# -gt 0 ]]; do
  case $1 in
    help)
      "$HELP_PATH" "delete"
      exit 0
      ;;

    -v|--verbose)
      VERBOSE=true;
      shift
      ;;

    --remote=*)

      if [[ "$REMOTE" != "" ]];then
        continue
      fi

      if [[ "$1" =~ ^--remote=(.{1,})$ ]]; then
        REMOTE="${BASH_REMATCH[1]}"
      else
        printf 'Remote name is not given\n'
        exit 1
      fi

      shift
      ;;

    -a|--all)
      ALL=true
      shift
      ;;

    --before=*|--after=*)

      [[ "$1" =~ --(before|after)=([0-9]{1,}) ]]

      if ! $VERIFY_TIMESTAMP "${BASH_REMATCH[2]}"; then
        exit 1
      else
        timestamp="${BASH_REMATCH[2]}"
      fi

      if [[ "${BASH_REMATCH[1]}" == "before" && ! $TIME_BEFORE ]]; then
        TIME_BEFORE=$timestamp
      fi

      if [[ "${BASH_REMATCH[1]}" == "after" && ! $TIME_AFTER ]]; then
        TIME_AFTER=$timestamp
      fi

      shift
      ;;

    -*)
      printf 'Illegal option %s\n' "$1"
      exit 1
      ;;

    *)
      KEYWORD_LIST+=("$1")
      shift
      ;;

  esac
done

if [[ "$ALL" == "true" && ($TIME_BEFORE != "" || $TIME_AFTER != ""|| "${#KEYWORD_LIST[@]}" -gt 0 ) ]]; then
  printf -- '--all option cannot be used with other contraints (--before, --after and refname)\n'
  exit 1
fi

if [[ "$ALL" == "false" && $TIME_BEFORE == "" && $TIME_AFTER == "" && "${#KEYWORD_LIST[@]}" -eq 0 ]]; then
  printf -- 'At least one filter option or refname should be provided\n'
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Find WIP tags according to given arguments
# ---------------------------------------------------------------------------- #

WIP_TAGS=()
LS_COMMAND_ARGUMENTS=("--format=short")

if [[ "$VERBOSE" == "true" ]]; then
  LS_COMMAND_ARGUMENTS+=("--verbose")
fi

# when remote
if [[ "$REMOTE" != "" ]]; then
  LS_COMMAND_ARGUMENTS+=("--remote=$REMOTE")
fi

# when arguments exist
if [[ "${#KEYWORD_LIST[@]}" -gt 0 ]]; then
  LS_COMMAND_ARGUMENTS+=("${KEYWORD_LIST[@]}")
fi

# with --before 
if [[ "$TIME_BEFORE" != "" ]]; then
  LS_COMMAND_ARGUMENTS+=("--before=$TIME_BEFORE")
fi

# with --after
if [[ "$TIME_AFTER" != "" ]]; then
  LS_COMMAND_ARGUMENTS+=("--after=$TIME_AFTER")
fi

# call ls.bash
if WIP_TAGS_STRING=$("$LS_PATH" "${LS_COMMAND_ARGUMENTS[@]}"); then
  readarray -t WIP_TAGS <<< "$WIP_TAGS_STRING"
else
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Delete tags (one liner)
# ---------------------------------------------------------------------------- #

# Local
if [[ "$REMOTE" == "" ]]; then
  if ! git tag -d "${WIP_TAGS[@]}"; then
    printf '[Error] Failed to delete the tag\n'
    exit 1
  fi
  # # If there are other references left, warn that it won't be gc'ed because of them
  # if [[ "$REMOTE" == "" && ( $(git --no-pager branch --contains "$COMMIT_HASH") != "" || $(git --no-pager tag --contains "$COMMIT_HASH") != "" ) ]]; then
  #   printf '[Warn] Commit %s has other references left, thus it will not be garbage collected\n' "$COMMIT_HASH"
  # fi

# Remote
else
  WIP_TAGS_FILTERED_INTERPOLATED_STRING=$(printf 'tag %s ' "${WIP_TAGS[@]}")
  REMOTE_DELETE_COMMAND="git push $REMOTE --delete $WIP_TAGS_FILTERED_INTERPOLATED_STRING"
  if ! eval "$REMOTE_DELETE_COMMAND"; then
    printf '[Error] Failed to delete the remote tag\n'
  fi
fi

