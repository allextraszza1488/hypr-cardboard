# hypr-cardboard

Play a PC game in a Google Cardboard headset with your phone.

```
  PC (Hyprland)                                 phone in Cardboard
  ┌────────────────┐   Sunshine    Moonlight    ┌───────┬───────┐
  │   game, full-  │ ──────────────────────────▶│ left  │ right │
  │     screen     │   shader splits the screen │  eye  │  eye  │
  └────────────────┘   into two eyes            └───────┴───────┘
```

Hyprland draws the game twice, side by side. Sunshine streams that picture to
the phone, and Moonlight shows it inside the Cardboard viewer. It was made for
FPV sims like Liftoff, but any game works.

## What you need

| Where | What |
|---|---|
| PC | Hyprland with the **Lua config** (`hyprctl eval` must work) |
| PC | [Sunshine](https://github.com/LizardByte/Sunshine), paired with your phone (Arch: AUR `sunshine` or `sunshine-bin`) |
| PC | `python3` |
| Phone | [Moonlight](https://moonlight-stream.org/) and a Cardboard-style headset |

## Install

```sh
git clone https://github.com/allextraszza1488/hypr-cardboard
cd hypr-cardboard
./install.sh
systemctl --user restart sunshine
```

It never asks for root. It does three things:

- copies `cardboard-sbs` to `~/.local/bin`
- copies the shader to `~/.local/share/hypr-cardboard`
- adds a **Cardboard** app to `~/.config/sunshine/apps.json`, leaving your other apps alone

Remove it with `./install.sh uninstall`.

## Play

1. Start the game and make it **truly fullscreen**, with the game's own
   fullscreen mode or Hyprland's fullscreen. Maximized doesn't count, because
   the bar would still be in the picture.
2. In Moonlight, open the **Cardboard** app.
3. Put the phone in the headset.

The split is on only while the game is focused **and** fullscreen. Alt-tab
away and the normal picture comes back. End the stream and everything resets.

### Another game

The default game is Liftoff (window class `Liftoff.x86_64`). To use another
game:

1. Focus the game and run `hyprctl activewindow`. Note the `class:` line.
2. In `~/.config/sunshine/apps.json`, find the Cardboard app's `do` command
   (`setsid -f .../cardboard-sbs auto`) and add the class at the end:
   `... auto <class>`.
3. Restart Sunshine.

## By hand

```sh
cardboard-sbs on        # split now
cardboard-sbs off       # back to normal
cardboard-sbs toggle    # flip it (handy on a keybind)
cardboard-sbs auto      # follow the game, Ctrl+C to quit
cardboard-sbs auto <class>
cardboard-sbs stop      # end a running auto and turn the split off
```

Example keybind for `hyprland.lua`:

```lua
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("cardboard-sbs toggle"))
```

## Phone viewer and calibration

`phone/index.html` is a single page that runs in the phone's browser, no
install and no network. It does two things:

- **Calibrate the headset.** A test grid, drawn once per eye, with sliders
  for eye spacing (mm), lens correction (k1, k2), zoom, up/down and screen
  scale. Adjust until the lines look straight and both eyes merge into one
  sharp picture. The values stay on the phone and are shown at the bottom.
- **View any picture or video Cardboard-style.** *Open file* picks one from
  the phone's gallery. If the file is already side-by-side 3D, tick the box
  and each eye gets its own half: real 3D.

*Fullscreen* also locks landscape. Tap the picture to show or hide the
settings.

Open it from a local server on the phone, for example in Termux:

```sh
cd hypr-cardboard/phone && python3 -m http.server 8090 --bind 127.0.0.1
# then open http://127.0.0.1:8090/ in the browser
```

The starting values are a guess for a generic plastic VR box (approx.); the
sliders are the real calibration. The PC split shader doesn't use these
values yet.

## How it works

```
bin/cardboard-sbs     turns the split on and off
share/cardboard.frag  the shader that does the split
install.sh            copies the two above, adds the Sunshine app
```

- **Shader.** Hyprland can run one fragment shader over the whole monitor
  (`decoration:screen_shader`). `cardboard.frag` cuts out the centre square of
  the screen and draws it twice, once per eye, with black bars above and
  below.
- **Aspect ratio.** The shader has the screen's aspect ratio written into it.
  Each time the split turns on, `cardboard-sbs` writes a copy with your
  monitor's real ratio to `$XDG_RUNTIME_DIR/cardboard-sbs.frag`.
- **Following the game.** `auto` listens on Hyprland's event socket. On every
  focus, fullscreen or window change, it asks whether the focused window is
  the game and is fullscreen, then turns the shader on or off.
- **Cursor.** The hardware cursor is drawn after the shader, so it wouldn't be
  split. While the split is on, the cursor is drawn in software and shows up in
  both eyes.
- **Sunshine.** The Cardboard app is your normal desktop stream with a prep
  command: `cardboard-sbs auto` runs when the stream starts and
  `cardboard-sbs stop` runs when it ends.

## Limits

- The shader covers the whole monitor, because Hyprland has no per-window
  shaders. Anything drawn on top of the game, like notifications, is split too.
- Both eyes get the same flat picture. It's not real stereo 3D.
- With several monitors, every monitor is split, and the ratio comes from the
  focused one.
- Lua-config Hyprland only.

## License

MIT
