# ---------------------------------------------------------------------------- #
# Parse options
# ---------------------------------------------------------------------------- #

# KEY=${!#}
# set -- "${@:1:$#-1}"

while [[ $# -gt 0 ]]; do
  case $1 in
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
      printf 'Illegal command %s\n' "$1"
      exit 1
      ;;
  esac
done


