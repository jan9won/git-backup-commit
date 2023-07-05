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

# ---------------------------------------------------------------------------- #
# Argument parsing
# ---------------------------------------------------------------------------- #

TIME_BEFORE=""
TIME_AFTER=""
FORMAT="pretty"

while [[ $# -gt 0 ]]; do
  case $1 in
    help)
			"$SCRIPT_PATH/usage.bash" "ls"
      exit 0
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

    --format=*)
      [[ "$1" =~ --format=(raw|pretty|long) ]]
      FORMAT="${BASH_REMATCH[1]}"
      shift
      ;;

    -*)
      printf 'Illegal option %s\n' "$1"
      exit 1
      ;;

  esac
done

HAS_ARGUMENTS=false
if [[ $# -gt 0 ]]; then
  HAS_ARGUMENTS=true
fi

# ---------------------------------------------------------------------------- #
# Get all WIP tags 
# ---------------------------------------------------------------------------- #

PREFIX=$(git config --get jan9won.git-wip-commit.prefix)
TAG_PATTERN="^$PREFIX/[0-9]{10,}/[a-zA-Z0-9]{40}$"
readarray -t WIP_TAGS < <(git tag --sort=refname | grep -E "$TAG_PATTERN")

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

  if [[ $FORMAT == "raw" ]]; then
    printf '%s\n\n' "$tag"
  fi

  if [[ $FORMAT == "pretty" ]]; then
    printf 'tag\t%s\ndate\t%s\nhash\t%s\n\n' "$tag" "$TIME_STRING" "${COMMIT_HASH:0:7}"
  fi

  if [[ $FORMAT == "long" ]]; then
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

    printf 'name\t%s\ntime\t%s\n%s\n' "$tag" "$TIME_STRING" "$file_list_string"
  fi

done

