#!/bin/sh
# Install the MV-SILICON USB Speaker fix. Uses sudo.
set -eu
DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

echo "Installing MV-SILICON USB Speaker fix (requires sudo)..."
sudo install -m 644 "$DIR/etc/udev/rules.d/99-usb-speaker-pcm.rules" \
	/etc/udev/rules.d/99-usb-speaker-pcm.rules
sudo install -m 644 "$DIR/etc/systemd/system/reset-usb-speaker-pcm.service" \
	/etc/systemd/system/reset-usb-speaker-pcm.service
sudo install -m 755 "$DIR/bin/reset-usb-speaker-audio.sh" \
	/usr/local/bin/reset-usb-speaker-audio.sh
sudo udevadm control --reload-rules
sudo systemctl daemon-reload

echo
echo "Installed. Re-plug the speaker, or apply now with:"
echo "  sudo systemctl start reset-usb-speaker-pcm.service"
