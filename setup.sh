#!/bin/sh
# Post-install setup for Acer Iconia Tab 8 W1-810 on Debian 12 (bookworm).
# Run as root from the repository root:  sudo ./setup.sh
set -eu
cd "$(dirname "$0")"

apt-get update
apt-get install -y firmware-brcm80211 firmware-intel-sound zram-tools \
    iio-sensor-proxy xinput x11-utils xdotool python3-evdev onboard at-spi2-core libglib2.0-bin \
    dbus-daemon wget

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

# Touch like a Mac touchpad: one finger = mouse (tap, drag, long press = right
# click), two fingers = scroll. Also applies the touch calibration.
install -m755 scripts/touch-gestures /usr/local/bin/
install -m644 config/touch-gestures.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now touch-gestures

# Backlight: acpi_video0 is not wired to the panel. Use the native i915 backlight
# (intel_backlight), which needs the LPSS PWM driver loaded before i915.
# Then turning the screen off (DPMS) also turns the backlight off.
install -m644 config/iconia-backlight.conf /etc/modprobe.d/
for m in pwm-lpss pwm-lpss-platform; do
    grep -qx "$m" /etc/initramfs-tools/modules || echo "$m" >> /etc/initramfs-tools/modules
done
grep -q 'acpi_backlight=native' /etc/default/grub ||
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 acpi_backlight=native"/' /etc/default/grub
update-initramfs -u
update-grub

# Power button like on a phone: lock + screen off. logind must not power off.
# (Suspend/s2idle resumes with a black screen on this tablet.)
install -m755 scripts/powerbutton-lock /usr/local/bin/
install -m644 config/powerbutton-lock.service /etc/systemd/system/
install -D -m644 config/50-iconia-logind.conf /etc/systemd/logind.conf.d/50-iconia.conf
install -D -m644 config/50-iconia-powerkey.conf /etc/X11/xorg.conf.d/50-iconia-powerkey.conf
systemctl daemon-reload
systemctl enable --now powerbutton-lock

# Auto-rotation and login-screen keyboard: LightDM hooks run for every X server
# (login screen, user session, lock screen).
install -m755 scripts/autorotate scripts/lightdm-display-setup scripts/lightdm-session-setup /usr/local/bin/
install -D -m644 scripts/iconia-display.sh /usr/local/lib/iconia-display.sh
install -D -m644 config/50-iconia.conf /etc/lightdm/lightdm.conf.d/50-iconia.conf

# The greeter's built-in (embedded) keyboard turns black after rotation; don't use it.
sed -i -E '/^(keyboard=|keyboard-position=|a11y-states=)/d' /etc/lightdm/lightdm-gtk-greeter.conf

# Login-screen keyboard runs as root: docked, always on top, and locked down
# (no Preferences/Quit, which would otherwise run with root rights).
HOME=/root dbus-run-session sh -c '
  gsettings set org.onboard.window docking-enabled true
  gsettings set org.onboard.window docking-edge bottom
  gsettings set org.onboard.window force-to-top true
  gsettings set org.onboard start-minimized false
  gsettings set org.onboard show-status-icon false
  gsettings set org.onboard.icon-palette in-use true
  gsettings set org.onboard.lockdown disable-preferences true
  gsettings set org.onboard.lockdown disable-quit true
'

# On-screen keyboard in the Xfce session.
install -m644 config/onboard-xfce.desktop /etc/xdg/autostart/

# Firefox: always expose accessibility so onboard can auto-show on text fields;
# wide always-visible scrollbars; XInput2 so it gets the real touches that
# touch-gestures passes on for 1:1 two-finger panning (read at login).
install -m644 config/onboard-a11y.js config/firefox-tablet.js /etc/firefox-esr/
grep -q '^MOZ_USE_XINPUT2=' /etc/environment || echo 'MOZ_USE_XINPUT2=1' >> /etc/environment

echo "System part done. Reboot, log in, then run ./setup-user.sh inside the desktop session."
