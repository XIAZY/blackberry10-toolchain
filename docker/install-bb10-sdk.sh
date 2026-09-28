#!/bin/sh
set -eu

payload=/opt/bbndk

target=$(
    find "$payload" -type d -name qnx6 -print | while IFS= read -r candidate; do
        if [ -f "$candidate/usr/include/bb/cascades/Application" ] || \
           [ -f "$candidate/usr/include/bb/cascades/Application.hpp" ]; then
            printf '%s\n' "$candidate"
            break
        fi
    done
)

if [ -z "$target" ]; then
    echo "error: the bbndk build context does not contain an extracted BB10 Cascades target" >&2
    echo "expected a directory like target_10_3_1_*/qnx6/usr/include/bb/cascades" >&2
    exit 1
fi

# Install only the target-facing SDK. The compiler and GNU linker are supplied
# independently, so no Momentics host compiler or qcc installation is needed.
mkdir -p /opt/bb10-sdk/target/qnx6
cp -a "$target/." /opt/bb10-sdk/target/qnx6/

target_parent=$(dirname "$target")
if [ -d "$target_parent/target-override" ]; then
    ln -s "$target_parent/target-override" /opt/bb10-target-override
else
    mkdir -p /opt/bb10-target-override/usr/include
fi

packager=$(
    find "$payload" \( -type f -o -type l \) \
        -path '*/linux/x86/usr/bin/blackberry-nativepackager' -print | head -n 1
)

if [ -z "$packager" ]; then
    echo "error: the bbndk context must contain the Linux/x86 SDK host tools" >&2
    echo "a macOS or Windows SDK payload cannot execute inside this Linux image" >&2
    exit 1
fi

host_bin=$(dirname "$packager")
host_root=$(dirname "$(dirname "$host_bin")")
ln -s "$host_root" /opt/bb10-host

for tool in \
    blackberry-nativepackager \
    blackberry-deploy \
    blackberry-signer \
    blackberry-debugtokenrequest; do
    if [ -e "/opt/bb10-host/usr/bin/$tool" ]; then
        ln -s /usr/local/libexec/bb10-sdk-tool "/usr/local/bin/$tool"
    fi
done

# qcc is intentionally unavailable. All target code is compiled by Clang and
# linked by the independently built GNU armnto linker.
find /opt/bbndk \( -name qcc -o -name QCC \) -exec rm -f {} \;

test -d /opt/bb10-sdk/target/qnx6/armle-v7/usr/lib/qt4/lib
test -e /opt/bb10-sdk/target/qnx6/armle-v7/usr/lib/qt4/lib/libQtCore.so
test -e /opt/bb10-sdk/target/qnx6/armle-v7/usr/lib/libbbcascades.so
