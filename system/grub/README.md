FILE_LOCATION: /boot/grub/themes

/etc/default/grub add line: GRUB_THEME="/boot/grub/themes/minimal/theme.txt"

cp 29_windows /etc/grub.d/29_windows
chmod +x /etc/grub.d/29_windows
grub-mkconfig -o /boot/grub/grub.cfg


