#!/usr/bin/env bash
# Copyright (c) 2020, Loïc Deraed

# Bootstrap cfengine onto local machine
#
# Usage: bootstrap-local

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

main() {
    # try sudo if not root
    [ "$UID" -eq 0 ] || exec sudo "$0" "$@"

    hostname=$(cat /etc/hostname)

    echo "bootstrap machine $hostname" | blue

    echo "install dependencies..." | blue
    export DEBIAN_FRONTEND="noninteractive"
    wrapped_output apt-get update --quiet
    wrapped_output apt-get install --quiet --no-install-recommends --yes \
        git gpg gpg-agent dirmngr cfengine3

    echo "add trusted gpg key" | blue
    wrapped_output gpg --keyserver  keys.gnupg.net \
        --recv-keys CFCBB3696FE1AB6787806FEE4EEE428DE1354DCF

    echo "clone cfengine repo" | blue
    cd "/var/lib/cfengine3/inputs"
    wrapped_output git clone -v "https://github.com/Idealcoder/cfengine" .

    echo "finished."
}

main
