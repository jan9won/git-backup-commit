#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Parse arguments
# ---------------------------------------------------------------------------- #

VERBOSE=false
PORCELAIN=false
COMMAND=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    --porcelain)
      PORCELAIN=true
      shift
      ;;
    --compare|--push|--fetch|--prune-local|--prune-remote)
      if [[ "$COMMAND" == "" ]]; then
        COMMAND="${1/--/}"
      fi
      shift
      ;;
    -*)
      printf 'Illegal option %s\n' "$1"
      exit 1
      ;;
    *)
      if [[ "$1" != "" ]]; then
        ARGS+=("$1")
      fi
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
COMPARE_REMOTE=$(readlink -f "$SCRIPT_PATH/compare-remote.bash")
LS_PATH=$(readlink -f "$SCRIPT_PATH/ls.bash")

# ---------------------------------------------------------------------------- #
# Get WIP commits that are on local but aren't on remote
# ---------------------------------------------------------------------------- #
#
# if COMPARE_REMOTE_RESULT_STRING=$("$COMPARE_REMOTE" "$REMOTE_NAME"); then
#   readarray -t COMPARE_REMOTE_RESULT_ARRAY <<< "$COMPARE_REMOTE_RESULT_STRING"
#   read -r -a UNIQUE_LOCAL <<< "${COMPARE_REMOTE_RESULT_ARRAY[0]}"
#   read -r -a UNIQUE_REMOTE <<< "${COMPARE_REMOTE_RESULT_ARRAY[1]}"
#   # read -r -a COMMON <<< "${COMPARE_REMOTE_RESULT_ARRAY[2]}"
# else
#   exit 1
# fi

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
UNIQUE_LOCAL=("${LOCAL_WIP_TAGS[@]}")
UNIQUE_REMOTE=("${REMOTE_WIP_TAGS[@]}")
COMMON_ITEMS=("${COMMON_ITEMS[@]}")

# ---------------------------------------------------------------------------- #
# Compare
# ---------------------------------------------------------------------------- #

if [[ "$COMMAND" == "compare" ]]; then
  if $PORCELAIN; then
    printf '%s\n' "${UNIQUE_LOCAL[*]}"
    printf '%s\n' "${UNIQUE_REMOTE[*]}"
    printf '%s\n' "${COMMON_ITEMS[*]}"
  else
    printf 'WIP tags that are unique to this local repository:\n'
    if [[ "${#UNIQUE_LOCAL[@]}" -gt 0 ]]; then
      printf '%s\n' "${UNIQUE_LOCAL[@]}"
    else
      printf '(none)\n'
    fi

    printf '\nWIP tags that are unique to the given remote repository:\n'
    if [[ "${#UNIQUE_REMOTE[@]}" -gt 0 ]]; then
      printf '%s\n' "${UNIQUE_REMOTE[@]}"
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
fi

# ---------------------------------------------------------------------------- #
# Push
# ---------------------------------------------------------------------------- #

if [[ "$COMMAND" == "push" ]]; then
  if [[ "${#UNIQUE_LOCAL[@]}" -gt 0 ]]; then
    UNIQUE_LOCAL_TAG_INTERPOLATED=$(printf 'tag %s ' "${UNIQUE_LOCAL[@]}")
  else
    printf 'Remote %s has all the WIP tags that are locally present' "$REMOTE_NAME"
  fi

  PUSH_COMMAND="git push $REMOTE_NAME $UNIQUE_LOCAL_TAG_INTERPOLATED"
  if ! eval "$PUSH_COMMAND"; then
    printf 'Failed while pushing WIP tags to %s\n' "$REMOTE_NAME"
    exit 1
  fi

  exit 0
fi

# ---------------------------------------------------------------------------- #
# Fetch
# ---------------------------------------------------------------------------- #

if [[ "$COMMAND" == "fetch" ]]; then
  echo
fi

# ---------------------------------------------------------------------------- #
# Prune-Local
# ---------------------------------------------------------------------------- #

if [[ "$COMMAND" == "prune-local" ]]; then
  echo
fi

# ---------------------------------------------------------------------------- #
# Prune-Remote
# ---------------------------------------------------------------------------- #

if [[ "$COMMAND" == "prune-remote" ]]; then
  echo
fi
