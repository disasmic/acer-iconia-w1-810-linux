# Debian on Acer Iconia Tab 8 (W1-810)

Step-by-step install of Debian 12 (Xfce) on the Acer Iconia Tab 8 W1-810, plus the fixes that make the tablet usable without a keyboard.

[Русская версия](README.ru.md)

## What works

| Component | Status | How |
|---|---|---|
| Boot from eMMC | ✅ | 32-bit GRUB plus a manual `BootOrder` fix ([step 5](#5-fix-no-bootable-device)) |
| Wi-Fi (BCM4330 SDIO) | ✅ | Prowise-PT301 NVRAM linked under the model name |
| Bluetooth (BCM4330B1 UART) | ✅ | `BCM4330B1.hcd` patch from LibreELEC |
| Sound (RT5640, speakers) | ✅ | `firmware-intel-sound` (kernel already has a W1-810 quirk) |
| Touchscreen (Goodix) | ✅ | Works as is; optional calibration |
| Auto-rotation (BMA222E) | ✅ | `iio-sensor-proxy` + `scripts/autorotate`, also on login and lock screens |
| Right click | ✅ | Long press, via `scripts/longpress-rightclick` |
| On-screen keyboard | ✅ | `onboard` with auto-show in the session; docked keyboard on login and lock screens |
| Cameras (2× Himax HM2056) | ❌ | No sensor driver, ISP hidden by firmware; use a USB webcam ([notes](#notes)) |

## Hardware quirks to know

- **32-bit UEFI on a 64-bit CPU.** The ISO must contain `EFI/boot/bootia32.efi`. **Debian 12 netinst has it. Debian 13 does not.**
- **The internal eMMC is `mmcblk1`**, not `mmcblk0`.
- **The firmware does not add Debian to its boot order**, so you get "No bootable device" after installing. Step 5 fixes this.
- **The only USB port is micro-USB OTG.** Use an OTG hub, preferably a powered one if you plug in a flash drive, a keyboard and an Ethernet adapter.

## 1. Prepare

- **ISO:** [`debian-12.15.0-amd64-netinst.iso`](https://cdimage.debian.org/cdimage/archive/12.15.0/amd64/iso-cd/debian-12.15.0-amd64-netinst.iso)
  SHA256 `cd4462c06aa8892e692c0c4b9c17802f38c8ab8690e85cbfb5ccaa5956e9af17`
- **Write it in Rufus:** partition scheme **GPT**, target **UEFI (non-CSM)**, and **DD image mode** when asked. Don't use Ventoy: the installer failed while copying files.
- **Have a USB keyboard and a USB Ethernet adapter.** Wi-Fi did not connect inside the installer.

## 2. BIOS

1. Power on while holding **Volume Up**.
2. **Security:** set a **Supervisor Password**. Without one, the other options are locked.
3. **Boot:** set **Secure Boot** to **Disabled**, and move **USB HDD** to the top.
4. Press **F10** to save.

## 3. Install

1. Boot the stick and choose **Install**.
2. **Network:**
   - plug in the Ethernet adapter before network detection and pick `eth0` or `enx…`;
   - answer "No" to the missing-firmware prompt.
3. **Partitioning:** Guided, use entire disk **`mmcblk1`**, all files in one partition.
4. **Software:** **Xfce**, **SSH server**, and standard utilities. Uncheck GNOME: it is too heavy for 1 GB RAM.
5. "Configuring linux-image…" takes 10–30 minutes. Wait.
6. Reboot. "No bootable device" is expected at this point.

## 4. Rescue mode

1. Boot the stick and choose **Advanced options → Rescue mode**.
2. Skip network configuration:
   - choose "Go Back" → "Do not configure the network";
   - or add `netcfg/enable=false` to the kernel line (press `e` on the menu entry).
3. **Root file system:** `/dev/mmcblk1p2`.
4. Mount `/boot/efi`: **Yes**.
5. Choose **Execute a shell in /dev/mmcblk1p2**.

## 5. Fix "No bootable device"

```sh
grub-install --target=i386-efi --efi-directory=/boot/efi --force-extra-removable
update-grub
mount -t efivarfs efivarfs /sys/firmware/efi/efivars
efibootmgr -v
```

In the output, find two entries:
- **`Unknown Device`**: `PciRoot(0x0)/Pci(0x17,0x0)/…/HD(1,GPT,…)`
- **`debian`**: `…\EFI\debian\grubia32.efi`

They exist but are missing from `BootOrder`. Put them first, using your own numbers and **no spaces**:

```sh
efibootmgr -o 0001,0002,2001,2002,2003
```

Type `exit`, reboot, and remove the stick. Debian boots.

If there is no `Unknown Device` entry, register the file in BIOS:
1. Temporarily enable Secure Boot.
2. In Security, use **Select an UEFI file as trusted** → `HDD0/EFI/debian/grubia32.efi`.
3. Disable Secure Boot again.

## 6. Post-install setup

With Ethernet connected, log in and run:

```sh
sudo apt install git
git clone https://github.com/disasmic/acer-iconia-w1-810-linux.git
cd acer-iconia-w1-810-linux
sudo ./setup.sh
sudo reboot
# after logging in to the desktop:
./setup-user.sh
```

**No `sudo`?** If you set a root password during install, your user is not in the `sudo` group. Add it with:
```sh
su - -c "/usr/sbin/usermod -aG sudo $USER"
```
Then log in again.

`setup.sh` (as root):
- installs firmware and tools;
- sets up Wi-Fi NVRAM and the Bluetooth patch (checksum-verified);
- configures zram, touch calibration and the long-press service;
- installs LightDM hooks for auto-rotation and the login/lock-screen keyboard;
- enables onboard in the Xfce session and Firefox accessibility.

`setup-user.sh` (in the session):
- tap to open on the desktop and in Thunar; easier double click for other apps (30 px / 500 ms);
- onboard auto-show settings.

Then connect to Wi-Fi from the panel icon.

## Notes

- **Touch calibration** in `config/99-touch-calibration.rules` was measured on one unit (it fixed a ~12 px vertical offset). If taps feel off on your tablet, run `xinput_calibrator -v`, take the four click positions and fit a new `LIBINPUT_CALIBRATION_MATRIX`. Or delete the rule.
- **Tap to open.** GTK3 turns touch events into emulated clicks but never into double clicks, so double tap can't open files. The desktop and Thunar use single-click mode instead, like phones and tablets: tap opens, long press opens the menu.
- **Long press** sends the right click after the finger is held still for 0.6 s, **while it is still down**. The context menu opens and grabs the pointer, so lifting the finger doesn't "tap" the item (which would open it in single-click mode) and a multi-selection is kept.
- **Onboard auto-show** needs `tablet-mode-detection-enabled=false`. Otherwise onboard waits for a tablet-mode switch this device doesn't have.
- **Login/lock-screen keyboard.** The greeter's built-in keyboard (`onboard --xid`) turns black after rotation. Instead, a LightDM `display-setup-script` starts a docked, always-on-top onboard as root once the greeter window appears, and `session-setup-script` closes it at login. Because it runs as root, its Preferences and Quit are locked down. The × button hides it behind a small floating icon. The lock screen runs on its own X server (`:1`), so the hooks only touch processes of their own display.
- **Cameras don't work and likely won't.** Both are Himax HM2056 sensors (`HIMX2056:00/01`, seen on I2C). Mainline Linux has no HM2056 driver (only an old Android port, see [kernel bug 195877](https://bugzilla.kernel.org/show_bug.cgi?id=195877)). The Bay Trail camera ISP that `atomisp` needs is not exposed at all (no PCI `8086:0f38`, no ACPI device), so there is no `/dev/video*`. A USB (UVC) webcam via the OTG hub works out of the box.
- **Firmware blobs are not stored here.** They come from Debian packages, and the BT patch is downloaded from [LibreELEC/brcmfmac_sdio-firmware](https://github.com/LibreELEC/brcmfmac_sdio-firmware).

## Files

```text
setup.sh                         system setup (root)
setup-user.sh                    per-user settings (inside Xfce session)
scripts/autorotate               screen + touch rotation from accelerometer
scripts/longpress-rightclick     long press -> right click (python3-evdev, uinput)
scripts/lightdm-display-setup    LightDM hook: autorotate + login-screen keyboard
scripts/lightdm-session-setup    LightDM hook: close login-screen keyboard at login
scripts/iconia-display.sh        shared helper: stop helpers of one X displayconfig/50-iconia.conf            LightDM: enables the two hooks
config/longpress-rightclick.service
config/99-touch-calibration.rules
config/zramswap
config/onboard-a11y.js           Firefox: force accessibility on
config/onboard-xfce.desktop      Xfce autostart for onboard
```
