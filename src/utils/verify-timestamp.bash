#!/usr/bin/env bash

# Function to check if a number is an integer
if ! [[ $1 =~ ^[0-9]+$ ]] ; then
  printf '[Error] Not a valid Unix timestamp. Must be an integer.\n'
  exit 1
fi

if (( $1 < 0 )); then
  printf '[Error] Got a minus value. Commit time cannot be before epoch.\n'
  exit 1
fi

exit 0
