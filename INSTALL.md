# Installing on a fresh machine

`install.sh` does everything it can. This file is the rest: the base Arch
install that has to exist before the script can run, and the few things after
it that need a person, a browser or a reboot.

## 1. Before: base Arch install

From the Arch ISO.

```sh
setfont ter-132n                     # readable console on a HiDPI panel
iwctl                                # wifi only:
#   station wlan0 get-networks
#   station wlan0 connect <SSID>
pacman -Sy archlinux-keyring

cfdisk /dev/<drive>                  # efi 1G · swap = RAM · root = rest
mkfs.fat -F 32 /dev/<efi>
mkfs.ext4 /dev/<root>
mkswap /dev/<swap> && swapon /dev/<swap>
mount /dev/<root> /mnt
mount --mkdir /dev/<efi> /mnt/efi
mount --mkdir /dev/<windows-efi> /mnt/windows   # dual boot only

pacstrap -K /mnt base base-devel linux linux-firmware sudo git networkmanager grub efibootmgr vim
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
```

In the chroot:

```sh
passwd
useradd -m -g users -G wheel,storage,video,audio -s /bin/bash clownfish73
passwd clownfish73
EDITOR=vim visudo                    # uncomment: %wheel ALL=(ALL:ALL) ALL

ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
vim /etc/locale.gen                  # uncomment en_GB.UTF-8
locale-gen
echo LANG=en_GB.UTF-8 > /etc/locale.conf
echo <hostname> > /etc/hostname      # and 127.0.1.1 <hostname>.localdomain <hostname> in /etc/hosts

grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
systemctl enable NetworkManager
exit
umount -R /mnt && reboot
```

Microcode is left out of pacstrap on purpose: `install.sh` picks `intel-ucode`
or `amd-ucode` from the CPU and regenerates grub.cfg afterwards.

## 2. The script

Log in as your user (not root), get online (`nmtui`), then:

```sh
git clone https://github.com/clownfish733/motfiles.git ~/motfiles
cd ~/motfiles
./install.sh          # add -w on the tower for the Windows grub entry,
                      # -l on a low-spec machine to skip Firefox/Waterfox
```

Reinstalling a machine? Grab its old install date first, so fastfetch's
"OS Age" keeps counting from it instead of restarting at 0:

```sh
cat ~/.local/state/fastfetch/install_date 2>/dev/null || stat -c %W /   # on the old install
./install.sh -a <that number>                                           # on the new one
```

It asks for the sudo password once, and `chsh` may ask for yours. Everything
else runs unattended. The Haskell toolchain is the slow part.

It also turns off the reboot watchdog (`/etc/systemd/system.conf.d/`) and
strips the "Loading Linux / initial ramdisk" echoes from
`/etc/grub.d/10_linux`. A grub package update restores that file, so rerun
`./install.sh -n` after one to hide them again.

## 3. After

**Test the greeter before rebooting.** greetd is enabled for next boot, and a
greeter that fails to start leaves you unable to log in. On a spare VT
(`Ctrl+Alt+F3`, log in):

```sh
setvtrgb /etc/greetd/vtrgb
/usr/local/bin/tuigreet --mock       # Ctrl+C to leave; setvtrgb default to reset
```

If it's broken, set `command = "tuigreet"` in `/etc/greetd/config.toml` to fall
back to the packaged greeter. Then reboot.

Once in sway:

- **GitHub** — `gh auth login`. `.gitconfig` uses gh as the credential helper,
  so pushing fails until this is done.
- **qutebrowser** — run `:adblock-update` once to fetch the block lists.
- **Firefox** (not with `-l`) — qutebrowser stays the default browser.
  `install.sh` creates the profiles and installs the add-ons in
  `extensions.txt` into `default-release` and `firefox-clone`; `firefox-basic`
  is left stock. Still by hand, in each configured profile:
  - [Bypass Paywalls Clean](https://gitflic.ru/project/magnolia1234/bypass-paywalls-firefox-clean#installation)
    — not on addons.mozilla.org, install the signed .xpi from that page.
  - The `udm=14` Google search engine (Settings → Search → Add,
    `https://www.google.com/search?q=%s&udm=14`, then make it default).
  - Log in to Surfshark.

  If the add-ons didn't show up, check `firefox-profile-setup` reported
  `default-release` (rerun it after starting Firefox once if not).
- **Waterfox** — add-ons by hand from addons.mozilla.org (same list as
  `~/.config/firefox-profile/extensions.txt`); none of the Firefox config
  applies to it.
- **nvim** — open it once and let the treesitter parsers compile (they start
  on launch; plugins and Mason servers are already installed).

### Only on some machines

- **Windows dual boot (`-w`)** — `system/grub/29_windows` hardcodes the Windows
  EFI partition's UUID (`F464-947D`, the tower's). On any other machine, replace
  it with the output of `lsblk -no UUID /dev/<windows-efi>` before running
  `install.sh -w`.
- **Laptop panel names** — sway pins workspaces 1–5 to `eDP-1`. Check the
  output names with `swaymsg -t get_outputs` and edit
  `home/sway/.config/sway/config` if they differ.

### Optional

- **YouTube downloads in vicky** — `cookiesFrom` in
  `home/quickshell/.config/quickshell/vicky/Config.qml` is `""` (anonymous).
  If YouTube starts asking you to sign in to prove you're not a bot, install
  Firefox, log in to YouTube there and set it to `"firefox"`.
- **qutebrowser `,r` (reader mode)** —
  `sudo npm install -g @mozilla/readability jsdom qutejs`.
