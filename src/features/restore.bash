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
HELP_PATH=$(readlink -f "$SCRIPT_PATH/usage.bash")

# ---------------------------------------------------------------------------- #
# Parse arguments 
# ---------------------------------------------------------------------------- #

VERBOSE=false
for arg in "$@"; do
  case $arg in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -*)
      printf 'Illegal option %s\n' "$1"
      exit 1
      ;;
  esac
done

if [[ $# -gt 1 ]]; then
  printf 'Too much arguments. Expected 1.\n'
  "$HELP_PATH" "restore"
  exit 1
fi

if [[ $# -eq 0 ]]; then
  printf 'No refname is given.\n'
  "$HELP_PATH" "restore"
  exit 1
fi

KEYWORD=$1
shift

# ---------------------------------------------------------------------------- #
# Check if there are uncommitted changes, if so, warn and abort
# ---------------------------------------------------------------------------- #

if git status --porcelain | grep -q '^.\{2\}'; then
  printf 'Cannot restore from WIP commit because there are uncommitted changes.\n'
  printf 'Please stash or commit them and then retry.\n'
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Resolve given KEYWORD to TAG_NAME
# ---------------------------------------------------------------------------- #

# Prepare arguments for ls.bash
if [[ "$VERBOSE" == "true" ]]; then
  LS_COMMAND_ARGUMENTS+=("--verbose")
fi

LS_COMMAND_ARGUMENTS=("--format=short" "$KEYWORD")

# call ls.bash
if TAG_NAME=$("$LS_PATH" "${LS_COMMAND_ARGUMENTS[@]}"); then
  IFS='/' read -r -a TAG_NAME_ARRAY <<< "$TAG_NAME"
else
  exit 1
fi

PREFIX=${TAG_NAME_ARRAY[0]}
COMMIT_HASH=${TAG_NAME_ARRAY[2]}

# ---------------------------------------------------------------------------- #
# restore from the commit
# ---------------------------------------------------------------------------- #

# check if currently checked out on branch or head is detached

if git symbolic-ref -q head > /dev/null; then
  WAS_ON_BRANCH=true
  BRANCH_NAME_BEFORE="$(git branch --show-current)"
else
  WAS_ON_BRANCH=false
  COMMIT_HASH_BEFORE="$(git rev-parse HEAD)"
fi

# Checkout WIP commit

$VERBOSE && printf 'Checking out the WIP commit...'
if ! git checkout -q "$COMMIT_HASH"; then
  printf 'Git checkout failed. Aborting.\n'
fi
$VERBOSE && printf 'OK\n'

# If create branch failed, exit

TEMP_BRANCH_NAME="$PREFIX/temp/$(date +%s)"
$VERBOSE && printf 'Switching to the temporary branch %s...' "$TEMP_BRANCH_NAME"
if ! git switch -q -c "$TEMP_BRANCH_NAME"; then
	printf 'Git switch -c failed\n'
	exit 1;
fi
$VERBOSE && printf 'OK\n'

# Checkout commit before this command

$VERBOSE && printf 'Checking out the commit you were on...'
if [[ $WAS_ON_BRANCH = true ]]; then
  if ! git switch -q "$BRANCH_NAME_BEFORE"; then
    printf 'Failed to switch to the original branch\n'
    exit 1
  fi
else
  if ! git checkout -q "$COMMIT_HASH_BEFORE"; then
    printf 'Failed to checkout the original commit\n'
    exit 1
  fi
fi
$VERBOSE && printf 'OK\n'

# Restore

$VERBOSE && printf 'Restoring from temporary branch %s...' "$TEMP_BRANCH_NAME"
if ! git restore --source "$TEMP_BRANCH_NAME" .;then
  printf 'Failed to restore the original state of working tree\n'
  exit 1
fi
$VERBOSE && printf 'OK\n'

# Add

$VERBOSE && printf 'Adding files that were originally on the staging area at the time of WIP commit...'
newly_added_files_string=$(git tag --list --format='%(body)' "$TAG_NAME")
newly_added_files=("${newly_added_files_string%$'\n'}")
if [[ "${#newly_added_files[@]}" -gt 0 ]]; then
  $VERBOSE && printf 'Adding staged files...'
  if ! git add "${newly_added_files[@]}" ; then
    printf 'Failed to add the files\n'
    exit 1 
  fi
  $VERBOSE && printf 'OK\n'
fi

# Delete temporary branch

$VERBOSE && printf 'Deleting the temporary branch created by this command...'
if ! git branch -q -D "$TEMP_BRANCH_NAME"; then
  printf 'Failed to delete the temporary branch used to create WIP commit\n'
  if [[ "$TEMP_BRANCH_NAME" = "" ]]; then
    printf 'Temporary branch name is empty\n'
  else
    printf 'Temporary branch name is %s\n' "$TEMP_BRANCH_NAME"
  fi
fi
$VERBOSE && printf 'OK\n'

