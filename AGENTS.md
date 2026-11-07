# AGENTS.md

Notes for anyone (human or AI) changing this repository.

## What this repo is

Install guide and post-install setup for Debian 12 + Xfce on the Acer Iconia Tab 8 W1-810
(Bay Trail, 32-bit UEFI, 1 GB RAM). `setup.sh` (root) and `setup-user.sh` (session) must
reproduce the working tablet state on a fresh install.

## Rules

- **Test on the real tablet before committing.** Deploy changed files, check the result
  (screenshots of the login screen: `DISPLAY=:0 XAUTHORITY=/var/run/lightdm/root/:0 scrot`).
- **`setup.sh` must stay idempotent**: running it twice must not duplicate config lines or autostarts.
- **POSIX `sh`** for scripts (no bashisms); check with `sh -n`.
- **No firmware blobs and no secrets** in the repo. Firmware comes from Debian packages or is
  downloaded with a SHA256 check.
- **Process matching:** never use a bare `pkill -f <name>` over SSH: the pattern also matches
  the SSH command line and kills the session. Anchor patterns (`'^/usr/bin/python3 /usr/bin/onboard'`).
- **Multiple X servers:** the lock screen runs on `:1`. Hooks must only touch processes of
  their own `$DISPLAY` (see `scripts/iconia-display.sh`).
- Keep README.md and README.ru.md in sync.
