# ThinkPad battery charge limit (85/90)

A small, package-free systemd oneshot that applies an 85% start / 90% end
charge threshold to `BAT0`, plus a systemd sleep hook that re-applies the
limit after suspend and hibernate. A small GTK4 popup exposes the same
helper without adding a daemon or tray icon.

Target machine: ThinkPad E14 Gen 3, kernel 7.2.11, `thinkpad_acpi` battery
extension. The threshold attributes were verified read-only; the actual
charge-stop behavior still needs the cold tests below.

No TLP, no extra packages, no UPower/hwdb override. The system files are
root-owned copies installed with `sudo install`; they are never symlinks
into the home directory.

## Files

Repository copies live in `~/.config/battery-charge-limit/`:

| Repo file | Installed path | Mode |
|---|---|---|
| `battery-charge-limit` | `/usr/local/bin/battery-charge-limit` | `0755` |
| `battery-charge-limit.service` | `/etc/systemd/system/battery-charge-limit.service` | `0644` |
| `battery-charge-limit-sleep` | `/usr/lib/systemd/system-sleep/battery-charge-limit` | `0755` |
| `battery-charge-limit.conf` | `/etc/battery-charge-limit.conf` | `0644` |
| `battery-charge-limit-gui.py` | run in place from `~/.config/battery-charge-limit/` | `0755` |
| `battery-charge-limit-gui.desktop` | `~/.local/share/applications/battery-charge-limit-gui.desktop` | `0644` |

`/usr/lib/systemd/system-sleep/` is the path systemd 262 reads on this
machine. The hook only acts when its first argument is `post`; `pre` is
ignored.

## Install

Run these in your own terminal. They copy the files; they do not link them.

```bash
sudo install -Dm755 ~/.config/battery-charge-limit/battery-charge-limit /usr/local/bin/battery-charge-limit
sudo install -Dm644 ~/.config/battery-charge-limit/battery-charge-limit.service /etc/systemd/system/battery-charge-limit.service
sudo install -Dm755 ~/.config/battery-charge-limit/battery-charge-limit-sleep /usr/lib/systemd/system-sleep/battery-charge-limit
sudo install -Dm644 ~/.config/battery-charge-limit/battery-charge-limit.conf /etc/battery-charge-limit.conf
sudo systemctl daemon-reload
sudo systemctl enable --now battery-charge-limit.service
```

Re-running the install overwrites `/etc/battery-charge-limit.conf` with the
default `85/90`. Back up a custom permanent value first.

## Verify

```bash
systemctl status battery-charge-limit.service --no-pager
journalctl -u battery-charge-limit -b --no-pager
cat /sys/class/power_supply/BAT0/charge_control_start_threshold
cat /sys/class/power_supply/BAT0/charge_control_end_threshold
cat /sys/class/power_supply/BAT0/charge_behaviour
```

Expected: the service is `active (exited)`, the journal shows
`applied BAT0 charge thresholds: start=85 end=90 mode=config`, the
thresholds are `85` and `90`, and `charge_behaviour` is
`[auto] inhibit-charge force-discharge`.

If the threshold attributes do not exist yet, the helper retries for up to
10 seconds and then exits non-zero with a journal message. A failed service
is visible in `systemctl status` and `journalctl -u battery-charge-limit`.

Manual sleep-hook test (both write only to the battery, not to `/etc`):

```bash
# Ignored: should make no change
sudo /usr/lib/systemd/system-sleep/battery-charge-limit pre suspend

# Applied: should re-apply 85/90
sudo /usr/lib/systemd/system-sleep/battery-charge-limit post suspend
```

## Daily use

```bash
# Re-apply the values from /etc/battery-charge-limit.conf
sudo /usr/local/bin/battery-charge-limit limit

# Same as no argument (used by the service and sleep hook)
sudo /usr/local/bin/battery-charge-limit
```

## GUI

`battery-charge-limit-gui.py` is a small GTK4 popup for the same limits. It
uses the already-installed system Python 3, `python-gobject`, and GTK4; no
additional packages are needed. It is unprivileged: it reads
`/sys/class/power_supply/BAT0/` directly and calls only the root-owned helper
for changes. It reads `START`/`END` from `/etc/battery-charge-limit.conf`
(read-only) to label the buttons and recognize the configured mode.

Open it with `SUPER + SHIFT + B` or:

```bash
~/.config/battery-charge-limit/battery-charge-limit-gui.py
```

The popup is a 340x320 floating window, centered by
`hypr/windowrules.lua`. It refreshes every 3 seconds only while open; closing
it stops the timer. There is no tray icon and no background service.

Buttons:

- **Limit to 90% (recommended)** runs
  `pkexec /usr/local/bin/battery-charge-limit limit` and re-applies the
  configured 85/90 values.
- **Charge to 100% once** runs
  `pkexec /usr/local/bin/battery-charge-limit full`, the one-off 95/100
  mode. The popup marks that mode as selected and says it returns to 90%
  after the next reboot or sleep. The limit button then becomes
  **Back to 90%**.

Every change opens the polkit agent's graphical password prompt. The GUI
never runs the user-writable copy in this folder with privilege: `pkexec` is
hardcoded to `/usr/bin/pkexec` and the helper to
`/usr/local/bin/battery-charge-limit`. The GUI refuses to run if that helper
is not root-owned or is writable by a non-root user. Cancelling the prompt
or a helper error is shown inline and leaves the thresholds unchanged.

No sudoers `NOPASSWD` entry and no custom polkit rule is installed. The
session needs a polkit authentication agent; this setup runs
`polkit-gnome-authentication-agent-1`. If clicking a button does nothing,
check that an agent is running:

```bash
pgrep -fa polkit
```

### Launcher entry

The repo copy `battery-charge-limit-gui.desktop` can be installed for the
launcher without root:

```bash
install -Dm644 ~/.config/battery-charge-limit/battery-charge-limit-gui.desktop \
  ~/.local/share/applications/battery-charge-limit-gui.desktop
update-desktop-database ~/.local/share/applications 2>/dev/null || true
```

The entry points at the script in this folder. If the folder moves, update
`Exec`/`TryExec` or reinstall the entry.

## Temporary 100% before a trip

The one-off mode does **not** change `/etc/battery-charge-limit.conf`:

```bash
# Shortcut for one-off 95/100
sudo /usr/local/bin/battery-charge-limit full

# Equivalent explicit form
sudo /usr/local/bin/battery-charge-limit --now 95 100
```

After the trip, re-apply the permanent limit:

```bash
sudo /usr/local/bin/battery-charge-limit limit
```

Caveats:

- `full` and `--now` are one-off. A reboot or resume re-applies `85/90`.
  **Suspending while topping up re-applies 85/90 on resume**, because the
  sleep hook calls `limit`.
- If the battery is already above 90 when you re-apply the limit, charging
  stops but the battery is not force-discharged. It will drop to 90 with
  normal use. `charge_behaviour=force-discharge` is a separate calibration
  action and is not used here.
- If you need 100% to survive a suspend/reboot, temporarily edit
  `/etc/battery-charge-limit.conf` to `START=95` / `END=100`, run
  `sudo /usr/local/bin/battery-charge-limit limit`, and change it back
  afterward.

## Permanent change

```bash
sudoedit /etc/battery-charge-limit.conf
sudo /usr/local/bin/battery-charge-limit limit
```

Keep `START <= END`. The helper also enforces start `0..99`, end `1..100`,
and reads both values back after writing.

## UPower's cosmetic 80%

`upower -i` may report `charge-end-threshold: 80%` even when sysfs says 90.
That 80 comes from the package-owned
`/usr/lib/udev/hwdb.d/60-upower-battery.hwdb` catch-all
(`CHARGE_LIMIT=75,80`), not from the hardware. UPower's
`ChargeThresholdEnabled` is `false`; it is not writing the limit.

No hwdb override is installed. For the real value, read sysfs:

```bash
cat /sys/class/power_supply/BAT0/charge_control_end_threshold
```

## Boot, suspend, hibernate

The kernel driver reads the current thresholds from the embedded controller
at probe; Linux does not store them. Persistence across an EC reset is
therefore firmware behavior and is not assumed.

- **Boot:** the oneshot runs at `multi-user.target` and applies `85/90`.
- **Suspend/resume:** the sleep hook runs on `post` and applies `85/90`.
- **Hibernate/resume:** the same hook runs on `post` and applies `85/90`.
- **Power loss / full restore:** the boot service applies `85/90` again.

The service is `Type=oneshot` with `RemainAfterExit=yes`.

## Cold verification checklist

The parts below cannot be proven without actually charging, rebooting, and
suspending the machine.

1. **Boot:** after a reboot, confirm the service is `active (exited)` and
   both thresholds read `85` / `90`.
2. **Charge stop:** with the charger connected, watch the battery stop at
   90%:

   ```bash
   watch -n 5 'cat /sys/class/power_supply/BAT0/capacity; cat /sys/class/power_supply/BAT0/status'
   ```

   Capacity should stop at 90 and the status should no longer be
   `Charging`. The exact EC status string may be `Not charging` or
   `Discharging`.
3. **Suspend/resume:** suspend, resume, then read both thresholds again.
   Check the journal for the sleep-hook run:

   ```bash
   journalctl -b --no-pager | grep battery-charge-limit
   ```

4. **Hibernate/resume:** same check as suspend.
5. **Charge behaviour:** `charge_behaviour` should remain `[auto]`. If it
   changes, investigate UPower/PPD before changing anything else.

## Logs and troubleshooting

```bash
systemctl status battery-charge-limit.service --no-pager
journalctl -u battery-charge-limit -b --no-pager
journalctl -b --no-pager | grep battery-charge-limit
```

Common failures:

- `BAT0 threshold attributes not available after 10s` — `thinkpad_acpi`
  is not loaded or `BAT0` is missing.
- `read-back mismatch` — the EC rejected or rounded a value; check the
  current sysfs values and the kernel log.
- The service succeeded but the value later changed — check for a desktop
  charge-limit UI or a new charge-related service; none are configured here.

## Rollback

```bash
sudo systemctl disable --now battery-charge-limit.service
sudo rm -f /etc/systemd/system/battery-charge-limit.service \
           /usr/local/bin/battery-charge-limit \
           /usr/lib/systemd/system-sleep/battery-charge-limit \
           /etc/battery-charge-limit.conf
sudo systemctl daemon-reload

# Restore the ThinkPad defaults: end first, then start.
echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
echo 95  | sudo tee /sys/class/power_supply/BAT0/charge_control_start_threshold
```

No package removal is needed, and no hwdb override was installed.
