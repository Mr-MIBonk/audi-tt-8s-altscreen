#!/bin/sh
# Native build of the CarPlay hook (libaltscreen111.so) and renderer (cluster_runtime) for the
# head unit (QNX 6.5, armle-v7), on Windows via WSL (Ubuntu). Run inside WSL as root:
#   wsl -d Ubuntu-24.04 -u root sh /mnt/c/<path>/ports/tt-8s-mu1462/scripts/wsl-native-build.sh <step>
#
# Steps (each can be rerun):
#   tools    install Docker in the WSL Ubuntu (once)
#   image    build the QNX 6.5 GCC 4.9 toolchain image from qnx65-armv7-toolchain (once, long:
#            it compiles GCC; every download in its Dockerfile is pinned by sha256)
#   native   compile carplay/src/native with upstream's scripts/compile-native.sh into
#            carplay/out/native, then compare with the shipped binaries in carplay/bin
#
# TOOLCHAIN: folder of the qnx65-armv7-toolchain checkout (luka-dev/qnx65-armv7-toolchain).
# REPO:      this repository's root.
set -eu
STEP=${1:-}
REPO=${REPO:-$(cd "$(dirname "$0")/../../.." && pwd)}
TOOLCHAIN=${TOOLCHAIN:-}
IMG=qnx65-armv7-toolchain:4.9
UPSTREAM_TAG=mhi2-qnx65-armv7-public:4.9   # the tag carplay/scripts/build-native.sh expects

case "$STEP" in
tools)
    apt-get update
    apt-get install -y --no-install-recommends docker.io ca-certificates file binutils
    # WSL with systemd starts dockerd itself; without it, start it by hand.
    (systemctl enable --now docker 2>/dev/null) || (pgrep dockerd >/dev/null || (dockerd >/var/log/dockerd.log 2>&1 &))
    sleep 3
    docker version
    ;;
image)
    test -n "$TOOLCHAIN" || { echo 'Set TOOLCHAIN=/mnt/c/.../qnx65-armv7-toolchain'; exit 2; }
    cd "$TOOLCHAIN"
    sh host-scripts/qnx-run.sh build 4.9
    docker tag "$IMG" "$UPSTREAM_TAG"
    docker run --rm "$UPSTREAM_TAG" arm-unknown-nto-qnx6.5.0eabi-gcc --version | head -1
    ;;
native)
    cd "$REPO/carplay"
    docker run --rm --platform=linux/amd64 -v "$PWD:/w" -w /w "$UPSTREAM_TAG" \
        sh -c 'command -v qcc >/dev/null || ln -sf "$(command -v arm-unknown-nto-qnx6.5.0eabi-gcc)" /usr/local/bin/qcc; bash scripts/compile-native.sh'
    for f in libaltscreen111.so cluster_runtime; do
        echo "== $f"
        ls -l "bin/$f" "out/native/$f"
        file "out/native/$f" || true
        # Same exports and imports as the shipped build? (code bytes will differ)
        for b in "bin/$f" "out/native/$f"; do
            readelf --dyn-syms -W "$b" | awk 'NR>3 && $8 != "" {print $5, $7=="UND"?"U":"D", $8}' | sort > "$b.syms"
        done
        diff "bin/$f.syms" "out/native/$f.syms" && echo "   symbols: identical" || echo "   symbols: DIFFER (see above)"
        rm -f "bin/$f.syms" "out/native/$f.syms"
    done
    ;;
*)
    echo 'usage: wsl-native-build.sh tools | image | native'; exit 2;;
esac
