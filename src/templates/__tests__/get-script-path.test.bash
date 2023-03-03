#!/usr/bin/env bash
# dir="$(dirname "$0")"
# source "$dir/../get-script-path.bash"
# get_script_path

# echo "$(dirname "${BASH_SOURCE[0]}")"
echo $(pwd)

get_script_path pwd
script_path="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

