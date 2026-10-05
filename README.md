# Archwave QuickShell Player

A compact retro media widget for QuickShell. It controls MPRIS-compatible media players and can adjust the default audio output using `pactl`.

## Requirements

- Linux with a running graphical session
- [QuickShell](https://quickshell.org/) (Qt 6)
- An MPRIS-compatible media player for playback controls
- `pactl` for the volume and balance sliders (usually provided by `pipewire-pulse` or PulseAudio utilities)

Playback controls work independently of `pactl`; without it, the audio sliders will not be available.

## Install

Clone or download this repository, then run:

```sh
./install.sh
```

The installer places the QuickShell config in `${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/archwave-winamp` and creates `archwave-winamp` in `$HOME/.local/bin`. No root access is needed.

Launch it with:

```sh
archwave-winamp
```

Alternatively, launch the installed config directly:

```sh
quickshell --config archwave-winamp
```

If `$HOME/.local/bin` is not on your `PATH`, use `$HOME/.local/bin/archwave-winamp` or add that directory to your `PATH`.

To remove the installed files, run `./uninstall.sh` from this repository. It removes only the widget's `shell.qml` and launcher; any other files in the config directory are left untouched.

## Controls

- `<<`: rewind 10 seconds; `<`: rewind 5 seconds; `>`: play; `||`: pause; `>>`: forward 10 seconds.
- `EJ`: close the player list if open; otherwise hide the widget.
- `PL`: open or close the list of active MPRIS players. Select a row to control that player.
- `Shuffle` / `Rep`: toggle these modes when supported by the active player.
- First small slider: system output volume. Second small slider: left/right audio balance.
- Main long slider: seek within the current track.
- Click the clock to switch between 24-hour and 12-hour format.
- The clock shows the detected distribution logo. The theme button cycles Classic, Carbon, Aurora, Matrix, Arctic, and Ember; the selection is saved between launches. In compact mode, use `TH` to change themes.
- Drag any corner grip to resize the widget.

Some track controls are unavailable when the selected media player does not advertise the corresponding MPRIS capability.

## License

No license is currently included. Add a license before redistributing if you want to grant others explicit permission to use, modify, or share the code.
