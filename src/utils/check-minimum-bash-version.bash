# first argument : bash version
if [[ ${BASH_VERSION%%.*} -lt $1 ]]; then
  echo "This script requires Bash version $1 or later." >&2
  exit 1
  else
  exit 0
fi