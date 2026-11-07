#!/bin/sh
# Post-install setup for Acer Iconia Tab 8 W1-810 on Debian 12 (bookworm).
# Run as root from the repository root:  sudo ./setup.sh
set -eu
cd "$(dirname "$0")"

apt-get update
apt-get install -y firmware-brcm80211 firmware-intel-sound zram-tools \
    iio-sensor-proxy xinput python3-evdev onboard at-spi2-core libglib2.0-bin wget

# Wi-Fi (BCM4330): the driver looks for an NVRAM file named after the DMI model.
# The Prowise-PT301 NVRAM from firmware-brcm80211 works on this board.
ln -sf brcmfmac4330-sdio.Prowise-PT301.txt \
    "/lib/firmware/brcm/brcmfmac4330-sdio.Acer-Iconia W1-810.txt"

# Bluetooth (BCM4330B1 over UART): firmware patch from LibreELEC, verified by checksum.
HCD=/lib/firmware/brcm/BCM4330B1.hcd
wget -qO "$HCD.tmp" https://raw.githubusercontent.com/LibreELEC/brcmfmac_sdio-firmware/master/BCM4330B1.hcd
echo "6c7e8d7fab2f3dc8af24c28dbdbd92a1e6872d28b68998743db0cc5807108c5e  $HCD.tmp" | sha256sum -c -
mv "$HCD.tmp" "$HCD"

# Keep GRUB also at EFI/BOOT/BOOTIA32.EFI on future GRUB updates.
echo "grub-efi-ia32 grub2/force_efi_extra_removable boolean true" | debconf-set-selections

# Compressed swap in RAM (1 GB RAM is tight).
install -m644 config/zramswap /etc/default/zramswap
systemctl enable --now zramswap

# Touchscreen calibration (values measured on one unit; see README).
install -m644 config/99-touch-calibration.rules /etc/udev/rules.d/
udevadm control --reload

# Long press -> right click.
install -m755 scripts/longpress-rightclick /usr/local/bin/
install -m644 config/longpress-rightclick.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now longpress-rightclick

# Auto-rotation and on-screen keyboard for every XFCE session.
install -m755 scripts/autorotate /usr/local/bin/
install -m644 config/autorotate.desktop config/onboard-xfce.desktop /etc/xdg/autostart/

# Firefox: always expose accessibility so onboard can auto-show on text fields.
install -m644 config/onboard-a11y.js /etc/firefox-esr/

# On-screen keyboard on the LightDM login screen.
G=/etc/lightdm/lightdm-gtk-greeter.conf
grep -q '^keyboard=onboard' "$G" || sed -i '/^\[greeter\]/a keyboard=onboard --xid\na11y-states=+keyboard' "$G"

echo "System part done. Reboot, log in, then run ./setup-user.sh inside the desktop session."
