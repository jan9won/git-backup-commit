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

--before|after=<timestamp>

                List WIP commits created before or after the <timestamp>.

                Both options are inclusive.

                <timestamp> is a unix timestamp. You can use commands like
                \`date -d \"<datetime_string>\" +%s\` to get it.

                \`--before\` and \`--after\` can be used at the same time.
                However if the same flag is provided multiple times, only the
                first one will be used.

--format=<raw|pretty|long>

                Choose a level of information to print for each WIP commit.
                
                raw (default): print raw tag name, which has a UNIX timestamp
                and full commit hash

                pretty: print locale-formatted time string and short commit hash

                long: print raw tag name, locale-formatted time string and full
                list of committed files (result of \`git show --name-status\`)
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
