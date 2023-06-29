#!/usr/bin/env bash
# echo "restore.bash: $@"

printf 'Restoring from selected commit %s\n' "$SELECTED_COMMIT_HASH"
if ! git restore --source "$SELECTED_COMMIT_HASH" .;then
  printf 'Failed to restore the original state of working tree\n'
  exit 1
fi

printf 'Adding staged files before this command\n'
if [[ "${#STAGED_FILES_BEFORE[@]}" -gt 0 ]]; then
  if ! git add "${STAGED_FILES_BEFORE[@]}" ; then
    printf 'Failed to restore the original state of staging area\n'
    exit 1 
  fi
fi

