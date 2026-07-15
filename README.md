# red-level

`red-level` is a small command-line utility for software display dimming and
independent red, green, and blue channel control.

It supports macOS, Windows, and Linux/X11. On macOS and Linux, invoking the
utility starts a detached background process by default.

## Build

Install Rust, clone the repository, and build a release binary:

```sh
./install
```

The installer builds a release binary and copies it to a user-local directory
without `sudo`:

- macOS and Linux: `$XDG_BIN_HOME` or `~/.local/bin`
- Windows under Git Bash, MSYS2, or Cygwin:
  `%LOCALAPPDATA%\red-level\bin`

Override the destination when needed:

```sh
RED_LEVEL_INSTALL_DIR="$HOME/bin" ./install
```

To build without installing, run `cargo build --release`. The binary is
written to `target/release/red-level` (`red-level.exe` on Windows).

Linux builds require the X11 and XRandR development libraries. For example:

```sh
# Debian and Ubuntu
sudo apt install libx11-dev libxrandr-dev

# Fedora
sudo dnf install libX11-devel libXrandr-devel

# Arch Linux
sudo pacman -S libx11 libxrandr
```

## Usage

Running `red-level` without a lifecycle option starts the filter in the
background. If it is already running, the existing process is stopped and
replaced.

```sh
# Start with all channels at full strength
red-level

# Start using only one color channel
red-level --red
red-level --green
red-level --blue

# Set independent RGB levels from 0 to 100 percent
red-level --levels 100 30 10

# Combine channel levels with overall software brightness
red-level --brightness 50 --levels 100 40 20

# Stop the background process and restore the display
red-level --stop

# Restore the default gamma curves without managing the process
red-level --reset
```

`--red-only` and its short form, `-r`, are retained as aliases for `--red`.
The channel preset flags and `--levels` are mutually exclusive.

## Options

| Option | Description |
| --- | --- |
| `-b, --brightness <1-100>` | Set overall software brightness. |
| `-r, --red-only` | Use only the red channel. |
| `--red` | Use only the red channel. |
| `--green` | Use only the green channel. |
| `--blue` | Use only the blue channel. |
| `--levels <RED> <GREEN> <BLUE>` | Set each channel from 0 to 100 percent. |
| `--start` | Explicitly start or restart the detached process. |
| `--stop` | Stop the detached process and restore the display. |
| `--reset` | Restore standard brightness and color levels. |

## Platform notes

- **macOS:** Uses CoreGraphics display transfer tables.
- **Windows:** Uses GDI device gamma ramps. Background process management is
  currently unavailable.
- **Linux:** Uses X11 RandR gamma ramps and requires an active X11 display.
  Native Wayland compositors are not currently supported.

Display servers, HDR modes, color-management services, and graphics drivers
may override software gamma changes.
