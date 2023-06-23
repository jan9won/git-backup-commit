#!/usr/bin/env bash

# --------------------------------------------------------------------------- #
# Check if requried bash version is installed 
# --------------------------------------------------------------------------- #

[[ $BASH_VERSION =~ ([0-9]*\.[0-9]*\.[0-9]*) ]]

IFS='.' read -r -a BASH_VER <<< "${BASH_REMATCH[1]}"

# MAJOR=4
BASH_MAJOR=4
BASH_MINOR=3
BASH_PATCH=0

if [[
  ${BASH_VER[0]} -lt $BASH_MAJOR ||
  (
    ${BASH_VER[0]} -eq $BASH_MAJOR &&
    ${BASH_VER[1]} -lt $BASH_MINOR
  ) ||
  (
    ${BASH_VER[0]} -eq $BASH_MAJOR &&
    ${BASH_VER[1]} -eq $BASH_MINOR &&
    ${BASH_VER[2]} -lt $BASH_PATCH
  )
]]; then
  printf 'Bash version %d.%d.%d or later is required.\n' "$BASH_MAJOR" "$BASH_MINOR" "$BASH_PATCH"
  printf 'Your current version is %d.%d.%d\n' "${BASH_VER[0]}" "${BASH_VER[1]}" "${BASH_VER[2]}"
  exit 1
fi

# --------------------------------------------------------------------------- #
# Check if requried bash and git version is installed 
# --------------------------------------------------------------------------- #

IFS='.' read -r -a GIT_VER <<< "$(git --version | sed -e 's/[^0-9.]//g')"

GIT_MAJOR=1
GIT_MINOR=9
GIT_PATCH=0

if [[
  ${GIT_VER[0]} -lt $GIT_MAJOR ||
  (
    ${GIT_VER[0]} -eq $GIT_MAJOR &&
    ${GIT_VER[1]} -lt $GIT_MINOR
  ) ||
  (
    ${GIT_VER[0]} -eq $GIT_MAJOR &&
    ${GIT_VER[1]} -eq $GIT_MINOR &&
    ${GIT_VER[2]} -lt $GIT_PATCH
  )
]]; then
  printf 'Git version %d.%d.%d or later is required.\n' "$GIT_MAJOR" "$GIT_MINOR" "$GIT_PATCH"
  printf 'Your current version is %d.%d.%d\n' "${GIT_VER[0]}" "${GIT_VER[1]}" "${GIT_VER[2]}"
  exit 1
fi


# --------------------------------------------------------------------------- #
# Installation paths
# --------------------------------------------------------------------------- #

COMMON_NAME="git-wip-commit"
LIBRARY_PATH="$HOME/.local/lib/$COMMON_NAME"
BINARY_PATH="$HOME/.local/bin/$COMMON_NAME"

# --------------------------------------------------------------------------- #
# Check if one of wget or curl is installed
# --------------------------------------------------------------------------- #

DOWNLOAD_FILE_PATH="$LIBRARY_PATH/archive.tar.gz"
DOWNLOAD_URL="https://github.com/jan9won/git-wip-commit/blob/main/install.bash"
DOWNLOAD_COMMAND=""

if type curl >/dev/null 2>&1; then
  DOWNLOAD_COMMAND="curl -LJo $DOWNLOAD_FILE_PATH $DOWNLOAD_URL"
fi

if type wget >/dev/null 2>&1; then
  DOWNLOAD_COMMAND="wget -O $DOWNLOAD_FILE_PATH $DOWNLOAD_URL"
fi

if [[ $DOWNLOAD_COMMAND = "" ]]; then
  printf "Neither curl nor wget was found.\nPlease install one of them and try again."
  exit 1
fi

# --------------------------------------------------------------------------- #
# Prepare library path
# --------------------------------------------------------------------------- #

if [[ -d "$LIBRARY_PATH" && $(ls -A "$LIBRARY_PATH") ]]; then
  printf 'Library directory "%s" already exists and is not empty.\n' "$LIBRARY_PATH"
  # printf 'Would you like to overwrite?'
  printf 'Delete the directory and try again.\n'
  exit 1
fi

if ! mkdir -p "$LIBRARY_PATH"; then
  printf 'mkdir failed on the %s. Aborting installation\n' "$LIBRARY_PATH"
  exit 1
fi

# --------------------------------------------------------------------------- #
# Prepare binary path
# --------------------------------------------------------------------------- #

if [[ -e "$BINARY_PATH" ]]; then
  printf 'File path for binary "%s" already exists.\n' "$BINARY_PATH" 
  # printf 'Would you like to overwrite?'
  printf 'Delete the directory and try again.\n'
  exit 1
fi

# --------------------------------------------------------------------------- #
# Download source archive to the library path, unarchive
# --------------------------------------------------------------------------- #

if ! $DOWNLOAD_COMMAND; then
  printf 'Download failed with status %d\n' "$?"
  printf 'Download command used: %s\n' "$DOWNLOAD_COMMAND"
  printf 'Please check your internet connection or report to the developer\n'
fi

if ! tar xzf "$DOWNLOAD_FILE_PATH" -C "$LIBRARY_PATH"; then
  printf 'tar failed with exit code %d. Aborting installation.' "$?"
  exit 1
fi

if ! chmod -R 755 "$LIBRARY_PATH"; then
  printf 'chmod failed with exit code %d. Aborting installation.' "$?"
  exit 1
fi

if ! rm "$DOWNLOAD_FILE_PATH"; then
  printf 'rm failed with exit code %d. Aborting installation.' "$?"
  exti 1
fi

# --------------------------------------------------------------------------- #
# Install binary symlink
# --------------------------------------------------------------------------- #

ln -s "$LIBRARY_PATH/entry.bash" "$BINARY_PATH/git-wip-commit"
chmod -R 755 "$BINARY_PATH"

# --------------------------------------------------------------------------- #
# Add alias calling entry script to global git config.
# --------------------------------------------------------------------------- #

ALIAS_NAME="wip"

if [[ -n "$(git config --get alias.$ALIAS_NAME)" ]]; then
  printf 'Git alias named '%s' is already in your git config.\n' "$ALIAS_NAME"
  # printf 'Would you like to overwrite?'
  printf 'Delete it and try again.\n'
  exit 1
fi

git config --global --set "alias.$ALIAS_NAME" "!$BINARY_PATH"

# --------------------------------------------------------------------------- #
# Check if $PATH includes binary path. If not, suggest so
# --------------------------------------------------------------------------- #

# IFS=':' read -ra PATH_ARRAY <<< "$PATH"
# for path in "${PATH_ARRAY[@]}"; do
#   if [[ "${path/ /}" = "$BINARY_PATH" ]]; then
#     echo "found"
#   fi
# done

printf 'Installed correctly.\nFollowing commands are available:\n"git %s" or "%s"' "$ALIAS_NAME" "$COMMON_NAME"
