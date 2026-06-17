#!/bin/sh
# Remove the MV-SILICON USB Speaker fix. Uses sudo.
set -eu

echo "Removing MV-SILICON USB Speaker fix (requires sudo)..."
sudo rm -f /etc/udev/rules.d/99-usb-speaker-pcm.rules
sudo rm -f /etc/systemd/system/reset-usb-speaker-pcm.service
sudo rm -f /usr/local/bin/reset-usb-speaker-audio.sh
sudo udevadm control --reload-rules
sudo systemctl daemon-reload

echo "Removed."
