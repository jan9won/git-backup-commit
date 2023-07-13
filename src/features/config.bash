#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Parse arguments
# ---------------------------------------------------------------------------- #

# KEY=${!#}
# set -- "${@:1:$#-1}"

VERBOSE=false
GETTER=""
ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    --get)
      GETTER="get"
      shift
      ;;
    --get-all) 
      # set some variables
      GETTER="get-all"
      shift
      ;;
    -*)
      printf 'Illegal option %s\n' "$1"
      exit 1
      ;;
    *)
      if [[ "$1" != "" ]];then
        ARGS+=("$1")
      fi
      shift
     ;;
  esac
done


if [[ ${#ARGS[@]} -eq 0 ]]; then
  if [[ "$GETTER" == "" ]]; then
    printf 'Either getter option or key-value pair is required.\n'
    exit 1
  fi
fi

if [[ ${#ARGS[@]} -eq 1 ]]; then
  if [[ "$GETTER" == "" ]]; then
    printf 'Key value pair is equired to set the config\n'
    exit 1
  fi
  if [[ "$GETTER" == "get" ]]; then
    KEY=${ARGS[0]}
  fi
  if [[ "$GETTER" == "get-all" ]]; then
    printf 'Too many arguments for --get-all option, expected none.\n'
    exit 1
  fi
fi

if [[ ${#ARGS[@]} -eq 2 ]]; then
  if [[ "$GETTER" == "" ]]; then
    KEY=${ARGS[0]}
    VAL=${ARGS[1]}
  fi
  if [[ "$GETTER" == "get" ]]; then
    printf 'Too many arguments for --get option, expected 1.\n'
    exit 1
  fi
  if [[ "$GETTER" == "get-all" ]]; then
    printf 'Too many arguments for --get-all option, expected none.\n'
    exit 1
  fi
fi

if [[ ${#ARGS[@]} -gt 2 ]]; then
  printf 'Too many arguments for config.bash (expected 1 or 2)\n'
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Define valid key-value pairs, verify given key-value
# ---------------------------------------------------------------------------- #

declare -A KEY_VALUE_PATTERN_PAIR=(
  [prefix]='^[a-zA-Z0-9]{2,10}$'
  [remote-timeout]='^[2-9]|10$'
)

if [[ "$KEY" != "" ]]; then
  if [[ "${KEY_VALUE_PATTERN_PAIR[$KEY]}" == "" ]]; then
    printf 'Invalid key %s\n' "$KEY"
    exit 1
  fi
fi

if [[ $VAL != "" ]]; then
  if [[ ! $VAL =~ ${KEY_VALUE_PATTERN_PAIR[$KEY]} ]]; then
    printf 'Invalid value %s for key %s\n' "$VAL" "$KEY"
    printf 'The valid pattern is %s\n' "${KEY_VALUE_PATTERN_PAIR[$KEY]}" 
    exit 1
  fi
fi

# ---------------------------------------------------------------------------- #
# Handle getter options
# ---------------------------------------------------------------------------- #

if [[ "$GETTER" == "get-all" ]]; then
  for key in "${!KEY_VALUE_PATTERN_PAIR[@]}"; do
    query_result=$(git config --get "jan9won.git-wip-commit.$key")
    printf '%s=%s\n' "$key" "$query_result"
  done
  exit 0
fi

if [[ "$GETTER" == "get" ]]; then
  query_result=$(git config --get "jan9won.git-wip-commit.$KEY")
  printf '%s=%s\n' "$KEY" "$query_result"
  exit 0
fi

# ---------------------------------------------------------------------------- #
# Set value on key
# ---------------------------------------------------------------------------- #

if ! git config --replace-all "jan9won.git-wip-commit.$KEY" "$VAL"; then
  printf 'Failed while setting local git config\n'
  exit 1
fi
