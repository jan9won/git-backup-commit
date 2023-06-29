#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Top level help
# ---------------------------------------------------------------------------- #

EMPTY="
usage           git wip [help] <command> 

<command>
create          Create new WIP commit, restore working and staging area
delete          Delete given WIP commit
restore         Restore working directory from given WIP commit
ls              List all WIP commits
push            Push WIP commits to remote
fetch           Fetch WIP commits to remote
"

# ---------------------------------------------------------------------------- #
# create
# ---------------------------------------------------------------------------- #

CREATE="
Usage           git wip create [help] [options]

[options]

-f|--force      Create even if there's nothing to commit.
"
# ---------------------------------------------------------------------------- #
# ls
# ---------------------------------------------------------------------------- #

LS="
Usage           git wip ls [help] [options]

Description     List WIP tags in the local repository

[options]

--<before|after>=<timestamp>

                List WIP commits created before or after the <timestamp>.

                Both --before and --after are inclusive. They can be used at the
                same time. However if the same flag is provided multiple times,
                only the first one will be used.

                <timestamp> is a unix timestamp. You can use commands like
                \`date -d \"<datetime_string>\" +%s\` to get it.
          

--format=<raw|pretty|long>

                Choose a level of information to print for each WIP commit.
                
                <raw> (default)
                Print raw tag name, which is consisted of a UNIX timestamp
                and full commit hash.

                <pretty>
                Print locale-formatted time string and short commit hash

                <long>
                Print raw tag name, locale-formatted time string and full
                list of committed files (result of \`git show --name-status\`).
                The files that have added by this library is marked with \"+\".
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
