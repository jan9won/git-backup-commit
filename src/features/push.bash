#!/usr/bin/env bash

REMOTE=""
PREFIX=$(git config --get jan9won.git-wip-commit.prefix)

readarray -t LOCAL_WIP_COMMITS < <(git wip ls --format=short)
readarray -t REMOTE_WIP_COMMITS < <(git ls-remote "$REMOTE" refs/tags/"$PREFIX")

for local_wip_commit in "${LOCAL_WIP_COMMITS[@]}"; do

  echo "$local_wip_commit"
done
