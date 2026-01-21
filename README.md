# Touchpad Tray Toggle - X-Seti - Oct 12 2024

A system tray applet for KDE Plasma 6 on Wayland that **actually works** to disable/enable your touchpad.

## Why This Version?

KDE Plasma 6 on Wayland **ignores** the standard `kcminputrc` settings for touchpad enable/disable. This version uses the **sysfs inhibit method** which directly controls the kernel input subsystem - it actually works!

## Quick Test

Before installing, test if it works:

```bash
chmod +x test-toggle.sh
./test-toggle.sh
```

You'll be asked for your password. After entering it, your touchpad should immediately enable or disable. Run it again to toggle back.

## Installation

```bash
chmod +x install-final.sh
./install-final.sh
```

The installer will:
- ✓ Check that your touchpad is at `/sys/class/input/event10/device/inhibited`
- ✓ Verify all dependencies
- ✓ Install to `~/.local/bin/touchpad-tray.py`
- ✓ Configure autostart
- ✓ Launch immediately

## First Use

**IMPORTANT:** The first time you click the tray icon, you'll be asked for your password via a polkit dialog. This is required to write to the system device file. After that, it remembers your authorization and won't ask again (until reboot).

## Usage

- **Left-click** the tray icon = instant toggle
- **Right-click** = menu with status
- Icon changes color when disabled
- Shows notifications on toggle

## How It Works

Instead of using KDE's broken config system, this directly writes to:
```
/sys/class/input/event10/device/inhibited
```

- Write `0` = Enable touchpad
- Write `1` = Disable touchpad

This is the same method that `xinput` would use on X11, but adapted for Wayland.

## Requirements

- KDE Plasma 6 on Wayland
- Python 3 with PyQt6
- polkit (for password authentication)

Install dependencies:
```bash
sudo pacman -S python-pyqt6 polkit
```

## Troubleshooting

**Icon doesn't appear?**
- Check if running: `pgrep -f touchpad-tray.py`
- Run manually to see errors: `~/.local/bin/touchpad-tray.py`

**Toggle doesn't work?**
- Make sure you entered your password in the polkit dialog
- Verify your touchpad is at event10: `cat /proc/bus/input/devices | grep -A 5 -i touchpad`

**Wrong event device?**
If your touchpad is NOT at event10, edit `touchpad-tray-final.py` and change line 10:
```python
EVENT_DEVICE = "event10"  # Change this to your event number
```

## Uninstall

```bash
rm ~/.local/bin/touchpad-tray.py
rm ~/.config/autostart/touchpad-tray.desktop
pkill -f touchpad-tray.py
```

## Why Does This Need Root?

Writing to `/sys/class/input/*/device/inhibited` requires root privileges because it directly controls hardware. The `pkexec` tool provides a secure way to get this privilege using polkit - you only authenticate once per session.
