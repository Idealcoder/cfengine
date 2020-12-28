#!/usr/bin/env bash
# Copyright (c) 2020, Loïc Deraed

# Build and package a program from git
#
# Usage: build git-url output-file

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS=("$@")

set -e
set -o pipefail

main() {
    # check user is unprivileged
    if [ "$UID" -eq 0 ] || id -nG "$USER" | grep -qw "sudo"; then
        echo "error: must use unprivileged user for building"
        exit 1
    fi

    URL="${ARGS[0]}"
    OUTPUT="${ARGS[1]}"
     
    echo "building package for $URL"

    # work in a temporary folder
    BUILDDIR=$(mktemp -d)
    cd $BUILDDIR

    # clone code
    git clone "$URL"

    # enter folder
    cd *

    # checkout latest tag
    VERSION=$(git describe --tags)

    echo "checkout out version ${VERSION}"
    git checkout --quiet "${VERSION}"

    # compile code
    make

    # add security stub around binaries
    find -type f -executable -not -path '*/\.git/*' -execdir "${PROGDIR}/unpriv.sh" '{}' \;

    VERSION=$(echo "$VERSION" | sed -e "s/v//g")

    checkinstall --install=no \
                 --pkgsource="$URL" \
                 --pkgversion="$VERSION" \
                 --default


    # copy to output file
    echo "copy deb to $OUTPUT"

    cp *.deb "${OUTPUT}"

    echo "done"
}

main
