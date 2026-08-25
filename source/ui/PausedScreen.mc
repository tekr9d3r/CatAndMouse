import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Turn 3's paused mockup (3e): deliberately dead. Grey rim, no characters,
// no animation - the animation clock is already stopped for this state
// (GameView.syncAnimationClock only runs it for states with something
// moving), so the screen looking frozen matches the clock actually being
// frozen.
//
// The centered "SELECT > resume" line used to overflow into PAUSED on
// narrower devices. Replaced with the same edge-arrow idiom BreakScreen
// uses to point at the physical SELECT button, but static (no blink,
// muted grey) to match this screen's deliberately dead/frozen tone rather
// than Break's "your turn" green.
module PausedScreen {
    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController) as Void {
        Hud.drawRim(dc, metrics, Palette.PAUSED_RIM, 14);

        drawPauseIcon(dc, metrics, layout);

        // Mockup 3e: bars at y150, PAUSED at y252.
        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        var labelY = metrics.isRound ? metrics.px(252) : (layout.stageBottom + metrics.px(20));
        Hud.drawCenteredText(dc, metrics, labelY, 2, WatchUi.loadResource(Rez.Strings.StatePaused) as String);

        drawResumeArrow(dc, metrics);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Static triangle + "RESUME" at the 2 o'clock edge, same anchor
    // BreakScreen's NEXT arrow uses for the same physical button.
    function drawResumeArrow(dc as Graphics.Dc, metrics as ScreenMetrics) as Void {
        var triW = metrics.px(13);
        var triH = metrics.px(13);
        var tipX = metrics.width - metrics.px(22);
        var cy = metrics.px(133);

        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [tipX - triW, cy - triH],
            [tipX, cy],
            [tipX - triW, cy + triH]
        ]);

        var font = metrics.fontFor(0);
        var label = WatchUi.loadResource(Rez.Strings.PausedResumeLabel) as String;
        dc.drawText(tipX - triW - metrics.px(8), cy, font, label, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function drawPauseIcon(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout) as Void {
        var barW = metrics.px(22);
        var barH = metrics.px(70);
        var gap = metrics.px(18);
        var y = metrics.isRound ? metrics.px(150) : (layout.stageTop + metrics.px(20));
        var cx = metrics.centerX;

        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - gap / 2 - barW, y, barW, barH);
        dc.fillRectangle(cx + gap / 2, y, barW, barH);
    }
}
