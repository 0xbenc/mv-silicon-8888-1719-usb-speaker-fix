# MV-SILICON USB Speaker fix (USB `8888:1719`) — no sound on Linux / PipeWire

Permanent fix for a **MV-SILICON USB Speaker** that connects fine but plays **no sound** on
Linux, even though the system volume slider looks completely normal.

### Symptoms this fixes
- USB speaker is detected (`aplay -l`, `lsusb`) but is **totally silent**
- The sound slider / PipeWire volume looks fine — still no audio
- It worked before, then silently went quiet after a **reboot, replug, or suspend**
- `pavucontrol` shows the sink active and unmuted, but nothing comes out

### Affected hardware
- Any USB audio device reporting USB ID **`8888:1719`** — *"MV-SILICON USB Speaker"*.
- **MV-SILICON is the audio chip vendor**, not the speaker brand, so the same device is
  **rebadged under many brand names**. If `lsusb` shows `8888:1719`, this applies to you.
- (`8888` is a placeholder vendor ID used by low-cost OEMs — it is **not** registered with the
  USB-IF, so it isn't unique to one brand.)

---

## Root cause

Audio passes through **two** volume controls in series:

```
audio → [ PipeWire sink volume (software) ] → [ ALSA hardware "PCM" control ] → 🔊
```

If **either** is at 0, you get silence. On this speaker PipeWire selects the **digital
(`iec958`) profile**, where it can only do **software** volume — so it never touches the ALSA
hardware **`PCM`** control. Nothing else manages that control either, and it can end up stuck at
**0%**. The result: total silence while every on-screen volume looks correct.

---

## Quick manual fix

```sh
aplay -l                          # find your card number (look for "USB Speaker")
amixer -c 1 sset PCM 100% unmute  # raise the hardware PCM control (replace 1 with your card #)
```

If that restores sound, the permanent fix below stops it from happening again.

---

## Permanent fix

```sh
git clone https://github.com/0xbenc/mv-silicon-8888-1719-usb-speaker-fix.git
cd mv-silicon-8888-1719-usb-speaker-fix
./install.sh        # uses sudo
```

This installs a **udev rule** that, every time the speaker is plugged in, starts a **systemd
service** which:

1. sets the ALSA hardware **`PCM` → 100%** (the actual fix), and
2. sets the **PipeWire sink → 40%** (a sane default level; edit to taste).

Apply immediately without replugging:

```sh
sudo systemctl start reset-usb-speaker-pcm.service
```

---

## What gets installed

| File | Purpose |
|------|---------|
| `/etc/udev/rules.d/99-usb-speaker-pcm.rules` | Fires when USB `8888:1719` is plugged in; starts the service |
| `/etc/systemd/system/reset-usb-speaker-pcm.service` | Oneshot unit that runs the script |
| `/usr/local/bin/reset-usb-speaker-audio.sh` | Sets ALSA `PCM` (as root) + PipeWire volume (in the user session) |

The udev rule matches the **control device** (`controlC*`) only, so it fires **once per plug**,
and only after the ALSA mixer actually exists (no race).

---

## Configuring the levels

Edit the two variables at the top of `bin/reset-usb-speaker-audio.sh`, then re-run `./install.sh`:

```sh
PCM_VOLUME=100%   # ALSA hardware control — keep at 100% unless you have a reason not to
PW_VOLUME=40%     # PipeWire sink level applied on each plug-in
```

---

## Testing

```sh
# Drop the hardware control to 0, then fire the service exactly as udev would:
CARD=$(for f in /proc/asound/card*/usbid; do \
         [ "$(cat "$f")" = "8888:1719" ] && d=$(dirname "$f") && echo "${d##*card}"; done)
amixer -c "$CARD" sset PCM 0%
sudo systemctl start reset-usb-speaker-pcm.service
amixer -c "$CARD" sget PCM        # should read [100%]
```

For the full chain, physically re-plug the speaker and check the log:

```sh
journalctl -u reset-usb-speaker-pcm --since '2 min ago' --no-pager
```

---

## Uninstall

```sh
./uninstall.sh
```

---

## Notes & caveats

- **The PipeWire half is best-effort.** It only runs if you're logged into a desktop session
  when you plug in (that's when your user PipeWire is alive). The ALSA `PCM` half always runs.
  Plug in before login and WirePlumber restores your last sink volume on its own.
- **`8888` is a placeholder VID**, so the rule matches both vendor *and* product (`8888:1719`)
  to stay specific to this speaker chip.
- **Profile-dependent.** This targets the device's default `iec958` (digital) profile. On an
  `analog` profile, WirePlumber manages `PCM` itself and this generally isn't needed.
- Tested on Pop!_OS / Ubuntu with PipeWire + WirePlumber. Works with PulseAudio too
  (`pactl` is used for the software-volume step).

## License

MIT — see [LICENSE](LICENSE).
