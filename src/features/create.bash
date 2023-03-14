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

FORCE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
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

# ---------------------------------------------------------------------------- #
# Get prefix
# ---------------------------------------------------------------------------- #

PREFIX=$(git config --get jan9won.git-wip-commit.prefix)

# --------------------------------------------------------------------------- #
# Check if there's any change to commit
# --------------------------------------------------------------------------- #

git status --porcelain | grep -q '^.\{2\}'; 
HAS_CHANGES_TO_COMMIT=$?

# If no changes to commit, exit
if [[ $HAS_CHANGES_TO_COMMIT -ne 0 ]]; then
  printf 'There are no changes to add or commit.\n'
  printf 'You can use --force to create empty one.\n'
	exit 0
fi  

# --------------------------------------------------------------------------- #
# Create temporary branch and switch to it
# --------------------------------------------------------------------------- #

TEMP_BRANCH_NAME="$PREFIX/temp/$(date +%s)"

git switch -c "$TEMP_BRANCH_NAME";
SWITCH_SUCCESS=$?

# If create branch failed, exit
if [[ $SWITCH_SUCCESS -ne 0 ]]; then
	echo "git switch failed";
	exit 1;
fi

# --------------------------------------------------------------------------- #
# Add everything, store which files were added by this command
# --------------------------------------------------------------------------- #

# Grab files in the staging area before adding
readarray -t STAGED_FILES_BEFORE < <(git diff --name-only --cached --diff-filter=ACMR HEAD)

# Add everything
git add .;
ADD_SUCCESS=$?

# If add failed, clean up
if [[ $ADD_SUCCESS -ne 0 ]]; then
	echo "git add failed";
	git switch -;
  git branch -D "$TEMP_BRANCH_NAME"
	exit 1;
fi

# Grab files in the staging area after adding 
readarray -t STAGED_FILES_AFTER < <(git diff --name-only --cached --diff-filter=ACMR HEAD)

ADDED_FILES=()

# List files that were newly added by this command
for added_file_after in "${STAGED_FILES_AFTER[@]}"
do
  for added_file_before in "${STAGED_FILES_BEFORE[@]}"
  do
    if [[ "$added_file_after" = "$added_file_before" ]]; then
      break 1
    else
      ADDED_FILES+=("$added_file_after")
    fi
  done
done

# --------------------------------------------------------------------------- #
# Commit everything
# --------------------------------------------------------------------------- #

git commit -m "This is a temporary branch used by jan9won/git-wip-command library.\nYou shouldn't be seeing this message if it worked correctly.\nFeel free to delete, and consider reporting to the developer.\n" &> /dev/null
COMMIT_SUCCESS=$?

# If commit failed, clean up (delete branch, reset newly added files)
if [[ $COMMIT_SUCCESS -ne 0 ]]; then
  printf 'Commit failed with exit code %s\n' "$COMMIT_SUCCESS"
	git switch -;
  git branch -D "$TEMP_BRANCH_NAME"
  git reset "${ADDED_FILES[@]}"
	exit 1;
fi

# --------------------------------------------------------------------------- #
# Create Tag
# --------------------------------------------------------------------------- #

COMMIT_HASH="$(git rev-parse HEAD)"
COMMIT_TIMESTAMP=$(git show -s --format=%at "$COMMIT_HASH")

git tag "$PREFIX/$COMMIT_HASH-$COMMIT_TIMESTAMP"
TAG_SUCCESS=$?

# If tag failed, clean up (restore commit, delete branch, reset added files)
if [[ $TAG_SUCCESS -ne 0 ]]; then
  printf 'Create tag failed\n'
fi
 
# --------------------------------------------------------------------------- #
# Restore working tree and staging area, delete temporary branch
# --------------------------------------------------------------------------- #

git switch -;
git restore --source "$TEMP_BRANCH_NAME" .;
git reset "${STAGED_FILES_BEFORE[@]}"
git branch -D "$TEMP_BRANCH_NAME"

