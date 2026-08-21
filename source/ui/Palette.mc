import Toybox.Graphics;
import Toybox.Lang;

// Colors lifted directly from the Claude Design handoff
// ("Cat and Mouse - Chase.dc.html"), which is the authoritative visual spec.
// Dc.setColor() accepts a raw 24-bit 0xRRGGBB integer directly, so these are
// the mockup's exact hex values rather than an approximation via the named
// Graphics.COLOR_* palette - full-color devices (AMOLED/Venu) render them
// exactly, MIP devices quantize automatically.
//
// Rim colour convention carried over from the turn 3 intro: orange family
// for setup/summary, blue family for recovery (warmup/break/pause), and
// green/amber/red reserved for the chase screen. Red is exclusive to the
// mouse-role fear stage and never appears in the cat role.
module Palette {
    const BLACK = 0x000000;
    const INK = 0x17171a; // the mockups' near-black used for eyes/silhouettes
    const CREAM = 0xf2efe9;
    const WARM_WHITE = 0xfff6e6;
    const OFF_WHITE = 0xd8d5cf;
    const MUTED_GREY = 0x6f6f76;
    const DK_PANEL = 0x26262b;

    const BRAND_ORANGE = 0xff7a1a;
    const AMBER = 0xffc300;
    const RED = 0xff2d2d;
    const GREEN = 0x4fd97a;
    const BLUE = 0x2ea8ff;

    // Chase screen - mouse role (turn 2)
    const MOUSE_BG_REST = BLACK;
    const MOUSE_BG_CLOSING = 0x3d2a00;
    const MOUSE_BG_DANGER = 0x8c0f0f;
    const MOUSE_RIM_REST = 0x1b3d24;
    const MOUSE_RIM_CLOSING = AMBER;
    const MOUSE_RIM_DANGER = RED;
    const MOUSE_TITLE_REST = GREEN;
    const MOUSE_TITLE_CLOSING = 0xffe9c9;
    const MOUSE_TITLE_DANGER = WARM_WHITE;
    const MOUSE_ACCENT_CLOSING = 0xe0b877;
    const MOUSE_ACCENT_DANGER = 0xffb3b3;
    const MOUSE_PACE_CLOSING = 0xffe9c9;
    const MOUSE_PACE_DANGER = 0xffd9d9;

    // Chase screen - cat role (turn 4): closing in is good, so the ramp ends
    // orange ("POUNCE!") rather than red. Rest/closing stay on a black
    // ground - only the final stage floods the screen.
    const CAT_BG_REST = BLACK;
    const CAT_BG_CLOSING = BLACK;
    const CAT_BG_DANGER = 0x7a3a00;
    const CAT_RIM_REST = DK_PANEL;
    const CAT_RIM_CLOSING = AMBER;
    const CAT_RIM_DANGER = BRAND_ORANGE;
    const CAT_TITLE_REST = BRAND_ORANGE;
    const CAT_TITLE_CLOSING = AMBER;
    const CAT_TITLE_DANGER = WARM_WHITE;
    const CAT_ACCENT_CLOSING = 0xe0b877;
    const CAT_ACCENT_DANGER = 0xffd0a0;
    const CAT_PACE_CLOSING = 0xffe9c9;
    const CAT_PACE_DANGER = 0xffe0c2;

    // Unselected setup-chip label grey (mockup 3a/3b).
    const CHIP_GREY = 0x8a8a90;

    // Setup (orange family)
    const SETUP_RIM = 0x4a2604;
    const SETUP_TITLE = BRAND_ORANGE;

    // Recovery states: warmup / break / pause (blue family, pause dims to grey)
    const RECOVERY_RIM = 0x0e2a40;
    const RECOVERY_TITLE = BLUE;
    const PAUSED_RIM = DK_PANEL;

    // Summary (orange family, same as setup)
    const SUMMARY_RIM = 0x4a2604;
    const SUMMARY_TITLE = BRAND_ORANGE;
}
