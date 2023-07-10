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
          
--format=<long|short|status>

                Choose a level of information to print for each WIP commit.

                <long> (default)
                Print locale-formatted time string and short commit hash

                <short> 
                Print raw tag name, which is consisted of a UNIX timestamp
                and full commit hash.

                <status>
                Print raw tag name, locale-formatted time string and full
                list of committed files (result of \`git show --name-status\`).
                The files that have added by this library is marked with \"+\".
"

# ---------------------------------------------------------------------------- #
# config
# ---------------------------------------------------------------------------- #

CONFIG="
usage           git wip config <key> <value>
                git wip config [options] [<key>]

<key>           A git config key, which consists of section, subsection and key

<value>         Value for the given key.

Available key-value pairs

                1.  key:    prefix
                    value:  an alphanumeric string
                            * case sensitive
                            * 2 ~ 10 characters
                    usage:  A prefix used for WIP tag names

                2.  key:    remote-timeout
                    value:  Timeout in seconds
                            * positive integer
                            * 2 ~ 10 seconds
                    usage:  Used when querying remote repositories

[options]

--get <key>     Show git config named \"jan9won.git-wip-commit.<key>\"
--get-all       Show all configs set under the section \"jan9won.git-wip-commit\"
"

# ---------------------------------------------------------------------------- #
# Restore
# ---------------------------------------------------------------------------- #

RESTORE="
usage           git wip restore [options] <refname>

<refname>       A name of reference pointing to the WIP commit to restore from.
                A list of possible refname is following:
                - A full or unique partial tag name (e.g., wip/1234567890/123)
                - A full or unique partial commit hash (e.g., 1234567)

[options]

-v|--verbose    Print process
"

# ---------------------------------------------------------------------------- #
# Delete
# ---------------------------------------------------------------------------- #

DELETE="
usage           git wip delete [options] [<refname>]

<refname>       A name of reference pointing to the WIP commit to restore from.
                A list of possible refname is following:
                - A full or unique partial tag name (e.g., wip/1234567890/123)
                - A full or unique partial commit hash (e.g., 1234567)

[options]

-v|--verbose    Print process

-a|--all        Delete all the WIP commits.
                Can't be used with --before, --after or <refname>(s)

--<before|after>=<timestamp>

                Delete all WIP commits created before or after the <timestamp>.
                Both --before and --after are inclusive. They can be used at the
                same time. However if the same flag is provided multiple times,
                only the first one will be used.

                <timestamp> is a unix timestamp. You can use commands like
                \`date -d \"<datetime_string>\" +%s\` to get it.
"

# ---------------------------------------------------------------------------- #
# Print help string according to command
# ---------------------------------------------------------------------------- #

case $1 in
  config)
    printf '%s' "$CONFIG"
    exit 0;
    ;;
  create)
    printf '%s' "$CREATE"
    exit 0;
    ;;
  ls)
    printf '%s' "$LS"
    exit 0;
    ;;
  restore)
    printf '%s' "$RESTORE"
    exit 0;
    ;;
  delete)
    printf '%s' "$DELETE"
    exit 0;
    ;;
esac

printf '%s' "$EMPTY"
exit 0;
