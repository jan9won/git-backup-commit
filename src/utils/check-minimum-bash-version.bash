if [[ ${BASH_VERSION%%.*} -lt $1 ]]; then
  echo "This script requires Bash version $1 or later." >&2
  exit 1
fi