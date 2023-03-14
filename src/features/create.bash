#!/usr/bin/env bash

# --------------------------------------------------------------------------- #
# Create a new branch named <prefix>/<timestamp>
# --------------------------------------------------------------------------- #

BACKUP_BRANCH_NAME=backup/$(date +%s);
HAS_CHANGES=1;
SWITCH_STATUS=1;
ADD_STATUS=1;
COMMIT_STATUS=1;

# --------------------------------------------------------------------------- #
# Add & Commit Everything
# --------------------------------------------------------------------------- #
if git status --porcelain | grep -q '^.\{2\}'; then
  HAS_CHANGES=0;
fi

if [ $HAS_CHANGES -eq 1 ]; then
  echo "There are no changes to add or commit. Use --force to create empty one."
	exit 0
fi

git switch -c "$BACKUP_BRANCH_NAME";
SWITCH_STATUS=$?
if [ $SWITCH_STATUS -ne 0 ]; then
	echo "git switch failed";
	exit 1;
fi

git add .;
ADD_STATUS=$?
if [ $ADD_STATUS -ne 0 ]; then
	echo "git add failed";
	git switch -;
	exit 1;
fi

git commit -m "$BACKUP_BRANCH_NAME" &> /dev/null
COMMIT_STATUS=$?
if [ $COMMIT_STATUS -ne 0 ]; then
	echo "git commit failed";
	ADDED_FILES=($(git diff --name-only --cached --diff-filter=ACMR HEAD))
	git reset $ADDED_FILES
	git switch -;
	exit 1;
fi


# --------------------------------------------------------------------------- #
# restore working tree and staged area
# --------------------------------------------------------------------------- #

git switch -;
git restore --source "$BACKUP_BRANCH_NAME" .;
