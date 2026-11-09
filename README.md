# Lightbian

A light Debian 13 based system for laptops and mini PCs.  It's a media box first, but it'll handle anything you'd do in a browser, and it's locked down out of the box.

It boots from a USB stick and copies itself into RAM when there's enough memory, so it runs fast and you can pull the stick.  If you want it permanent, there's an installer on the desktop that puts it on the drive with full disk encryption.

## What's in it

| Area | What you get |
|---|---|
| Desktop | Xfce, plus Kodi as a TV style front end |
| Browsers | Firefox ESR and Chromium (Chromium is the one that can cast a tab to a Chromecast) |
| Video | mpv, VLC, Kodi, yt-dlp, with hardware decoding on Intel and AMD |
| Casting out | `catt` for Chromecast, GNOME Network Displays for Miracast |
| Casting in | UxPlay starts at login so phones and Macs can AirPlay to it |
| VPN | Tailscale for your Headscale server, Mullvad, Proton VPN (x86_64), WireGuard tools |
| Wi‑Fi | NetworkManager on iwd, all the non‑free firmware, MAC address privacy |
| Encryption | LUKS2 with argon2id on install, encrypted swap file |
| Hardening | nftables firewall that blocks everything incoming except casting on your home network and Tailscale, AppArmor, kernel hardening flags and sysctls, no SSH server, no core dumps, automatic security updates |

## Building

You need a Debian 13 machine (a VM is fine) with about 20 GB free.

```sh
sudo apt install live-build curl gnupg
sudo ./build.sh amd64     # or arm64
```

The ISO lands in `out/`.  Write it to a USB stick with `dd`, Rufus, or balenaEtcher.

The first time, `build.sh` prints the fingerprints of the Tailscale, Mullvad and Proton signing keys.  Check them against each company's website before you trust the image.

### ARM builds

Build arm64 on an ARM machine if you can.  Building it on an x86 box works, but you need `qemu-user-static` and `binfmt-support` installed and it's several times slower.

The arm64 ISO boots on UEFI ARM machines.  A Raspberry Pi won't boot it unless you put UEFI firmware on the Pi first.

### GitHub Actions

`.github/workflows/build.yml` builds both ISOs.  Run it from the Actions tab or push a tag like `v0.1`.  The ARM job uses GitHub's `ubuntu-24.04-arm` runner, which is free on public repos but needs a paid plan on private ones.  If it won't start, delete that matrix entry and build ARM locally.

## Using it

**RAM copy.**  On boot it copies itself to RAM if that still leaves 2 GiB free.  If it doesn't, it just runs from the stick.  To skip the copy for one boot, press `e` at the boot menu and delete `toram` from the kernel line.

**Installing.**  Run the installer from the menu and tick **Encrypt system**.  You'll get an unencrypted 1 GiB `/boot` (GRUB can't unlock argon2id), and everything else is LUKS2.

**Tailscale with Headscale.**  It's off until you turn it on:

```sh
sudo systemctl enable --now tailscaled
sudo tailscale up --login-server https://your-headscale-domain
```

**Mullvad.**  `sudo systemctl enable --now mullvad-daemon`, then open the Mullvad app.  Turn on **Local network sharing** in its settings or casting stops working while it's connected.  Don't run Mullvad and Tailscale at the same time unless you've set up split tunneling, they fight over routing.

**Proton VPN.**  Open the Proton VPN app on x86_64.  On ARM, download WireGuard configs from your Proton account and import them in NetworkManager.

**Wi‑Fi trouble or flaky Miracast.**  Delete `/etc/NetworkManager/conf.d/10-iwd.conf` and reboot to switch back to wpa_supplicant.

**AirPlay receiver.**  It's only reachable from your home network.  If you don't want it, delete `/etc/xdg/autostart/uxplay.desktop`.

## Layout

```
auto/config                  live-build options (arch, boot flags, image name)
build.sh                     builds one arch in build/<arch>/
scripts/fetch-keys.sh        downloads the VPN repo signing keys
config/package-lists/        what gets installed
config/archives/             Tailscale, Mullvad and Proton apt repos
config/hooks/normal/         RAM headroom patch, service setup
config/includes.chroot/      firewall, sysctl, NetworkManager, installer and update settings
```

## Not tested yet

None of this has been built yet.  Do the first build in a VM and check these before trusting it on real hardware:

1. The whole package list resolves on both arches (recommends are off to keep it light, so something small might be missing).
2. The installer really leaves `/boot` plain and encrypts `/` when you tick Encrypt system.
3. The Mullvad and Proton packages install cleanly inside the build chroot.
4. Miracast works with iwd on your Wi‑Fi card.
