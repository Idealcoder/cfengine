#!/usr/bin/env bash
# Copyright (c) 2020, Loïc Deraed

# Pick a random hostname from 'candidate_hostnames.txt'

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

shuf -n 1 "$PROGDIR/candidate_hostnames.txt"
