#!/usr/bin/env bash
# Copyright (c) 2020, Loïc Deraed

# Bootstrap cfengine to a new remote machine
#
# Usage: bootstrap-remote user@ip_address

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

set -e

main() {
    remote_machine=${ARGS[0]}

    # copy bootstrap-local script to the remote machine, and execute it.
    scp -o "StrictHostKeyChecking no" -q \
        "bootstrap-local.sh" "$remote_machine:~"
    ssh -o "StrictHostKeyChecking no" \
        "$remote_machine" "chmod +x ~/bootstrap-local.sh && ~/bootstrap-local.sh"

    # cleanup
    ssh "$remote_machine" "rm ~/bootstrap-local.sh"
}

main
