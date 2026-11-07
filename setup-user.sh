#!/bin/sh
# Per-user settings. Run as your normal user inside the XFCE session:  ./setup-user.sh
set -eu

# Touch-friendly double tap: fingers move more than the default 5 px between taps.
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
