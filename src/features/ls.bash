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

# ---------------------------------------------------------------------------- #
# Argument parsing
# ---------------------------------------------------------------------------- #

declare -i time_before
declare -i time_after
format="pretty"

while [[ $# -gt 0 ]]; do
  case $1 in
    help)
			"$SCRIPT_PATH/usage.bash" "ls"
      exit 0
      ;;

    --before=*|--after=*)

      [[ "$1" =~ --(before|after)=([0-9]{1,}) ]]

      verify_timestamp=$(readlink -f "$SCRIPT_PATH/../utils/verify-timestamp.bash")
      if ! $verify_timestamp "${BASH_REMATCH[2]}"; then
        exit 1
      fi

      if [[ "${BASH_REMATCH[1]}" == "before" && ! $time_before ]]; then
        time_before="${BASH_REMATCH[2]}"
      fi

      if [[ "${BASH_REMATCH[1]}" == "after" && ! $time_after ]]; then
        time_after="${BASH_REMATCH[2]}"
      fi

      shift
      ;;

    --format=*)
      [[ "$1" =~ --format=(raw|pretty|long) ]]
      format="${BASH_REMATCH[1]}"
      shift
      ;;

    -*)
      printf 'Illegal option %s\n' "$1"
      exit 1
      ;;

     *)
      printf 'Illegal command %s\n' "$1"
      exit 1
      ;;
  esac
done

# ---------------------------------------------------------------------------- #
# Get tags prefixed with PREFIX
# ---------------------------------------------------------------------------- #

PREFIX=$(git config --get jan9won.git-wip-commit.prefix)
readarray -t tag_list < <(git tag --list "$PREFIX*" --sort=refname)

# ---------------------------------------------------------------------------- #
# Filter and print
# ---------------------------------------------------------------------------- #

for tag in  "${tag_list[@]}"; do

  # Get timestamp and commit hash from tag name

  [[ "$tag" =~ ([0-9]{10,})/([a-zA-Z0-9]{40}) ]]

  timestamp="${BASH_REMATCH[1]}"
  time_string=$(date -r "$timestamp" "+%x %A %X")
  commit_hash="${BASH_REMATCH[2]}"

  # Filter with timestamp

  if [[ $time_before ]]; then
    if [[ $time_before < $timestamp ]]; then
      continue
    fi
  fi

  if [[ $time_after ]]; then
    if [[ $time_after > $timestamp ]]; then
      continue
    fi
  fi

  # Formatted printing

  if [[ $format == "raw" ]]; then
    printf '%s\n\n' "$tag"
  fi

  if [[ $format == "pretty" ]]; then
    printf 'tag\t%s\ndate\t%s\nhash\t%s\n\n' "$tag" "$time_string" "${commit_hash:0:7}"
  fi

  if [[ $format == "long" ]]; then
    readarray -t committed_files < <(git show --name-status --pretty= "$commit_hash")
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

    printf 'name\t%s\ntime\t%s\n%s\n' "$tag" "$time_string" "$file_list_string"
  fi

done

