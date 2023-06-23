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

WIP_TAG_BEFORE=$(git tag --contains HEAD | grep "$PREFIX")

if [[ $WIP_TAG_BEFORE != "" ]]; then
  printf "You're currently on another wip commit \"%s\".\n" "$WIP_TAG_BEFORE"
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

# If no changes to commit, exit
if [[ $HAS_CHANGES_TO_COMMIT = false && $FORCE = false ]]; then
  printf 'There are no changes to commit.\n'
  printf 'Use option "--force" to create empty one.\n'
	exit 0
fi  

# --------------------------------------------------------------------------- #
# Create temporary branch and switch to it
# --------------------------------------------------------------------------- #

# If create branch failed, exit
if ! git switch -c "$PREFIX/temp/$(date +%s)"; then
	echo "Git switch failed it exit code $SWITCH_SUCCESS";
	exit 1;
fi

# --------------------------------------------------------------------------- #
# Add everything, store which files were added by this command
# --------------------------------------------------------------------------- #

# Grab files in the staging area before adding
readarray -t STAGED_FILES_BEFORE < <(git diff --name-only --cached --diff-filter=ACMR HEAD)

if [[ $HAS_CHANGES_TO_COMMIT = true ]]; then
    
  # If add failed, clean up
  if ! git add .; then
    echo "git add failed";
    if [[ $WAS_ON_BRANCH = true ]]; then
      git switch "$BRANCH_NAME_BEFORE"
    else
      git checkout "$COMMIT_HASH_BEFORE"
    fi
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

fi

# --------------------------------------------------------------------------- #
# Commit everything
# --------------------------------------------------------------------------- #

COMMIT_MESSAGE="
This is a temporary branch used by jan9won/git-wip-command library.
You shouldn't be seeing this message if it worked correctly.
Feel free to delete, and consider reporting to the developer.
"

# If commit failed, clean up 
if ! git commit --allow-empty -m "$COMMIT_MESSAGE" &> /dev/null; then
  printf 'Commit failed with exit code %s. Cleaning up...\n' "$COMMIT_SUCCESS"
  if [[ $WAS_ON_BRANCH = true ]]; then
    git switch "$BRANCH_NAME_BEFORE"
  else
    git checkout "$COMMIT_HASH_BEFORE"
  fi
  # reset newly added files
  git reset "${ADDED_FILES[@]}"
  # delete branch
  git branch -D "$TEMP_BRANCH_NAME"
	exit 1;
fi

# --------------------------------------------------------------------------- #
# Create Tag
# --------------------------------------------------------------------------- #

COMMIT_HASH="$(git rev-parse HEAD)"
COMMIT_TIMESTAMP=$(git show -s --format=%at "$COMMIT_HASH")

# If tag failed, clean up (restore commit, delete branch, reset added files)
if ! git tag "$PREFIX/$COMMIT_HASH-$COMMIT_TIMESTAMP"; then
  printf 'Create tag failed with %s. Cleaning up...\n' "$TAG_SUCCESS"
  if [[ $WAS_ON_BRANCH = true ]]; then
    git switch "$BRANCH_NAME_BEFORE"
  else
    git checkout "$COMMIT_HASH_BEFORE"
  fi
  git restore --source "$TEMP_BRANCH_NAME" .;
  git reset "${STAGED_FILES_BEFORE[@]}"
  git branch -D "$TEMP_BRANCH_NAME"
fi
 
# --------------------------------------------------------------------------- #
# Restore working tree and staging area, delete temporary branch
# --------------------------------------------------------------------------- #

if [[ $WAS_ON_BRANCH = true ]]; then
  git switch "$BRANCH_NAME_BEFORE"
else
  git checkout "$COMMIT_HASH_BEFORE"
fi
git restore --source "$TEMP_BRANCH_NAME" .;
git reset "${STAGED_FILES_BEFORE[@]}"
git branch -D "$TEMP_BRANCH_NAME"

