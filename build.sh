#!/usr/bin/env bash
# Build a Lightbian ISO.  Usage: sudo ./build.sh [amd64|arm64]
set -euo pipefail

ARCH="${1:-amd64}"
case "$ARCH" in
  amd64|arm64) ;;
  *) echo "usage: sudo $0 [amd64|arm64]" >&2; exit 1 ;;
esac

if [ "$(id -u)" -ne 0 ]; then
  echo "live-build needs root. Run: sudo $0 $ARCH" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "$0")" && pwd)"
HOST_ARCH="$(dpkg --print-architecture)"
if [ "$HOST_ARCH" != "$ARCH" ]; then
  echo "Note: building $ARCH on a $HOST_ARCH machine. This needs qemu-user-static"
  echo "and binfmt-support installed, and it's a lot slower than a native build."
fi

"$ROOT/scripts/fetch-keys.sh"

# Each arch gets its own work folder so the package caches never mix.
WORK="$ROOT/build/$ARCH"
mkdir -p "$WORK" "$ROOT/out"
rm -rf "$WORK/auto" "$WORK/config"
cp -a "$ROOT/auto" "$ROOT/config" "$WORK/"

cd "$WORK"
lb clean
ARCH="$ARCH" lb config
lb build

mv -f ./*.iso "$ROOT/out/"
echo "Done. ISO is in $ROOT/out/"
