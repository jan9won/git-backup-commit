#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Utilities
# ---------------------------------------------------------------------------- #

# read_yes_or_no(){
# 	printf "[Y/N] "
# 	read -r ANSWER
# 	if [[ $ANSWER =~ ^[yY]$ ]]; then
# 		return 0
# 	elif [[ $ANSWER =~ ^[nN]$ ]]; then
# 		return 1
# 	else
# 		printf 'Bad input "%s"\n' "$ANSWER"
# 		read_yes_or_no
# 	fi
# }

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
  printf '[ERROR]Bash version %d.%d.%d or later is required. Your current version is %d.%d.%d\n' "$BASH_MAJOR" "$BASH_MINOR" "$BASH_PATCH" "${BASH_VER[0]}" "${BASH_VER[1]}" "${BASH_VER[2]}"
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
  printf '[ERROR] Git version %d.%d.%d or later is required. Your current version is %d.%d.%d\n' "$GIT_MAJOR" "$GIT_MINOR" "$GIT_PATCH" "${GIT_VER[0]}" "${GIT_VER[1]}" "${GIT_VER[2]}"
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
DOWNLOAD_URL="https://raw.githubusercontent.com/jan9won/git-wip-commit/main/dist/archive.tar.gz"
DOWNLOAD_COMMAND=""

if type curl >/dev/null 2>&1; then
  DOWNLOAD_COMMAND="curl -sLJo $DOWNLOAD_FILE_PATH $DOWNLOAD_URL"
fi

if type wget >/dev/null 2>&1; then
  DOWNLOAD_COMMAND="wget -qO $DOWNLOAD_FILE_PATH $DOWNLOAD_URL"
fi

if [[ $DOWNLOAD_COMMAND = "" ]]; then
  printf '[ERROR] Neither curl nor wget was found.\nPlease install one of them and try again.'
  exit 1
fi

# --------------------------------------------------------------------------- #
# Prepare library path
# --------------------------------------------------------------------------- #
# Download source archive to the library path, unarchive
# --------------------------------------------------------------------------- #

# Check if library path exists
if [[ -d "$LIBRARY_PATH" && $(ls -A "$LIBRARY_PATH") ]]; then
  rm -rf "$LIBRARY_PATH"
  # printf 'Library directory "%s" already exists and is not empty.\n' "$LIBRARY_PATH"
  # read_yes_or_no
  # case $? in
  #   0)
  #     printf 'Overwriting the directory\n'
  #     rm -rf "$LIBRARY_PATH"
  #     ;;
  #   1)
  #     printf 'Aborting installation\n'
  #     exit 0
  #     ;;
  # esac
fi

# Create library path
if ! mkdir -p "$LIBRARY_PATH"; then
  printf '[ERROR] mkdir on path %s has failed.\nAborting installation\n' "$LIBRARY_PATH"
  exit 1
fi

# Download archive file
if ! $DOWNLOAD_COMMAND; then
  printf 'Download failed with status %d\n' "$?"
  printf 'Download command used: %s\n' "$DOWNLOAD_COMMAND"
  printf 'Please check your internet connection or report to the developer\n'
fi

# Unarchive
if ! tar xzf "$DOWNLOAD_FILE_PATH" -C "$LIBRARY_PATH"; then
  printf '[ERROR] tar unarchiving failed on %s. Aborting installation.\n' "$DOWNLOAD_FILE_PATH"
  exit 1
fi

# Change permissions
if ! chmod -R 755 "$LIBRARY_PATH"; then
  printf '[ERROR] chmod -R 755 on %s failed. Aborting installation.\n' "$LIBRARY_PATH"
  exit 1
fi

# Remove archive
if ! rm "$DOWNLOAD_FILE_PATH"; then
  printf '[ERROR] Deleting archive file failed. Aborting installation.\n'
  exti 1
fi

# --------------------------------------------------------------------------- #
# Prepare binary path
# --------------------------------------------------------------------------- #
# Install binary symlink
# --------------------------------------------------------------------------- #

# Check if binary symlink already exists
if [[ -e "$BINARY_PATH" ]]; then
  rm "$BINARY_PATH" 
  # printf 'File path for binary "%s" already exists.\n' "$BINARY_PATH" 
  # printf 'Would you like to overwrite? '
  # read_yes_or_no
  # case $? in
  #   0)
  #     printf 'Overwriting the existing symlink\n'
  #     rm "$BINARY_PATH" 
  #     ;;
  #   1)
  #     printf 'Aborting installation...\n'
  #     exit 0
  #     ;;
  # esac
fi

# Create binary directory
if ! mkdir -p "$HOME/.local/bin/"; then
  printf '[ERROR] mkdir on path %s has failed.\nAborting installation\n' "$LIBRARY_PATH" 
  exit 1
fi

if ! ln -s "$LIBRARY_PATH/entry.bash" "$BINARY_PATH"; then
  printf '[ERROR] Symlink creation failed. Aborting installation\n'
  exit 1
fi

if ! chmod -R 755 "$BINARY_PATH"; then
  printf '[ERROR] Permission changing failed. Aborting installation\n'
  exit 1
fi

# --------------------------------------------------------------------------- #
# Add global git alias calling entry script
# --------------------------------------------------------------------------- #

ALIAS_NAME="wip"
if ! git config --global --add "alias.$ALIAS_NAME" "!$BINARY_PATH"; then
  printf 'git config --global failed. Aborting installation.\n'
  rm -rf "$LIBRARY_PATH"
  rm "$BINARY_PATH"
  exit 1
fi

# --------------------------------------------------------------------------- #
# Check if $PATH includes binary path. If not, suggest adding it
# --------------------------------------------------------------------------- #

IFS=':' read -ra PATH_ARRAY <<< "$PATH"
HAS_BINARY_PATH_SET=false
for path in "${PATH_ARRAY[@]}"; do
  if [[ "${path/ /}" = "$HOME/.local/bin" ]]; then
    HAS_BINARY_PATH_SET=true
  fi
done

if ! $HAS_BINARY_PATH_SET; then
  printf '[WARN] %s/.local/bin/ is currently not included in your PATH variable. Please add it to your shell startup configuration file to use "git-wip-commit" command directly\n' "$HOME"
fi

# ---------------------------------------------------------------------------- #
# Wrap up
# ---------------------------------------------------------------------------- #

git wip 
