#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
# Top level help
# ---------------------------------------------------------------------------- #

EMPTY="
usage           git wip [help] <command> 

<command>
create          Create new WIP commit, restore working and staging area
ls              List all WIP commits
delete          Delete given WIP commit
restore         Restore working directory from given WIP commit
remote          A set of remote commands and featured under this command
config          Configure this library
"

# ---------------------------------------------------------------------------- #
# create
# ---------------------------------------------------------------------------- #

CREATE="
Usage           git wip create [help] [options]

Description     Create WIP commit on the top of the commit you're currentl
                checked out. (You can't create WIP commit on another WIP commit)

[options]

-f|--force      Create empty WIP commit when there's nothing to commit.
-v|--verbose    Print each steps of this feature
"
# ---------------------------------------------------------------------------- #
# ls
# ---------------------------------------------------------------------------- #

LS="
Usage           git wip ls [help] [options]

Description     List WIP commits in the local repository

[options]

--remote=<remote-name>
        
                Query remote repository rather than the local one.

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

-v|--verbose    Print each steps of this feature
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
-v|--verbose    Print each steps of this feature
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

-v|--verbose    Print each steps of this feature
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

-a|--all        Delete all the WIP commits.
                Can't be used with --before, --after or <refname>(s)

--<before|after>=<timestamp>

                Delete all WIP commits created before or after the <timestamp>.
                Both --before and --after are inclusive. They can be used at the
                same time. However if the same flag is provided multiple times,
                only the first one will be used.

                <timestamp> is a unix timestamp. You can use commands like
                \`date -d \"<datetime_string>\" +%s\` to get it.

-v|--verbose    Print each steps of this feature
"

# ---------------------------------------------------------------------------- #
# Remote
# ---------------------------------------------------------------------------- #

REMOTE="
usage           git wip remote <remote> <command> [options]

<remote>        Name of remote configured in your local repository

<command>

compare         Compare local and remote repository, print which WIP commits are
                unique to local/remote repository, and which are common.

push            Push local WIP commits that are not on the remote repository,
                but on the local repository.

fetch           Fetch remote WIP commits that are not on the local repository,
                but on the remote repository.

prune-local     Delete local WIP commits that are on the local repository, but
                not on the remote repository.

prune-remote    Delete remote WIP commits that are on the remote repository, but
                not on the local repository.

[options]

-v|--verbose    Print each steps of this feature

--porcelain     Used with \`compare\` command, only print newline-separated
                lists of WIP tag names without list titles. The format is:
                
                \`<a list of locally unique tags>\`
                \`<a list of remotely unique tags>\`
                \`<a list of common tags>\`
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
  remote)
    pritnf '%s' "$REMOTE"
    exit 0;
    ;;
esac

printf '%s' "$EMPTY"
exit 0;
