# ---------------------------------------------------------------------------- #
# Get path of the directory this script is included
# ---------------------------------------------------------------------------- #
get_script_path () {
  local SOURCE
  local SCRIPT_PATH
  SOURCE=${BASH_SOURCE[0]}
  while [ -L "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
    SOURCE=$(readlink "$SOURCE")
    [[ $SOURCE != /* ]] && SOURCE=$SCRIPT_PATH/$SOURCE # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  done
  SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  echo "$SCRIPT_PATH"
}

SCRIPT_PATH=$(get_script_path)


# --------------------------------------------------------------------------- #
# Check if tag prefix is set in local git config
# --------------------------------------------------------------------------- #
BACKUP_TAG_PREFIX=$(git config --get jan9won.git-wip-commit.prefix)
BACKUP_TAG_WAS_SET=$?

# if not, set it as default
if [[ $BACKUP_TAG_WAS_SET -ne 0 ]]; then
  printf 'Tag prefix is not configured\n'
  printf 'Setting "jan9won.git-wip-commit.prefix" as "wip" in your local git config\n'
  # Make it executable
  if ! git config jan9won.git-wip-commit.prefix wip; then
    printf 'Failed to add value in the local git config.\n'
    printf 'See more in "configuration" section in README\n\n'
    exit 1
  fi
  BACKUP_TAG_PREFIX="wip"
fi

# --------------------------------------------------------------------------- #
# Check if tag prefix has correct pattern, if not, suggest a fixed one 
# --------------------------------------------------------------------------- #
PATTERN="^[a-z0-9][a-z0-9\-]+[a-z0-9]$"

if [[ $BACKUP_TAG_PREFIX =~ $PATTERN ]]; then
  exit 0

else
  BACKUP_TAG_PREFIX_FIXED=$(
    printf '%s' "$BACKUP_TAG_PREFIX"  |
    tr '[:upper:]' '[:lower:]'        | # make lowercase
    sed -r 's/[^a-zA-Z0-9]/-/g'       | # replace illegal characters with "-"
    sed -e 's/--*/-/g'                | # remove duplicate "-"
    sed -e 's/^-//g; s/-$//g'           # remove heading and trailing "-"
  )

  printf '"%s" has illegal pattern\n' "$BACKUP_TAG_PREFIX"
  printf 'Recommended fix: "%s"\n' "$BACKUP_TAG_PREFIX_FIXED"
  printf 'See "configuration" section in README\n\n'
  exit 1
fi

