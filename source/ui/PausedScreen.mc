import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Turn 3's paused mockup (3e): deliberately dead. Grey rim, no characters,
// no animation - the animation clock is already stopped for this state
// (GameView.syncAnimationClock only runs it for states with something
// moving), so the screen looking frozen matches the clock actually being
// frozen.
module PausedScreen {
    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController) as Void {
        Hud.drawRim(dc, metrics, Palette.PAUSED_RIM, 14);

        drawPauseIcon(dc, metrics, layout);

        // Mockup 3e: bars at y150, PAUSED at y252, hint bottom-anchored 88.
        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        var labelY = metrics.isRound ? metrics.px(252) : (layout.stageBottom + metrics.px(20));
        Hud.drawCenteredText(dc, metrics, labelY, 2, WatchUi.loadResource(Rez.Strings.StatePaused) as String);

        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        var hintFont = metrics.fontFor(1);
        var hintY = metrics.isRound ? (metrics.height - metrics.px(88) - dc.getFontHeight(hintFont)) : layout.hintY;
        Hud.drawCenteredText(dc, metrics, hintY, 1, WatchUi.loadResource(Rez.Strings.HintPausedResume) as String);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
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
