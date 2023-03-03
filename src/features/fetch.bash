#!/usr/bin/env bash

#!/usr/bin/env bash
echo fetch

# fetch all backup branches
# git branch -r | grep -v '\->' | sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" | while read remote; do git branch --track "${remote#origin/}" "$remote"; done
# git fetch --all
# git pull --all
