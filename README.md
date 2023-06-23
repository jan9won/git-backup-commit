# Git-WIP-Commit

## Table of Contents

*   [Introduction](#introduction)

    *   [What is a "WIP commit"](#what-is-a-wip-commit)
    *   [Features](#features)
    *   [Advantages Over Other Strategies](#advantages-over-other-strategies)
    *   [Limitations](#limitations)

*   [Getting Started](#getting-started)

    *   [Requirements](#requirements)
    *   [Installation](#installation)

*   [Configuration](#configuration)

*   [Usage](#usage)

    *   [Working Locally](#working-locally)

        *   [Create](#create)
        *   [List](#list)
        *   [Delete](#delete)

    *   [Working With Remote](#working-with-remote)

        *   [List](#list-1)
        *   [Push](#push)
        *   [Fetch](#fetch)
        *   [Delete](#delete-1)

    *   [Manual Configuration](#manual-configuration)

        *   [Tag Prefix](#tag-prefix)
        *   [Git Alias](#git-alias)

    *   [Troubleshooting](#troubleshooting)

        *   [`command not found: <command>`](#command-not-found-command)
        *   [`<command> is not a git command`](#command-is-not-a-git-command)
        *   [`permission denied`](#permission-denied)

## Introduction

### What is a "WIP commit"

*   A commit created to record work-in-progress changes
*   Usage
    *   Share uncommited changes over remote repository
    *   Manage WIP commits in batch

### Features

1.  Create a commit, yet preserve current state of repository
    *   Immediately restore working & staging area
    *   Delete branch used to create the commit, this has few advantages:
        *   Commit won’t appear in daily commands (unless you explicitly include them)
        *   Commit can be deleted without affecting any branch
        *   Prevent you from creating new commit, merging and patching on WIP commit (it’s also prevented by git hooks)

2.  Add a unique tag to the commit
    *   Used to find, delete and restore from WIP commits
    *   Used to push and fetch WIP commits on remotes

### Advantages Over Other Strategies

1.  Adavantages over directly syncing files with `rsync`
    *   Push/fetch workload is usually smaller
    *   As your `.gitignore` file is respected, unexpected private file push is prevented

2.  Advantages over `git-stash`
    *   Stashes can't be directly pushed to the remote (not at least with well-defined behavior)
    *   Stashes are harder to be used as backup, as they’re not part of history

### Limitations

1.  History won’t be 100% clean
    *   It still creates extra commmits and tags
    *   Log will show WIP commits with options like `git log --all` or `git log --tags`

2.  It’s not resilient to destructive commands
    *   If you accidentally delete WIP commit’s tag, the commit becomes a dangling commit, and will be deleted in the next garbage collection routine

3.  WIP Commits are not 100% private
    *   They can still be pushed to any remote if specified explicitly
    *   E.g., `git push <remote> <tag_name>`
    *   Though it isn't likely to happen, as tag names are long and complex

## Getting Started

### Requirements

This is a collection of bash scripts that uses native git commands.

*   bash > 4.3 (Jul. 10, 2014)
*   git > 1.9 (Feb, 14. 2014)
*   curl or wget
*   tar

### Installation

1.  Download and run install script

    ```bash
    curl -o- https://raw.githubusercontent.com/jan9won/git-wip-commit/main/install.sh | bash
    ```

## Configuration

1.  Configure tag prefix
    *   Purpose:    A string prefixed to the tags that marks backup commits
    *   Command:    `git backup config prefix <prefix>`
2.  Prepare remote repository
    *   Some features that works with remote repository (e.g., push, fetch) requires remote repository name

## Usage

(Use `--help` flag to see manual on each subcommand)

### Working Locally

#### Create

⚠️ You can't create WIP commit on another WIP commit. (Prevented with git pre-commit hook)

⚠️ You can't create WIP commit without changes to commit

    git wip create [-e | --empty]

*   Options

    *   `-e | --empty` : create WIP commit without any changes (same as currently checked out commit)

*   Tags are created in following format

    *   `<tag prefix name>-<commit hash>-<creation time in UTC epoch>`
    *   E.g., `wip-1683533327`

#### List

    git wip ls [--author <author name>] [--after <UTC epoch>]

Options

*   `--author <author name>` : list all local WIP commits created by `author name`
*   `--after <UTC epoch>` : list all local WIP commits created after provided `<UTC epoch` time

#### Delete

⚠️ Do not delete tags explicitly

    git wip delete [<tag> | --all] [--author <author name>] [--after <UTC epoch>]

Options

*   `<tag>` : delete specific WIP commit with tag name
*   `--all` : delete all WIP commits
*   `--author <author name>` : delete all local WIP commits created by `author name`
*   `--after <UTC epoch>` : delete all local WIP commits created after provided `UTC epoch` time

1.  Restore working space and staging area from WIP commit

⚠️ This may introduce conflict with uncommited files, stash them or clean workspace before running this command.

    git wip restore <tag>

### Working With Remote

⚠️ Before running remote-related commands, configure remote through git.

#### List

    git wip remote ls <remote> [--author <author name>] [--after <UTC epoch>]

Options

*   `--author <author name>` : list all remote WIP commits created by `author name`
*   `--after <UTC epoch>` : list all remote WIP commits created after provided `<UTC epoch` time

#### Push

Push all local WIP commits that doesn’t exists on the remote

    git wip remote push <remote>

#### Fetch

Fetch all remote WIP commits that doesn’t exists in local repository

    git wip remote fetch <remote>

#### Delete

Delete remote WIP commits

    git wip remote delete <remote> [--missing-on-remote | --missing-on-local | <tag> | --all] [--author <author name>] [--after <UTC epoch>]

*   Options
    *   `–-missing-on-remote` (default) : delete all remote WIP commits that doesn’t exists on the local repository, but exists in the remote
    *   `–-missing-on-local` : delete all local WIP commits that doesn’t exists on the remote, but exists in the local repository
    *   `<tag>` : delete specific remote WIP commit with tag name
    *   `--all` : delete all WIP commits in the remote
    *   `--author <author name>` : delete all remote WIP commits created by `author name`
    *   `--after <UTC epoch>` : delete all remote WIP commits created after provided `UTC epoch` time

### Manual Configuration

You can manually configure informations that install script prompted you at the first installation.

Configuration is stored in repository's local \`\` file's section.

#### Tag Prefix

It’s prefixed to every WIP commit’s unique tag.

In local `.git/config`, under `[jan9won.git-wip-commit]` section, edit `prefix` variable’s value.

    [git-wip-commit]
    	...
    	tag-prefix = <tag prefix name>

#### Git Alias

In global `~/.gitconfig`, under `[alias]` section, edit `wip` variable name.

    [alias]
    	...
    	wip = !git-wip-commit

### Troubleshooting

#### `command not found: <command>`

*   Command is `git-wip-commit`

    1.  Look in your shell's startup script

        Check if your local binary path (`~/bin`) is added to `PATH`. If not, add it

    2.  Look in your library path (`~/lib/git-wip-commit`)

        Check if libary contents exist and not corrupted. If not, reinstall.

    3.  Look in your binary path (`~/bin`)

        Check if symlink named `git-wip-commit` exists and points to `~/lib/git-wip-commit/entry.sh`. If not, reinstall.

    4.  If problem persists

        Delete `~/lib/git-wip-commit` and `~/bin/git-wip-commit` and reinstall.

*   Other commands

    1.  Update bash over version 4.3

#### `<command> is not a git command`

1.  Update git over version 1.9

#### `permission denied`

1.  Check if your binary and library path's permission allows execution

2.  If not, run following command on `~/lib/git-wip-commit` and `~/bin`

    `chmod -R +x /path/to/directory`
