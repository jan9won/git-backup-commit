#!/usr/bin/env bash

[[ $BASH_VERSION =~ ([0-9]{1,}\.[0-9]{1,}\.[0-9]{1,}) ]]
IFS='.' read -r -a BASH_VER <<< "${BASH_REMATCH[1]}"

# MAJOR=4
MAJOR=4
MINOR=3
PATCH=0

if [[
  ${BASH_VER[0]} -lt $MAJOR ||
  (
    ${BASH_VER[0]} -eq $MAJOR &&
    ${BASH_VER[1]} -lt $MINOR
  ) ||
  (
    ${BASH_VER[0]} -eq $MAJOR &&
    ${BASH_VER[1]} -eq $MINOR &&
    ${BASH_VER[2]} -lt $PATCH
  )
]]; then
  printf 'Bash version %d.%d.%d or later is required.\n' "$MAJOR" "$MINOR" "$PATCH"
  printf 'Your current version is %d.%d.%d\n' "${BASH_VER[0]}" "${BASH_VER[1]}" "${BASH_VER[2]}"
  exit 1
fi
