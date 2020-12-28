#!/usr/bin/env bash
# Copyright (c) 2020, Loïc Deraed

# Create a digitalocean machine and deploy cfengine onto it
#
# Usage: deploy-digitalocean [machine-name]
#
#   Argument machine_name is optional, if omitted then pick random name from
#  'hostnames/candidate_hostnames.txt'.
#
#   Further options are hard coded in config() function.

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS=("$@")

set -e
set -o pipefail

config() {
    SIZE="s-1vcpu-1gb"
    REGION="lon1"
    OS="debian-10-x64"
    SSH_USER="root"

    # key must be already added to digital ocean 
    SSH_KEY="fe:9d:b4:dc:fe:8e:99:c5:d0:3a:41:3c:9a:63:2e:d1"
}

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
    echo "begin deploy-digitalocean" | blue

    config

    # if machine_name omitted, pick random name from 
    # 'candidate_hostnames.txt' as fallback.
    FALLBACK_NAME="gen-$("$PROGDIR/../hostnames/pick.sh")"
    MACHINE_NAME="${ARGS[1]:-$FALLBACK_NAME}"

    echo "machine name: $MACHINE_NAME" | green

    echo "decrypt api token with gpg" | blue

    TOKEN=$(gpg --quiet --decrypt "$PROGDIR/../secrets/deploy.json.gpg" | jq -r .digitalocean_token)

    echo "make api request" | blue

    OUTPUT=$(curl --silent -X POST \
                 -H "Content-Type: application/json" \
                 -H "Authorization: Bearer $TOKEN" \
                 -d '{"name":"'"$MACHINE_NAME"'",
                      "region":"'"$REGION"'",
                      "size":"'"$SIZE"'",
                      "image":"'"$OS"'",
                      "ssh_keys":["'"$SSH_KEY"'"],
                      "backups":false,
                      "ipv6":true,
                      "user_data":null,
                      "private_networking":null,
                      "volumes": null,
                      "tags":["deploy-cfengine"]}' \
                    "https://api.digitalocean.com/v2/droplets")

    MACHINE_ID=$(echo "$OUTPUT" | jq -r .droplet.id)

    # wait for ip address to become available
    until [ ! -z "$IP_ADDRESS" ]; do
        echo "wait for ip address..." | blue

        MACHINE_DETAILS=$(curl --silent -X GET -H "Content-Type: application/json" \
                                 -H "Authorization: Bearer $TOKEN" \
                                 "https://api.digitalocean.com/v2/droplets/$MACHINE_ID")

        IP_ADDRESS=$(echo "$MACHINE_DETAILS" | jq -r .droplet.networks.v4[].ip_address | awk 'NR==2')

        sleep 5
    done

    echo "ip address: $IP_ADDRESS" | green

    time "$PROGDIR/../bootstrap/bootstrap-remote.sh" "${SSH_USER}@${IP_ADDRESS}"

}

main
