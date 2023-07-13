
datestring=$1
declare -i timestamp

# GNU
if date --version >/dev/null 2>&1; then
  timestamp=$(date -d "$datestring" +%s)

# BSD
else
  # timestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "$datestring" +%s)
  timestamp=$(date -j "$datestring" +%s)
fi

printf '%d\n' "$timestamp"
