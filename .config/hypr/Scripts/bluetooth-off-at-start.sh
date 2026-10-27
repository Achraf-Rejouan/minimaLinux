#!/bin/bash

# Turn the Bluetooth adapter off once per Hyprland session.
# Polls for bluetoothd/the adapter (up to ~30 s) instead of a blind sleep,
# and is a no-op when it is already off. Uses BlueZ adapter power, the same
# path as Noctalia's Bluetooth toggle, so manual enable keeps working.

for _ in $(seq 1 60); do
    SHOW=$(bluetoothctl show 2>/dev/null)

    if [[ "$SHOW" == *"Controller "* ]]; then
        if [[ "$SHOW" == *"Powered: yes"* ]]; then
            bluetoothctl power off >/dev/null 2>&1
        else
            exit 0
        fi
    fi

    sleep 0.5
done

exit 1
