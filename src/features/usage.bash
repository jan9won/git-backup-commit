#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Top level help
# ---------------------------------------------------------------------------- #

EMPTY="
usage           git wip [--help] <command> 

<command>
create          Create new wip commit, restore working and staging area
delete          Delete given wip commit
restore         Restore working directory from given wip commit
ls              List all wip commits
push            Push wip commits to remote
fetch           Fetch wip commits to remote

"

# ---------------------------------------------------------------------------- #
# create
# ---------------------------------------------------------------------------- #

CREATE="
Usage           git wip create [flags]

Description     1. create new backup branch
                2. commit everything
                3. restore working directory

[flags]

-h|--help       Print this message
-f|--force      Create backup even if there's nothing to add or commit.

"
# ---------------------------------------------------------------------------- #
# ls
# ---------------------------------------------------------------------------- #

LS="
usage           git wip ls [flags]

[flags]
-r | --remote   show remote
-a | --all      show remote and local

"

# ---------------------------------------------------------------------------- #
# config
# ---------------------------------------------------------------------------- #

CONFIG="
usage           git wip config <variable> <value>

<variable>
prefix          prefix used for tag names
remote-timeout  timeout in seconds, used when querying remote repositories
"

# ---------------------------------------------------------------------------- #
# Print help string according to command
# ---------------------------------------------------------------------------- #

case $1 in
  create)
    printf '%s' "$CREATE"
    exit 0;
    ;;
  ls)
    printf '%s' "$LS"
    exit 0;
    ;;
  config)
    printf '%s' "$CONFIG"
    exit 0;
    ;;
esac

printf '%s' "$EMPTY"
exit 0;
