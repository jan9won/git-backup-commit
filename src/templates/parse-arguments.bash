# ---------------------------------------------------------------------------- #
# Parse arguments
# ---------------------------------------------------------------------------- #

# KEY=${!#}
# set -- "${@:1:$#-1}"

VERBOSE=false
ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -o|--option)
      # set some variables
      shift
      ;;
    command)
      # do something
      exit 0
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

if [[ ${#ARGS[@]} -gt 2 ]]; then
  printf 'Too many arguments, expected 2\n'
  exit 1
fi

if [[ ${#ARGS[@]} -eq 0 ]]; then
  printf 'Argument is required\n'
  exit 1
fi

if [[ ${#ARGS[@]} -eq 1 ]]; then
  MYVAR=${ARGS[0]}
fi


