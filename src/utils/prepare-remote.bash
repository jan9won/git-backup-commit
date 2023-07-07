

VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -*)
      printf 'Illegal option %s\n' "$1"
      exit 1
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#ARGS[@]} -gt 1 ]]; then
  printf 'Too many arguments, expected 1\n'
  exit 1
fi

if [[ ${#ARGS[@]} -eq 0 ]]; then
  printf 'Argument is required\n'
  exit 1
fi

if [[ ${#ARGS[@]} -eq 1 ]]; then
  REMOTE_NAME=${ARGS[0]}
  shift
fi



# ---------------------------------------------------------------------------- #
# Get path of the directory this script is included
# ---------------------------------------------------------------------------- #

get_script_path () {
  local SOURCE
  local SCRIPT_PATH
  SOURCE=${BASH_SOURCE[0]}
  # resolve $SOURCE until the file is no longer a symlink
  while [ -L "$SOURCE" ]; do 
    SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
    SOURCE=$(readlink "$SOURCE")
    # if $SOURCE was a relative symlink, resolve it relative to it
    [[ $SOURCE != /* ]] && SOURCE=$SCRIPT_PATH/$SOURCE 
  done
  SCRIPT_PATH=$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )
  echo "$SCRIPT_PATH"
}

SCRIPT_PATH=$(get_script_path)
USAGE_PATH=$(readlink -f "$SCRIPT_PATH/../features/usage.bash") 

# ---------------------------------------------------------------------------- #
# Get remote name (given as the first parameter), check if not empty
# ---------------------------------------------------------------------------- #

if [[ $REMOTE_NAME = "" ]]; then
  printf 'Remote name is not given (got an empty string)\n'
  exit 1
fi

# ---------------------------------------------------------------------------- #
# Check if the remote actually exists
# ---------------------------------------------------------------------------- #

# Get remote timeout config
REMOTE_TIMEOUT=$(git config jan9won.git-wip-commit.remote-timeout)
if [[ $REMOTE_TIMEOUT = "" ]]; then
  REMOTE_TIMEOUT="10"
fi

$VERBOSE && printf 'Checking if the remote repository "%s" is accessible (%ss timeout)...\n' "$REMOTE_NAME" "$REMOTE_TIMEOUT"

timeout "$REMOTE_TIMEOUT" git ls-remote --exit-code "$REMOTE_NAME" 1>/dev/null
EXIT_CODE="$?"

case "$EXIT_CODE" in
  128)
    exit 1;
    ;;
  124)
    printf 'Remote repository "%s" has not responded in %s seconds.\n' "$REMOTE_NAME" "$REMOTE_TIMEOUT"
    printf 'If you want to change the default timeout, configure it through "git wip config remote-timeout <seconds>.\n' 
    $USAGE_PATH "config"
    exit 1
    ;;
  0)
    $VERBOSE && printf 'OK\n'
    exit 0
    ;;
  *)
    printf 'Unhandled error %s occured while running "git ls-remote %s"\n' "$EXIT_CODE" "$REMOTE_NAME"
    exit 1
esac

