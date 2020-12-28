#!/usr/bin/env bash
# Copyright (c) 2020, Loïc Deraed

# Weakly enforce that a program is only run by unprivileged users, by 
# inserting a shell wrapper around it.
#
# This is trivial to bypass, its purpose is to prevent untrusted binaries
# from accidentally being executed by privileged users.
# 
# Usage: unpriv program-path

readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))
readonly ARGS=("$@")

set -e
set -o pipefail

main() {
    BINARY="${ARGS[0]}"
    BINARY_B64=$(base64 "$BINARY")

    (cat <<-END
#!/usr/bin/env bash
# Copyright (c) 2020, Loïc Deraed

# This is an unpriv wrapper. Weakly enforces that the contained program is only 
# run by unprivileged users. Requires executable /tmp.

readonly PROGNAME=\$(basename \$0)
readonly PROGDIR=\$(readlink -m \$(dirname \$0))

TMP=\$(mktemp)

# check user is unprivileged
if [ "\$UID" -eq 0 ] || id -nG "\$USER" | grep -qw "sudo"; then
    echo "error: can only be run by unprivileged users"
    exit 1
fi

# copy binary to /tmp
cat "\$PROGDIR/\$PROGNAME" \
  | awk 'output {print \$0}; \$0=="exit 0" {output=1}' \
  | base64 -d \
  > "\$TMP"

# make binary executable
chmod +x "\$TMP"

"\$TMP"

exit 0
${BINARY_B64}
END
  ) > "$BINARY"

  chmod +x "$BINARY"
}

main
