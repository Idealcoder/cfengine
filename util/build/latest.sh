#!/usr/bin/env bash
# Copyright (c) 2020, Loïc Deraed

# Get latest tag given a git url
#
# Usage: latest git-url

readonly ARGS=("$@")

git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags ${ARGS[0]} '*.*.*' \
    | tail --lines=1 \
    | cut --delimiter='/' --fields=3 \
    | sed -e "s/v//g"

