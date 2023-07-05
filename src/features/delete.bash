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
HELP_PATH=$(readlink -f "$SCRIPT_PATH/usage.bash" "delete")
FIND_WIP_COMMIT_WITH_KEYWORD=$(readlink -f "$SCRIPT_PATH/../utils/find-wip-commit-with-keyword.bash")
PREFIX=$(git config --get jan9won.git-wip-commit.prefix)

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
      "$SCRIPT_PATH/usage.bash" "delete"
      exit 0
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
  printf -- 'At least one option or refname should be provided\n'
  "$HELP_PATH"
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Find all WIP tags according to given arguments
# ---------------------------------------------------------------------------- #

TAG_PATTERN="^$PREFIX/([0-9]{10,})/([a-zA-Z0-9]{40})$"
WIP_TAGS=()

if [[ "${#KEYWORD_LIST[@]}" -gt 0 ]]; then

  for keyword in "${KEYWORD_LIST[@]}"; do

    # Resolve given keyword to tag name 
    $VERBOSE && printf 'Searching for the WIP commit with the give argument %s...\n' "$keyword"

    if ! tag_name=$($FIND_WIP_COMMIT_WITH_KEYWORD "$KEY") ; then
      continue
    else
      $VERBOSE && printf 'Found %s\n' "$tag_name"
      WIP_TAGS+=("$tag_name")
    fi

  done
fi

if $ALL ; then
  readarray -t WIP_TAGS < <(git tag --sort=refname | grep -E "$TAG_PATTERN")
fi

if [[ "${#WIP_TAGS[@]}" -eq 0 ]]; then
  printf 'No WIP tags are found\n'
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Filter and delete tags
# ---------------------------------------------------------------------------- #

for tag in "${WIP_TAGS[@]}"; do
  
  IFS='/' read -r -a tag_splitted <<< "$tag"
  PREFIX=${tag_splitted[0]}
  COMMIT_TIMESTAMP=${tag_splitted[1]}
  COMMIT_HASH=${tag_splitted[2]}

  # Filter with timestamp

  if [[ $TIME_BEFORE ]]; then
    if [[ $TIME_BEFORE < $COMMIT_TIMESTAMP ]]; then
      continue
    fi
  fi

  if [[ $TIME_AFTER ]]; then
    if [[ $TIME_AFTER > $COMMIT_TIMESTAMP ]]; then
      continue
    fi
  fi

  # Delete
  
  if ! git tag -d "$tag"; then
    printf 'Failed to delete the tag %s\n' "$tag"
    exit 1
  fi

  # If there are other references left, warn that it won't be gc'ed because of them

  if [[ $(git --no-pager branch --contains "$COMMIT_HASH") != "" || $(git --no-pager tag --contains "$COMMIT_HASH") != "" ]]; then
    printf '[Warn] Commit %s has other references left, thus it will not be garbage collected\n' "$COMMIT_HASH"
  fi

done

