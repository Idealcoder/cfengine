#!/usr/bin/env bash
# Copyright (c) 2020, Loïc Deraed

# Bootstrap cfengine onto local machine
#
# Usage: bootstrap-local

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS="$@"

set -e
set -o pipefail

# coloured output
green() { IFS= ; while read -r line; do echo -e '\e[32m'$line'\e[0m'; done; }
blue()  { IFS= ; while read -r line; do echo -e '\e[34m'$line'\e[0m'; done; }

wrapped_output() {
    prefix="-->"
    "$@" 2>&1 \
      | green \
      | stdbuf -oL -eL sed "s/^/$prefix /"
}

main() {
    # try sudo if not root
    [ "$UID" -eq 0 ] || exec sudo "$0" "$@"

    hostname=$(cat /etc/hostname)

    echo "bootstrap-local machine $hostname" | blue

    echo "install dependencies..." | blue
    export DEBIAN_FRONTEND="noninteractive"
    wrapped_output apt-get --quiet update
    wrapped_output apt-get --quiet install --no-install-recommends --yes \
        git gpg gpg-agent dirmngr cfengine3 usrmerge apt-utils

    echo "import admin public key" | blue
    gpg_key="CFCBB3696FE1AB6787806FEE4EEE428DE1354DCF"
    wrapped_output gpg --batch \
        --keyserver keys.openpgp.org \
        --recv-keys "$gpg_key"

    # hack to non-interactively trust gpg key
    echo "$gpg_key:6:" | wrapped_output gpg --import-ownertrust

    echo "import shared secret keys" | blue
    wrapped_output gpg --import ${PROGDIR}/keys/shared/*

    echo "clone cfengine repo" | blue
    cd "/var/lib/cfengine3/inputs"
    wrapped_output git clone -v "https://github.com/Idealcoder/cfengine" .

    echo "running cf-agent" | blue
    wrapped_output cf-agent

    echo "finished." | blue
}

main
