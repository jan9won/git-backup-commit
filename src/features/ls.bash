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
VERIFY_TIMESTAMP=$(readlink -f "$SCRIPT_PATH/../utils/verify-timestamp.bash")
USAGE_PATH=$(readlink -f "$SCRIPT_PATH/usage.bash")
FIND_WIP_COMMIT_WITH_KEYWORD=$(readlink -f "$SCRIPT_PATH/../utils/find-wip-commit-with-keyword.bash")

# ---------------------------------------------------------------------------- #
# Argument parsing
# ---------------------------------------------------------------------------- #

VERBOSE=false
TIME_BEFORE=""
TIME_AFTER=""
FORMAT="long"
REMOTE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    help)
			"$USAGE_PATH" "ls"
      exit 0
      ;;

    -v|--verbose)
      VERBOSE=true
      shift
      ;;

    --remote=*)
      [[ "$1" =~ ^--remote=(.{1,})$ ]]
      REMOTE="${BASH_REMATCH[1]}"
      shift
      ;;

    --before=*|--after=*)

      [[ "$1" =~ ^--(before|after)=([0-9]{1,})$ ]]

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

    --format=*)
      [[ "$1" =~ ^--format=(short|long|status)$ ]]
      FORMAT="${BASH_REMATCH[1]}"
      shift
      ;;

    -*)
      printf 'Illegal option %s\n' "$1"
      exit 1
      ;;

    *)
      if [[ "$1" != "" ]]; then
        KEYWORD_LIST+=("$1")
      fi
      shift
      ;;

  esac
done

if [[ "$REMOTE" != "" && "$FORMAT" == "status" ]]; then
  printf '[Error] option --status cannot be used with --remote. Please consider fetching them and read them locally.\n' 
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Find all WIP tags according to given arguments
# ---------------------------------------------------------------------------- #

PREFIX=$(git config --get jan9won.git-wip-commit.prefix)
WIP_TAGS=()

# Local

if [[ "$REMOTE" == "" ]]; then

  # With Keyword(s)
  if [[ "${#KEYWORD_LIST[@]}" -gt 0 ]]; then
    for keyword in "${KEYWORD_LIST[@]}"; do
      # Resolve given keyword to tag name 
      $VERBOSE && printf 'Searching for the WIP commit with the given arguments %s\n' "$keyword"
      if tag_name=$($FIND_WIP_COMMIT_WITH_KEYWORD "$keyword") ; then
        $VERBOSE && printf 'Found %s\n' "$tag_name"
        WIP_TAGS+=("$tag_name")
      else
        printf 'Could not find WIP commit with keyword %s\n' "$keyword"
      fi
    done

  # Without Keyword (All Local)
  else
    readarray -t WIP_TAGS < <(git tag --sort=refname | grep -E "^$PREFIX/[0-9]{10,}/[a-zA-Z0-9]{40}$")
  fi
fi

# Remote

if [[ "$REMOTE" != "" ]]; then

  # All Remote with Prefix
  $VERBOSE && printf 'Querying all remote tags prefixed with locally configured prefix %s\n' "$PREFIX"
  readarray -t REMOTE_TAGS_WITH_PREFIX < <(git ls-remote "$REMOTE" refs/tags/"$PREFIX"/* | grep -v "\^{}")
  for remote_object in "${REMOTE_TAGS_WITH_PREFIX[@]}"; do

    # All Remote with WIP Tag Pattern 
    if [[ "$remote_object" =~ refs/tags/($PREFIX/([0-9]{10,})/([a-zA-Z0-9]{40}))$ ]]; then

      # Extract data from tag  
      remote_tag="${BASH_REMATCH[1]}"
      remote_tag_timestamp="${BASH_REMATCH[2]}"
      remote_tag_full_hash="${BASH_REMATCH[3]}"

      # Without Keywords (All Remote WIP Tags)
      if [[ "${#KEYWORD_LIST[@]}" -eq 0 ]]; then
        WIP_TAGS+=("$remote_tag")

      # With Keywords
      else
        for keyword in "${KEYWORD_LIST[@]}"; do
          
          # Match Full Tag Name
          if [[ "$keyword" == "$remote_tag" ]]; then
            WIP_TAGS+=("$remote_tag")
          fi

          # Match Short/Long Commit Hash
          keyword_hash_pattern="^$keyword\[a-z0-9\]\{0,33\}$"
          if [[ "$remote_tag_full_hash" =~ $keyword_hash_pattern ]]; then
            WIP_TAGS+=("$remote_tag")
          fi
        done
      fi
    fi
  done
fi

if [[ "${#WIP_TAGS[@]}" -eq 0 ]]; then
  printf 'Could not find WIP tags with given parameter(s)\n'
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Filter and print
# ---------------------------------------------------------------------------- #

for tag in "${WIP_TAGS[@]}"; do

  # Get timestamp and commit hash from tag name

  IFS='/' read -r -a tag_splitted <<< "$tag"
  COMMIT_TIMESTAMP=${tag_splitted[1]}
  TIME_STRING=$(date -r "$COMMIT_TIMESTAMP" "+%x %A %X")
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

  # Formatted printing

  if [[ $FORMAT == "short" ]]; then
    printf '%s\n' "$tag"

  elif [[ $FORMAT == "long" ]]; then
    printf 'tag\t%s\ndate\t%s\nhash\t%s\n\n' "$tag" "$TIME_STRING" "$COMMIT_HASH"

  elif [[ $FORMAT == "status" ]]; then
    readarray -t committed_files < <(git show --name-status --pretty= "$COMMIT_HASH")
    readarray -t newly_added_files < <(git tag --list --format='%(body)' "$tag")

    file_list_string=""

    for committed_file in "${committed_files[@]}"; do
      readarray -d $'\t' -t committed_file_pair < <(printf '%s' "$committed_file")
      commit_type="${committed_file_pair[0]}"
      committed_file_name="${committed_file_pair[1]}"
      for newly_added_file in "${newly_added_files[@]}"; do
        if [[ "$committed_file_name" == "$newly_added_file" ]]; then
          file_list_string+="$commit_type"
          file_list_string+="+"
          file_list_string+=$'\t'
          file_list_string+="$committed_file_name"
          file_list_string+=$'\n'
          continue 2 
        fi
      done
      file_list_string+="$commit_type"
      file_list_string+=$' \t'
      file_list_string+="$committed_file_name"
      file_list_string+=$'\n'
    done

    printf 'name\t%s\ndate\t%s\nhash\t%s\n%s\n' "$tag" "$TIME_STRING" "$COMMIT_HASH" "$file_list_string"
  else
    printf 'Illegal value for --format option\n'
    exit 1
  fi

done

