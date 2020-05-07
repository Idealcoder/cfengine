#!/usr/bin/env bash
# Copyright (c) 2020, Loïc Deraed

# Bootstrap cfengine to a new remote machine
#
# Usage: bootstrap-remote user@ip_address

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

set -e

# coloured output
green() { IFS= ; while read -r line; do echo -e '\e[32m'$line'\e[0m'; done; }
blue()  { IFS= ; while read -r line; do echo -e '\e[34m'$line'\e[0m'; done; }

wrapped_output() {
    prefix="-->"
    "$@" 2>&1 | green | sed "s/^/$prefix /"
}

tryssh() {
    ssh -o "StrictHostKeyChecking no" -q "$remote_machine" "exit"
}

main() {
    remote_machine=${ARGS[0]}

    echo "bootstrap-remote ${remote_machine}" | blue

    # wait for host to become available
    until tryssh; do
        echo "waiting for network connectivity..." | blue
        sleep 5
    done

    # copy bootstrap-local script to the remote machine, and execute it.
    scp -o "StrictHostKeyChecking no" -q \
        "${PROGDIR}/bootstrap-local.sh" "$remote_machine:~"
    ssh -o "StrictHostKeyChecking no" \
        "$remote_machine" "chmod +x ~/bootstrap-local.sh && ~/bootstrap-local.sh"

    # cleanup
    ssh "$remote_machine" "rm ~/bootstrap-local.sh"
}

main
