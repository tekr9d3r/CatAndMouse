# Cat & Mouse

A GPS interval-training game for Garmin watches. You run, and your real pace
drives a chase: one round you're the mouse trying to survive, the next
you're the cat trying to close the gap — all rendered as a live graphical
HUD, not a data screen.

## How it plays

- **You are it.** Every round you're either the **mouse** (run to keep the
  cat off you) or the **cat** (run to close the gap before time runs out).
  Roles alternate each round.
- **Your pace is the input.** There's no button-mashing — running faster
  closes the gap when you're the cat, and opens it when you're the mouse.
  The whole game is just your real running pace, mapped onto a virtual chase.
- **The rim is the clock.** Each round has a time limit shown as a ring
  draining around the edge of the watch face. As the mouse, survive until it
  empties. As the cat, catch the mouse before it does.
- **Danger has three stages** — rest, closing in, and about to be
  caught/about to pounce — read the same way by the screen (background
  flood color, blinking "RUN!" / "GET 'EM!") and by vibration/tone, so you
  always know how close it is without staring at the watch.
- **A 5-minute warmup** opens every session (the cat's asleep), then rounds
  begin. Each round the required pace escalates 5% over the last, so a
  session gets progressively harder the longer it runs.
- **Score is simple:** +1 for every round you win, shown live and on the
  end-of-session summary alongside total distance, average pace, and rounds
  played.
- The whole session — warmup included — records as one continuous Running
  activity with GPS, so it shows up in Garmin Connect afterward with a full
  map, distance, and pace history, same as any other run.

## In-app controls

- **SELECT** — confirm / advance (start, continue past a break, dismiss the
  summary).
- **MENU or BACK during an activity** — opens an in-activity menu:
  Resume, Change Intensity, Skip Warmup (warmup only), End Activity, or
  Delete Activity (with a confirmation, since it discards the recording).
- Three intensity levels (Easy / Medium / Hard) set the base and top chase
  speeds, chosen before you start and changeable mid-session from the menu.

## Why it looks like this

The UI is built entirely from procedural drawing (`Graphics.Dc` primitives —
circles, polygons, arcs) rather than bitmap art, so one codebase renders
correctly across round, semi-round, semi-octagon, and rectangular screens,
and across full-color AMOLED and lower-color-depth MIP displays, without
per-device art assets. A `ScreenMetrics` / `HudLayout` layer computes
everything relative to each device's actual resolution and shape at
runtime.

## Supported devices

Currently targets 16 color-screen Garmin devices spanning the Fenix,
Forerunner, Venu, Instinct (AMOLED), and Vivoactive lines — see
[`manifest.xml`](manifest.xml) for the exact list. Monochrome (1-bit)
devices are intentionally not yet supported; that UI pass hasn't been
designed yet.

## Project structure

```
source/
  GameController.mc     State machine: setup → warmup → chase rounds → break → summary
  ChaseModel.mc          Pure pace/gap simulation (no rendering, no I/O)
  Feedback.mc            Centralizes all vibration/tone triggers
  ActivityRecorder.mc    Wraps the FIT recording session
  ui/
    ScreenMetrics.mc      Per-device resolution/shape scaling
    HudLayout.mc          Named layout anchors for round vs. rectangular screens
    Character.mc          Procedural cat/mouse rendering
    *Screen.mc            One draw module per game state
resources/
  strings/, menus/, drawables/
manifest.xml             Declares target devices and permissions
```

## Building

Requires the Garmin Connect IQ SDK and a local `keys/developer_key.der`
signing key (not checked in).

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home
export PATH="$JAVA_HOME/bin:$PATH"
SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/<sdk-version>"

"$SDK/bin/monkeyc" -f monkey.jungle -o dist/CatAndMouse-<device>.prg \
  -y keys/developer_key.der -d <device> -w
```

Run it in the simulator with `monkeydo`, or copy the `.prg` to
`GARMIN/APPS/` on the watch over USB to sideload it for real running.
