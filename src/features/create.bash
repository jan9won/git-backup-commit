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
#
FORCE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    help)
			"$SCRIPT_PATH/usage.bash" "create"
      exit 0
      ;;
    -f|--force)
      FORCE=true
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

# --------------------------------------------------------------------------- #
# Cleanup Functions
# --------------------------------------------------------------------------- #

cleanup_restore_newly_added_files()
{
  printf 'Restoring files staged by this command...'
  if ! git restore --staged "${ADDED_FILES[*]}"; then
    printf 'Failed to restore files staged by git wip create.\nFile list:\n%s\n' "${ADDED_FILES[*]}"
    exit 1
  fi
  printf 'OK'
}

cleanup_delete_temp_branch()
{
  printf 'Deleting the temporary branch created by this command...\n'
  if ! git branch -D "$TEMP_BRANCH_NAME"; then
    printf 'Failed to delete the temporary branch used to create WIP commit\n'
    if [[ "$TEMP_BRANCH_NAME" = "" ]]; then
      printf 'Temporary branch name is empty\n'
    else
      printf 'Temporary branch name is %s\n' "$TEMP_BRANCH_NAME"
    fi
  fi
}

cleanup_checkout_previous_commit()
{
  printf 'Checking out the previous commit...'
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
  printf 'OK\n'
}

cleanup_restore_all_and_add_files_staged_before()
{
  printf 'Restoring from temporary branch %s...' "$TEMP_BRANCH_NAME"
  if ! git restore --source "$TEMP_BRANCH_NAME" .;then
    printf 'Failed to restore the original state of working tree\n'
    exit 1
  fi
  printf 'OK\n'

  printf 'Adding staged files before this command...'
  if [[ "${#STAGED_FILES_BEFORE[@]}" -gt 0 ]]; then
    if ! git add "${STAGED_FILES_BEFORE[@]}" ; then
      printf 'Failed to restore the original state of staging area\n'
      exit 1 
    fi
  fi
  printf 'OK\n'
}

# ---------------------------------------------------------------------------- #
# Get prefix
# ---------------------------------------------------------------------------- #

PREFIX=$(git config --get jan9won.git-wip-commit.prefix)

# ---------------------------------------------------------------------------- #
# Check if currently checked out on branch or HEAD is detached
# ---------------------------------------------------------------------------- #

if git symbolic-ref -q HEAD; then
  WAS_ON_BRANCH=true
  BRANCH_NAME_BEFORE="$(git branch --show-current)"
else
  WAS_ON_BRANCH=false
  COMMIT_HASH_BEFORE="$(git rev-parse HEAD)"
fi

# ---------------------------------------------------------------------------- #
# Check if currently checked out on another wip branch
# ---------------------------------------------------------------------------- #

if git show-ref --tags | grep "$(git rev-parse HEAD)" | sed 's|.*/tags/||' | grep "$PREFIX*"; then
  printf "You're currently on another wip commit tagged with name above.\n" 
  printf "You can't create another wip commit on a wip commit.\n"
  exit 1
fi 

# --------------------------------------------------------------------------- #
# Check if there's any change to commit
# --------------------------------------------------------------------------- #

if git status --porcelain | grep -q '^.\{2\}'; then
  HAS_CHANGES_TO_COMMIT=true
else
  HAS_CHANGES_TO_COMMIT=false
fi

# If no changes to commit, or --force is not set, exit
if [[ $HAS_CHANGES_TO_COMMIT = false && $FORCE = false ]]; then
  printf 'There are no changes to commit.\n'
  printf 'Use option "--force" to create empty one.\n'
	exit 0
fi  

# --------------------------------------------------------------------------- #
# Action 1 : Create temporary branch and switch to it
# --------------------------------------------------------------------------- #

# If create branch failed, exit
TEMP_BRANCH_NAME="$PREFIX/temp/$(date +%s)"

printf 'Switching to the temporary branch %s...' "$TEMP_BRANCH_NAME"
if ! git switch -q -c "$TEMP_BRANCH_NAME"; then
	printf 'Git switch failed it exit code'
	exit 1;
fi
printf 'OK\n'

# --------------------------------------------------------------------------- #
# Action 2 : Add everything, store which files were on staging area on which stage
# --------------------------------------------------------------------------- #

# Grab files in the staging area before this command
# readarray -t STAGED_FILES_BEFORE < <(git diff --name-only --cached --diff-filter=ACMR HEAD)
readarray -t STAGED_FILES_BEFORE < <(git diff --name-only --cached HEAD)

if [[ $HAS_CHANGES_TO_COMMIT = true ]]; then
    
  printf 'Adding every changes to the staging area...'
  # If add failed, clean up
  if ! git add .; then
    printf 'Git add failed. Cleaning up...\n'
    cleanup_delete_temp_branch
    exit 1;
  fi
  printf 'OK\n'

  # Grab files in the staging area after adding 
  # readarray -t STAGED_FILES_AFTER < <(git diff --name-only --cached --diff-filter=ACMR HEAD)
  readarray -t STAGED_FILES_AFTER < <(git diff --name-only --cached HEAD)

  # List files that were newly added by this command
  ADDED_FILES=()
  for after in "${STAGED_FILES_AFTER[@]}"
  do
    for before in "${STAGED_FILES_BEFORE[@]}"
    do
      if [[ "$after" = "$before" ]]; then
        continue 2
      fi
    done
    ADDED_FILES+=("$after")
  done

fi

# --------------------------------------------------------------------------- #
# Action 3 : Create a commit
# --------------------------------------------------------------------------- #

COMMIT_MESSAGE="WIP Commit

This is a commit created by jan9won/git-wip-command library.
It's recommended not to interact with this commit directly, but rather use the library.
"

printf 'Creating a commit...'
# If commit failed, clean up 
if ! git commit --allow-empty -m "$COMMIT_MESSAGE" &> /dev/null; then
  printf 'Commit failed. Cleaning up...\n'
  cleanup_checkout_previous_commit
  cleanup_restore_newly_added_files
  cleanup_delete_temp_branch
	exit 1;
fi
printf 'OK\n'

# --------------------------------------------------------------------------- #
# Action 4 : Create a Tag
# --------------------------------------------------------------------------- #

COMMIT_HASH="$(git rev-parse HEAD)"
COMMIT_TIMESTAMP=$(git show -s --format=%at "$COMMIT_HASH")
TAG_NAME="$PREFIX/$COMMIT_TIMESTAMP/$COMMIT_HASH"
TEMP_FILE_NAME="git-wip-commit-temp-$COMMIT_HASH-$COMMIT_TIMESTAMP"

cleanup_procedure_create_tag(){
  cleanup_checkout_previous_commit
  cleanup_restore_all_and_add_files_staged_before
  cleanup_delete_temp_branch
}

printf 'Creating a temporary file to write tag message...'
if ! touch "$TEMP_FILE_NAME"; then
  printf 'Failed to create file. Cleaning up...\n'
  cleanup_procedure_create_tag
  exit 1
fi
printf 'OK\n'

printf 'Writing a list of newly added files to the temporary file...'
added_files_newline_separated=$(printf '%s\n' "${ADDED_FILES[@]}")
if ! printf 'This is a WIP tag created with git-wip-commit library\n\n%s' "$added_files_newline_separated" > "$TEMP_FILE_NAME"; then
  printf 'Failed while writing to the file. Cleaning up...\n'
  cleanup_procedure_create_tag
  exit 1
fi
printf 'OK\n'

printf 'Creating a tag...'
if ! git tag -a "$TAG_NAME" -F "$TEMP_FILE_NAME"; then
  printf 'Create tag failed. Cleaning up...\n' 
  cleanup_procedure_create_tag
  exit 1
fi
printf 'OK\n'

printf 'Deleting the temporary file...'
if ! rm "$TEMP_FILE_NAME"; then
  printf 'Failed while deleting the file. Cleaning up...\n'
  cleanup_procedure_create_tag
  exit 1
fi
printf 'OK\n'

# --------------------------------------------------------------------------- #
# Action 5 : Restore to original state of working tree and staging area
# --------------------------------------------------------------------------- #

cleanup_checkout_previous_commit
cleanup_restore_all_and_add_files_staged_before
cleanup_delete_temp_branch

printf 'Created a WIP commit and restored working and staging area\nTag name: %s\n' "$TAG_NAME"
exit 0
