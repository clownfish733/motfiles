**ASUS laptop only.** Installed by `./install.sh -z`; don't use it on other machines.

- `zram-generator.conf` → `/etc/systemd/zram-generator.conf`: a zram swap
  device of half the RAM, zstd, priority 100 (used before the swap partition).
- `99-vm-zram.conf` → `/etc/sysctl.d/99-vm-zram.conf`: swappiness and
  watermark tuning for swapping to zram.

`-z` also installs the `zram-generator` package (it is not in `pkglist.txt`).
Reboot for it to take effect, then check with `zramctl` and `swapon --show`.
