#!/usr/bin/env bash

# --------------------------------------------------------------------------- #
# Check if requried bash and git version is installed 
# --------------------------------------------------------------------------- #

./src/utils/check-minimum-bash-version.bash
BASH_VERSION_FULFILLED=$?
./src/utils/check-minimum-git-version.bash
GIT_VERSION_FULFILLED=$?

if [[ $BASH_VERSION_FULFILLED -ne 0 || $GIT_VERSION_FULFILLED -ne 0 ]]; then
  exit 1 
fi

# --------------------------------------------------------------------------- #
# Installation paths
# --------------------------------------------------------------------------- #

COMMON_NAME="git-wip-commit"
LIBRARY_PATH="/usr/local/lib/$COMMON_NAME"
BINARY_PATH="/usr/local/bin/$COMMON_NAME"

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

mkdir -p "$LIBRARY_PATH"

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

# git clone "https://github.com/jan9won/git-wip-commit.git" "$LIBRARY_PATH"
$DOWNLOAD_COMMAND "https://github.com/jan9won/git-wip-commit/blob/main/dist/archive.tar.gz"
DOWNLOAD_STATUS=$?
if [[ $DOWNLOAD_STATUS -ne 0 ]]; then
  printf 'Download failed with status %d\n' "$DOWNLOAD_STATUS"
  printf 'Download command used: %s\n' "$DOWNLOAD_COMMAND"
  printf 'Please check your internet connection or report to the developer\n'
fi

tar xzf "$DOWNLOAD_FILE_PATH" -C "$LIBRARY_PATH"
chmod -R 755 "$LIBRARY_PATH"
rm "$DOWNLOAD_FILE_PATH"

# --------------------------------------------------------------------------- #
# Install binary symlink
# --------------------------------------------------------------------------- #

ln -s "$LIBRARY_PATH/entry.bash" "$BINARY_PATH/git-wip-commit"
chmod -R 755 "$BINARY_PATH"

# --------------------------------------------------------------------------- #
# Add alias calling entry script to global git config.
# --------------------------------------------------------------------------- #

ALIAS_NAME="wip"

if [ -n "$(git config --get alias.$ALIAS_NAME)" ]; then
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
#   if [[ "${path/ /}" = "/usr/local/bin" ]]; then
#     echo "found"
#   fi
# done

printf 'Installed correctly.\nFollowing commands are available:\n"git %s" or "%s"' "$ALIAS_NAME" "$COMMON_NAME"
