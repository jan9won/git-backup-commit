# ---------------------------------------------------------------------------- #
# Parse arguments
# ---------------------------------------------------------------------------- #

# KEY=${!#}
# set -- "${@:1:$#-1}"

VERBOSE=false

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
    # *)
    #  if [[ $1 =~ "" ]]; then
    #    printf 'Illegal command %s\n' "$1"
    #    exit 1
    #  fi
    #  ;;
  esac
done

if [[ $# -gt 2 ]]; then
  printf 'Too many arguments, expected 2\n'
fi

if [[ $# -eq 0 ]]; then
  printf 'Argument "" required\n'
  # usage path
fi


