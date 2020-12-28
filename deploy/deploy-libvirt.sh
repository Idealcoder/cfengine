#!/usr/bin/env bash
# Copyright (c) 2020, Loïc Deraed

# Create a libvirt virtual machine and deploy cfengine onto it
#
# Usage: deploy-libvirt disk_name [ssh_user] [machine_name]
#
#   Depends on 'create-vm' and 'create-config-drive' scripts on PATH
#
#   See 'create-config-drive' for libvirt virtual machine details
#
#   Disk name is managed with symlinks to keep track of easily.
#
#   An ssh_user is optional, if blank then disk name is picked, which at
#   least holds true for debian and ubuntu.
# 
#   A machine_name is optional, if blank then randomly picked from 
#   'hostnames/candidate_hostnames.txt'.

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS=("$@")

set -e
set -o pipefail

# coloured output
green() { IFS= ; while read -r line; do echo -e '\e[32m'$line'\e[0m'; done; }
blue()  { IFS= ; while read -r line; do echo -e '\e[34m'$line'\e[0m'; done; }

check_root() {
    if [ "$EUID" -ne 0 ]
        then echo "error: please run as root"
        exit 1
    fi
}

wrapped_output() {
    prefix="-->"

    "$@" \
        >  >(green | sed "s/^/$prefix /") \
        2> >(green | grep --line-buffered -v "RockRidge" \
                   | grep --line-buffered -v -e "\S" \
                   | sed "s/^/$prefix (err) /" >&2)
}

capture_output() {
    tty=$(tty)
    output=$("$@" | tee ${tty})
    echo "$output"
}

get_value() {
    echo "$2" | grep "$1" | head -n 1 \
      | awk -F '=' '{ print $2 }' | awk -F '\033' '{ print $1 }'
}

main() {
    echo "begin deploy-libvirt" | blue

    iso_dir="$DATA/vms/iso"
    disk_dir="$DATA/vms/disk"

    disk_name=${ARGS[0]}
    ssh_user=${ARGS[1]}
    machine_name=${ARGS[2]}

    check_root

    # if an ssh_user is not specified, use disk_name as fallback
    ssh_user=${ssh_user:-$disk_name}

    # if machine_name not specified, use a random hostname from 
    # 'candidate_hostnames.txt' as fallback.
    fallback_hostname="gen-$("$PROGDIR/../hostnames/pick.sh")"
    machine_name=${machine_name:-$fallback_hostname}

    echo "machine name: $machine_name" | green

    echo "create disk image" | blue

    cp "${disk_dir}/${disk_name}.qcow2" \
        "${disk_dir}/${machine_name}.qcow2"

    echo "expand disk" | blue

    wrapped_output qemu-img resize "${disk_dir}/${machine_name}.qcow2" 10G

    echo "create libvirt virtual machine" | blue
    output=$(capture_output wrapped_output create-vm "$machine_name")

    ip_address=$(get_value "ip_address" "$output")

    time "$PROGDIR/../bootstrap/bootstrap-remote.sh" "${ssh_user}@${ip_address}"

    #echo "connect to ${ip_address}" | blue
}

main
