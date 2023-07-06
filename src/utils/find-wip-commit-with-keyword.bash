#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Resolve given KEY to TAG_NAME
# ---------------------------------------------------------------------------- #

# Input
KEY=$1

# Output
TAG_NAME=""
FULL_HASH=""
PREFIX=$(git config --get jan9won.git-wip-commit.prefix)
TAG_PATTERN="^$PREFIX/([0-9]{10,})/([a-zA-Z0-9]{40})$"

# Get FULL_HASH with KEY (when KEY is a unique part of hash, or a full tag name)
if read -r FULL_HASH < <(git rev-parse --quiet --verify "$KEY"); then

  # Get tag name from the FULL_HASH
  read -r TAG_NAME < <(git tag --contains "$FULL_HASH")
  
  # Check if TAG_NAME is in WIP format
  if [[ ! $TAG_NAME =~ $TAG_PATTERN ]]; then
    printf '%s is not a WIP commit' "$TAG_NAME"
    exit 1
  fi

  printf '%s' "$TAG_NAME"
  exit 0

# If Given KEY doesn't match anything, exit with error
else
  printf '%s does not match any tag name (exact) or commit hash (short/full)\n' "$KEY"
  exit 1
fi

