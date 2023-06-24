#!/usr/bin/env bash

PREFIX=$(git config --get jan9won.git-wip-commit.prefix)
git tag --list "$PREFIX*" --sort=-refname
