#!/bin/sh
# Per-user settings. Run as your normal user inside the XFCE session:  ./setup-user.sh
set -eu

# Touch model like on phones: tap opens, long press opens the menu.
# (GTK3 never builds double clicks from touch events, so double tap can't work.)
xfconf-query -c xfce4-desktop -p /desktop-icons/single-click -n -t bool -s true
xfconf-query -c thunar -p /misc-single-click -n -t bool -s true
xfconf-query -c thunar -p /misc-single-click-timeout -n -t uint -s 0   # no hover-select
# Double click is still used by other apps; make it easier to hit with a finger.
xfconf-query -c xsettings -p /Net/DoubleClickDistance -n -t int -s 30
xfconf-query -c xsettings -p /Net/DoubleClickTime -n -t int -s 500

# Accessibility bus: lets onboard see which widget has focus.
xfconf-query -c xfce4-session -p /general/StartAssistiveTechnologies -n -t bool -s true
gsettings set org.gnome.desktop.interface toolkit-accessibility true

# Onboard: show on text fields, docked at the bottom, tray icon.
# The tablet has no tablet-mode switch, so tablet-mode detection must be off.
gsettings set org.onboard.auto-show enabled true
gsettings set org.onboard.auto-show tablet-mode-detection-enabled false
gsettings set org.onboard start-minimized true
gsettings set org.onboard show-status-icon true
gsettings set org.onboard status-icon-provider GtkStatusIcon
gsettings set org.onboard.window docking-enabled true
gsettings set org.onboard.window docking-edge bottom

echo "Done. Log out and log back in."
