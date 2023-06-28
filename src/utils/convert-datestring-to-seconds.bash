
datestring=$1
declare -i timestamp

if date --version >/dev/null 2>&1; then
  # GNU
  timestamp=$(date -d "$datestring" +%s)
else
  # BSD
  timestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "$datestring" +%s)
fi

printf '%d\n' "$timestamp"
