#!/usr/bin/env bash

PORCELAIN=false
SHOW_COMMONS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --porcelain)
      PORCELAIN=true
      shift
      ;;
    --show-commons)
      SHOW_COMMONS=true
      shif
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
LS_PATH=$(readlink -f "$SCRIPT_PATH/ls.bash")

# ---------------------------------------------------------------------------- #
# Compare remote WIP tags with local WIP tags
# ---------------------------------------------------------------------------- #

if REMOTE_WIP_TAGS_STRING=$("$LS_PATH" "--remote=$REMOTE_NAME" "--format=short"); then
  readarray -t REMOTE_WIP_TAGS <<< "$REMOTE_WIP_TAGS_STRING"
else
  exit 1
fi

if LOCAL_WIP_TAGS_STRING=$("$LS_PATH" "--format=short"); then
  readarray -t LOCAL_WIP_TAGS <<< "$LOCAL_WIP_TAGS_STRING"
else
  exit 1
fi

# echo "${REMOTE_WIP_TAGS[@]}"
# echo "${LOCAL_WIP_TAGS[@]}"

COMMON_ITEMS=()

for (( local_idx="${#LOCAL_WIP_TAGS[@]}"-1; local_idx>=0; local_idx-- )); do
  local_tag="${LOCAL_WIP_TAGS[$local_idx]}"

  for (( remote_idx="${#REMOTE_WIP_TAGS[@]}"; remote_idx>=0; remote_idx-- )); do
    remote_tag="${REMOTE_WIP_TAGS[$remote_idx]}"

    if [[ "$local_tag" == "$remote_tag" ]]; then
      unset "LOCAL_WIP_TAGS[$local_idx]"
      unset "REMOTE_WIP_TAGS[$remote_idx]"
      COMMON_ITEMS+=("$local_tag")
      continue 2
    fi
  done
done

# remove gaps from arrays
LOCAL_WIP_TAGS=("${LOCAL_WIP_TAGS[@]}")
REMOTE_WIP_TAGS=("${REMOTE_WIP_TAGS[@]}")

if $PORCELAIN; then
  printf '%s\n' "${LOCAL_WIP_TAGS[*]}"
  printf '%s\n' "${REMOTE_WIP_TAGS[*]}"
  printf '%s\n' "${COMMON_ITEMS[*]}"
else
  printf 'WIP tags that are unique to this local repository:\n'
  if [[ "${#LOCAL_WIP_TAGS[@]}" -gt 0 ]]; then
    printf '%s\n' "${LOCAL_WIP_TAGS[@]}"
  else
    printf '(none)\n'
  fi

  printf '\nWIP tags that are unique to the given remote repository:\n'
  if [[ "${#REMOTE_WIP_TAGS[@]}" -gt 0 ]]; then
    printf '%s\n' "${REMOTE_WIP_TAGS[@]}"
  else
    printf '(none)\n'
  fi

  if $SHOW_COMMONS; then
    printf '\nWIP tags that are common between local and remote repository:\n'
    if [[ "${#COMMON_ITEMS[@]}" -gt 0 ]]; then
      printf '%s\n' "${COMMON_ITEMS[@]}"
    else
      printf '(none)\n'
    fi
  fi
fi

