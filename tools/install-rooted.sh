#!/bin/sh
# Install a .bar on a BB10 phone rooted with bb10mt, using the phone's own
# package installer over SSH. For rooted phones this is preferred over the
# Java blackberry-deploy tool: no Development Mode password, no legacy-TLS
# workarounds and no Java on the host.
#
# usage: tools/install-rooted.sh <ssh-host> <package.bar>
#   <ssh-host> is anything ssh accepts (user@ip, or a Host from ~/.ssh/config)
#   and must reach a root shell on the phone.
set -eu

host=${1:?usage: $0 <ssh-host> <package.bar>}
bar=${2:?usage: $0 <ssh-host> <package.bar>}
[ -f "$bar" ] || { echo "error: no such package: $bar" >&2; exit 1; }

remote="/tmp/$(basename "$bar")"
scp -q "$bar" "$host:$remote"

# sud_install_package_2 comes from the phone's /base/scripts/sudtools.sh. The
# phone's sh lacks many utilities, so run it under ksh, and judge success by
# its log line rather than its exit status.
output=$(ssh "$host" "/bin/ksh -c '. /base/scripts/sudtools.sh; sud_install_package_2 -T 120 -D -p \"$remote\"'; rm -f \"$remote\"" 2>&1) || true
if printf '%s\n' "$output" | grep -q "Sucessfully installed"; then
    echo "installed: $(basename "$bar") on $host"
else
    printf '%s\n' "$output" >&2
    echo "error: installation failed" >&2
    exit 1
fi
