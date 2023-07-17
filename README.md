# Git-WIP-Commit

> Tests
>
> ![Integration And Entry](https://github.com/jan9won/git-wip-commit/actions/workflows/installation-and-entry.yml/badge.svg)

## Table of Contents

*   [Introduction](#introduction)

    *   [Use Cases of This Library](#use-cases-of-this-library)
    *   [Key Components](#key-components)
    *   [Working with WIP commit](#working-with-wip-commit)
    *   [Advantages Over Other WIP Sharing Strategies](#advantages-over-other-wip-sharing-strategies)
    *   [Limitations](#limitations)

*   [Getting Started](#getting-started)

    *   [Requirements](#requirements)
    *   [Installation and Preparation](#installation-and-preparation)
    *   [Usage](#usage)
    *   [Feature Description](#feature-description)
    *   [Troubleshooting](#troubleshooting)

## Introduction

### Use Cases of This Library

*   Share current status of working/staging area over remote repository
*   Create commits for backup purposes, and restore from them later

### Key Components

*   WIP commit
    *   A commit that stores work-in-progress changes
    *   It doesn't have a branch or a parent commit. The advantages are:
        *   Commit won’t appear in daily commands
        *   Commit can be deleted without affecting any branch

*   WIP tag
    *   An annotated tag that is attached to every WIP tag
    *   It stores following metadata:
        *   Tag name is formatted as `prefix/timestamp/commit-hash/`
        *   Tag message stores a list of file which were staged at the time of creation

### Working with WIP commit

*   Creating WIP commit has little to no affect on your current working state
    *   It doesn't change the current state of working and staging area
    *   It creates commit and checks out the commit you've checked out before

*   Deleting WIP commit doesn't affect repository

*   You can restore working/staging area from a WIP commit

*   You can push/fetch/compare/prune WIP commits on remote repository

### Advantages Over Other WIP Sharing Strategies

1.  Advantages over `git-stash`
    *   Stashes can't directly be pushed to the remote (not at least with well-defined behavior)

2.  Adavantages over directly syncing project directory (e.g., `rsync`)
    *   Push/fetch workload is smaller
    *   As your gitignore is respected, unexpected file sharing is prevented

### Limitations

1.  Commit log and tag list won’t be 100% clean
    *   Commit log will show WIP commits with options like `--all` or `--tags`
    *   Tags list will always print WIP tags, but can filtered

2.  Deletion relies on git's garbage collection
    *   If there are other references other than WIP tag left on the WIP commit, (which shouldn't be in normal use cases), the commit won't be deleted
    *   Commits may not get deleted immediately after deletion commands (until next gc phase).

3.  WIP commits are not resilient to destructive commands
    *   If you accidentally delete WIP tags, the commit becomes a dangling commit, and will be deleted in the next garbage collection routine

## Getting Started

### Requirements

This is a collection of bash scripts that uses native git commands.

*   bash > 4.3 (Jul. 10, 2014)
*   git > 1.9 (Feb, 14. 2014)
*   curl or wget
*   tar

### Installation and Preparation

1.  Download and run install script

    ```bash
    curl -o- https://raw.githubusercontent.com/jan9won/git-wip-commit/main/install.sh | bash
    ```

2.  Prepare remote repository for remote features

    ```bash
    git remote add <remote-name> <remote-path>
    ```

### Usage

1.  Entry command

    ```bash
    git wip <command>
    ```

2.  Use `help` command to see manual for each level of command. For example:

    ```bash
    git wip help          # top level
    git wip create help   # for create command
    git wip remote help   # for remote commands
    ```

### Feature Description

1.  Working Locally

    *   `git wip create`  : create a new WIP commit attached to current commit
    *   `git wip ls`      : list WIP commits
    *   `git wip delete`  : delete WIP commits
    *   `git wip restore` : restore current working/staging area with WIP commit
    *   `git wip config`  : configure this library

2.  Working Remotely

    *   `git wip remote <remote> push`          : push WIP commits that doesn't exist on remote
    *   `git wip remote <remote> fetch`         : fetch WIP commits that doesn't exist on local
    *   `git wip remote <remote> prune-local`   : delete local commits that doesn't exist on remote
    *   `git wip remote <remote> prune-remote`  : delete remote commits that doesn't exist on local

### Troubleshooting

1.  Command not found

    1.  Check if your bash is over 4.3
    2.  Check if your local binary path (`~/.local/bin`) is added to `PATH`. If not, add it
    3.  If problem persists, delete `~/.local/lib/git-wip-commit` and `~/.local/bin/git-wip-commit` then reinstall.

2.  `<command> is not a git command`

    1.  Update git over version 1.9

3.  `permission denied`

    1.  Check if your binary and library path's permission allows execution. If now, allow them.
