# Cat and Mouse — Screens & Design Constraints

Reference doc for redesigning the UI in an external wireframe tool. Covers
every screen the app currently shows, what it's for, and the hard technical
limits of the Garmin watches it runs on.

## Screens

The app is a single persistent view that redraws differently per game
state. There is no navigation stack (no "back" between these) except the
in-game pause overlay — one state flows into the next automatically or on
a SELECT press, as noted below.

### 1. Setup — Length picker
**State:** `STATE_SETUP`, step 1 of 2
First thing the user sees on launch. Picks session length.
- Shows a title ("Game Length") and a row of 3 selectable options: 10 / 20 / 30 minutes.
- One option is highlighted as "selected" at a time.
- Input: swipe/button up-down (or touch swipe on touch-capable devices) cycles the selection; SELECT confirms and advances to step 2.

### 2. Setup — Intensity picker
**State:** `STATE_SETUP`, step 2 of 2
Picks difficulty.
- Same chip-row pattern: Easy / Medium / Hard.
- A small idle decorative character (mouse) animates next to the options — animation speed increases with the selected intensity, previewing "how fast this will feel."
- Input: same as step 1. SELECT here starts the game (not just advances).

### 3. Warmup
**State:** `STATE_WARMUP`
A short countdown before the chase begins (5–10% of total session length, capped at 5 min), so the user can jog into pace before being chased.
- Shows: countdown timer, current live pace.
- No user input expected here other than pause (see Pause below); it auto-advances to the first chase round when the timer hits zero.

### 4. Chase — "You are the Mouse"
**State:** `STATE_CHASED`
The main gameplay screen, role 1: a virtual "cat" is chasing the player. Ends when the cat catches the player (gap closes to threshold) or a per-round timeout is reached.
- Shows: round label + round number, both characters (player = mouse, opponent = cat) positioned with a gap proportional to the live distance between them — they visually converge as the cat closes in.
- A proximity meter (currently a bar, colored green → yellow → red as danger rises) reinforces how close the catch is.
- Small directional "chevron" indicators appear only while the gap is actively shrinking (not just because it's already close).
- Text readout: live gap in meters, player's pace, opponent's pace.
- Running score is shown.
- This is the screen that should feel the most tense/adrenaline-driven — sound + vibration escalate as danger rises (see Feedback below).

### 5. Chase — "You are the Cat"
**State:** `STATE_CHASING`
Same screen/layout as #4, roles reversed: the player is now chasing a virtual "mouse." Ends when the player catches it or the round times out.
- Visually and structurally identical to screen 4 — same converging characters, same proximity meter, same escalating feedback — just with the label/framing and character roles swapped.

### 6. Break
**State:** `STATE_BREAK`
A recovery screen shown after every round (win or lose), before the next round starts. Meant for the user to jog slowly / catch their breath.
- Shows: a short outcome message (4 variants depending on what just happened — caught by the cat, escaped as the mouse, caught the mouse, or the mouse got away), current score, and a "press SELECT when ready" prompt.
- Unlike a timed rest, this screen waits indefinitely for the user to press SELECT — it does not auto-advance. (The overall session clock keeps running in the background even during this screen, so resting too long eats into total session time.)
- After SELECT, the next round starts with roles reversed from whichever round just ended.

### 7. Paused
**State:** `STATE_PAUSED`
A generic pause overlay, reachable via SELECT from any state except Setup/Summary (including from mid-round or from the Break screen itself).
- Shows: "Paused" + "press SELECT to resume."
- Freezes the session clock while active.

### 8. Summary
**State:** `STATE_SUMMARY`
Shown once the total configured session length has elapsed (checked continuously, including through Break/Paused).
- Shows: a static character (matching whichever role the player was in during the very last round), the final round's outcome message, total rounds played, and final score.
- End of the flow — no further input advances anywhere (app would need to be relaunched to play again).

## Flow summary

```
Setup (length) → Setup (intensity) → Warmup
  → Chase (mouse) → Break → Chase (cat) → Break → Chase (mouse) → ...
  → (loops until session time elapses) → Summary
```
Pause can interrupt any state in the loop except Setup/Summary and resumes back to exactly where it was.

## Design constraints

### Devices currently targeted (verified against the installed Connect IQ SDK's device data)

| Device | Shape | Resolution | Panel | Touch | Graphics memory pool | App storage |
|---|---|---|---|---|---|---|
| fenix 7 | round | 260×260 | transflective MIP, 64-color | yes | 1 MB | 10 MB |
| Forerunner 255 | round | 260×260 | transflective MIP, 64-color | no | 1 MB | 10 MB |
| Instinct 2 | semi-octagon (flattened-edge round) | **176×176** | transflective MIP, 64-color | no | (not reported — very tight) | **128 KB** |
| Instinct 3 AMOLED (50mm) | round | 416×416 | AMOLED, full color | no | 3 MB | 10 MB |
| Venu Sq 2 | rectangle | 320×360 | AMOLED, full color | yes | 2 MB | 10 MB |

Takeaways for wireframing:
- **Three screen shapes in play**: full round, semi-octagon (round with flattened top/bottom/sides — Instinct 2), and rectangle (Venu Sq 2). A layout that only accounts for "round vs. rectangle" will still clip on the semi-octagon's flattened edges if content is pushed too close to top/bottom.
- **Resolution spans ~2.4x** (176px to 416px) across the current device set, and the underlying Connect IQ device catalog goes even wider than this project currently targets. Any wireframe needs to be described in relative/proportional terms, not fixed pixel positions.
- **Color**: two of five current devices (fenix 7, FR255, Instinct 2 — all MIP panels) are limited to a fixed 64-color palette with no smooth gradients/alpha blending in practice; only Instinct 3 AMOLED and Venu Sq 2 are full-color AMOLED. Any design meant to work everywhere should rely on solid named colors and avoid gradients as the *primary* signal (fine as a bonus effect on AMOLED only).
- **Instinct 2 is the tight constraint**: 176×176 with a reported 128 KB of app storage is far more limited than the rest of the lineup (10 MB). A design with heavy imagery/assets risks not fitting this device at all.
- **Touch is inconsistent**: only fenix 7 and Venu Sq 2 are touch-capable; FR255, Instinct 2, and Instinct 3 AMOLED are physical-button-only. Any interaction design has to work with up/down button presses + a select button as the baseline, with touch swipe as a bonus, never a requirement.

### Rendering
- All drawing is 2D and CPU-driven (`Dc` primitives: circles, ellipses, polygons, lines, arcs, rectangles, text) — there is no GPU and no built-in vector/SVG rendering at runtime.
- No bitmap art is currently used for gameplay elements (the cat/mouse characters are drawn from primitives, not image files) specifically so the same code scales to every resolution/shape above without needing per-device art variants. A wireframe tool doesn't need to account for image assets unless that changes.
- Bitmap image resources (if used) are typically PNG; the project's one image asset (the launcher icon) is an SVG rasterized at build time — that's specific to launcher icons, not general in-app graphics.
- Text uses a fixed system font-size enum (roughly xtiny/tiny/small/medium/large), not arbitrary point sizes — designs should think in relative size tiers, not exact type scales.
- Animation is possible (this isn't a watchface, so there's no forced low-refresh "always-on" mode) but is intentionally throttled to a low frame rate (~5 fps in the current implementation) and stopped outright during idle states (paused/summary), because the app runs continuously over GPS for the length of the whole workout (10–30+ minutes) and battery matters.

### Sound & haptics
- **No device in this lineup has a real speaker.** Audio is limited to a fixed system set of short alert *tones* (like an alarm-clock beep) — the same fixed sound set on every Connect IQ app and device, not something a designer can author custom audio for.
- Vibration is the one channel that's actually customizable — pulse timing/intensity patterns can be authored freely, and some devices ignore fine intensity control and just buzz on/off. Treat vibration (not sound) as the primary "feel" channel for tension/urgency; sound is a secondary, coarse reinforcement at best.

### Session/runtime constraints worth designing around
- The session clock runs continuously once started, including through the Break and Paused screens — a design shouldn't imply "the clock stops" during rest.
- Because the whole session is a live GPS-tracked activity, any screen a user might linger on (Break in particular) should stay legible/glanceable rather than assuming sustained attention.
