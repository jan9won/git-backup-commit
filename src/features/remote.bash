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
LS_PATH=$(readlink -f "$SCRIPT_PATH/ls.bash")
FIND_WIP_COMMIT_WITH_KEYWORD=$(readlink -f "$SCRIPT_PATH/../utils/find-wip-commit-with-keyword.bash")

# ---------------------------------------------------------------------------- #
# Parse arguments
# ---------------------------------------------------------------------------- #

VERBOSE=false
PORCELAIN=false
COMMAND=""
ARGUMENTS=()

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
    -*)
      printf 'Illegal option %s\n' "$1"
      exit 1
      ;;
    *)
      if [[ "$1" != "" ]]; then
        ARGUMENTS+=("$1")
      fi
      shift
      ;;
  esac
done

# Check if Required Arguments Exist
if [[ ${#ARGUMENTS[@]} -lt 2 ]]; then
  printf 'Too few arguments. Expected remote name and remote command\n'
  printf 'Usage: git wip remote <remote name> <remote command>\n'
  exit 1
fi

# Parse Required Arguments (Remote Name, Command)
if [[ ${#ARGUMENTS[@]} -ge 2 ]]; then
  REMOTE_NAME=${ARGUMENTS[0]}
  COMMAND=${ARGUMENTS[1]}
  if [[ ! "$COMMAND" =~ ^(compare|push|fetch|prune-local|prune-remote)$ ]]; then
    printf 'Illegal command %s\n' "$COMMAND"
    exit 1
  fi
fi

# Parse Additional Arguments (Refnames)
if [[ ${#ARGUMENTS[@]} -ge 3 ]]; then
  if [[ "$COMMAND" =~ ^(push|fetch)$ ]]; then
    printf 'Refnames are only valid with push and fetch command\n'
    if [[ "$COMMAND" =~ ^prune-(local|remote)$ ]]; then
      printf 'To delete specific WIP commits, use delete command instead\n'
    fi
    exit 1
  fi
  KEYWORD_LIST=("${ARGUMENTS[@]:2}")
fi

# ---------------------------------------------------------------------------- #
# Compare remote WIP tags with local WIP tags
# ---------------------------------------------------------------------------- #

LS_ARGUMENTS_LOCAL=("--format=short")
LS_ARGUMENTS_REMOTE=("--format=short" "--remote=$REMOTE_NAME")
if [[ "${#KEYWORD_LIST[@]}" -gt 0 ]]; then
  LS_ARGUMENTS_LOCAL+=("${KEYWORD_LIST[@]}")
  LS_ARGUMENTS_REMOTE+=("${KEYWORD_LIST[@]}")
fi

if REMOTE_WIP_TAGS_STRING=$(eval "$LS_PATH ${LS_ARGUMENTS_REMOTE[*]}"); then
  readarray -t REMOTE_WIP_TAGS <<< "$REMOTE_WIP_TAGS_STRING"
else
  REMOTE_WIP_TAGS=()
fi

if LOCAL_WIP_TAGS_STRING=$(eval "$LS_PATH ${LS_ARGUMENTS_LOCAL[*]}"); then
  readarray -t LOCAL_WIP_TAGS <<< "$LOCAL_WIP_TAGS_STRING"
else
  LOCAL_WIP_TAGS=()
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
# Print Comparison Result
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

  exit 0
fi

# ---------------------------------------------------------------------------- #
# Push
# ---------------------------------------------------------------------------- #

if [[ "$COMMAND" == "push" ]]; then

  if [[ "${#UNIQUE_LOCAL[@]}" -gt 0 ]]; then
    UNIQUE_LOCAL_TAG_INTERPOLATED=$(printf 'tag %s ' "${UNIQUE_LOCAL[@]}")
  else
    printf 'Nothing to push\n'
    exit 0
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

  if [[ "${#UNIQUE_REMOTE[@]}" -gt 0 ]]; then
    UNIQUE_REMOTE_TAG_INTERPOLATED=$(printf 'tag %s ' "${UNIQUE_REMOTE[@]}")
  else
    printf 'Nothing to fetch\n'
    exit 0
  fi

  FETCH_COMMAND="git fetch $REMOTE_NAME $UNIQUE_REMOTE_TAG_INTERPOLATED"
  if ! eval "$FETCH_COMMAND"; then
    printf 'Failed while fetching WIP tags to %s\n' "$REMOTE_NAME"
    exit 1
  fi

  exit 0
fi

# ---------------------------------------------------------------------------- #
# Prune-Local
# ---------------------------------------------------------------------------- #

if [[ "$COMMAND" == "prune-local" ]]; then

  if [[ "${#UNIQUE_LOCAL[@]}" -gt 0 ]]; then
    UNIQUE_LOCAL_TAG_INTERPOLATED=$(printf '%s ' "${UNIQUE_LOCAL[@]}")
  else
    printf 'Nothing to prune in the local repository\n'
    exit 0
  fi

  PRUNE_LOCAL_COMMAND="git tag -d $UNIQUE_LOCAL_TAG_INTERPOLATED"
  if ! eval "$PRUNE_LOCAL_COMMAND"; then
    printf 'Failed while deleting locally unique WIP tags\n'
    exit 1
  fi

  exit 0
fi

# ---------------------------------------------------------------------------- #
# Prune-Remote
# ---------------------------------------------------------------------------- #

if [[ "$COMMAND" == "prune-remote" ]]; then

  if [[ "${#UNIQUE_REMOTE[@]}" -gt 0 ]]; then
    UNIQUE_REMOTE_TAG_INTERPOLATED=$(printf 'tag %s ' "${UNIQUE_REMOTE[@]}")
  else
    printf 'Nothing to prune in the remote repository\n'
    exit 0
  fi

  PRUNE_REMOTE_COMMAND="git push --delete $REMOTE_NAME $UNIQUE_REMOTE_TAG_INTERPOLATED"
  if ! eval "$PRUNE_REMOTE_COMMAND"; then
    printf 'Failed while deleting WIP tags in %s\n' "$REMOTE_NAME"
    exit 1
  fi

  exit 0
fi

