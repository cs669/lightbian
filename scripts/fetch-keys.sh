#!/usr/bin/env bash
# Downloads the signing keys for the third party VPN repos into the image.
# Keys aren't committed so they can't go stale. Compare the printed
# fingerprints against each vendor's website the first time you build.
set -euo pipefail

DEST="$(cd "$(dirname "$0")/.." && pwd)/config/includes.chroot_before_packages/usr/share/keyrings"
mkdir -p "$DEST"

fetch() {
  echo "Fetching $2"
  curl -fsSL --retry 3 -o "$DEST/$1" "$2"
}

fetch tailscale-archive-keyring.gpg https://pkgs.tailscale.com/stable/debian/trixie.noarmor.gpg
fetch mullvad-keyring.asc           https://repo.mullvad.net/deb/mullvad-keyring.asc
fetch protonvpn-keyring.asc         https://repo.protonvpn.com/debian/public_key.asc

echo
echo "Key fingerprints, check these against the vendor sites:"
for k in "$DEST"/*; do
  echo "== $(basename "$k")"
  gpg --show-keys --with-fingerprint "$k" 2>/dev/null | grep -E '^ +[0-9A-F ]{40,}' || true
done
