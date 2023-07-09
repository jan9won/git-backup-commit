#!/usr/bin/env bash

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
# Entry Check 1: if called inside a git repository
# --------------------------------------------------------------------------- #

IS_GIT_REPO=$(git rev-parse --is-inside-work-tree 2>/dev/null)

if [[ $IS_GIT_REPO != "true" ]]; then
	printf "[Error] Not a git repository.\n"
  "$SCRIPT_PATH/features/usage.bash"
	exit 1
fi

# --------------------------------------------------------------------------- #
# Entry Check 2: if tag prefix is ready
# --------------------------------------------------------------------------- #

if ! "$SCRIPT_PATH/utils/prepare-prefix.bash"; then
	exit 1
fi

# --------------------------------------------------------------------------- #
# Handle highest order argument
# --------------------------------------------------------------------------- #

while [[ "$#" -gt 0 ]]; do
	case $1 in
    help)
      shift;
			"$SCRIPT_PATH/features/usage.bash"
      exit 0;
      ;;
		create)
			shift;
			"$SCRIPT_PATH/features/create.bash" "$@"
      exit 0;
			;;
		ls)
			shift;
			"$SCRIPT_PATH/features/ls.bash" "$@"
      exit 0;
			;;
		restore)
			shift;
			"$SCRIPT_PATH/features/restore.bash" "$@"
      exit 0;
			;;
		delete)
			shift;
			"$SCRIPT_PATH/features/delete.bash" "$@"
      exit 0;
			;;
    # Remotes
    remote)
      shift;
      "$SCRIPT_PATH/features/remote.bash" "$@"
      exit 0;
    ;;
    # compare-remote)
    #   shift;
    #   "$SCRIPT_PATH/features/compare-remote.bash" "$@"
    #   exit 0;
    # ;;
    # push-remote)
    #   shift;
    #   "$SCRIPT_PATH/features/push-remote.bash" "$@"
    #   exit 0;
    # ;;
    # fetch-remote)
    #   shift;
    #   "$SCRIPT_PATH/features/fetch-remote.bash" "$@"
    #   exit 0;
    # ;;
    # prune-remote)
    #   shift;
    #   "$SCRIPT_PATH/features/prune-remote.bash" "$@"
    #   exit 0;
    # ;;
		-*)
			echo "illegal option $1";
      exit 1;
			;;
		*)
			echo "illegal command $1"
      exit 1;
			;;
	esac
done

"$SCRIPT_PATH/features/usage.bash"
exit 0

