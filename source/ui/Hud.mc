import Toybox.Graphics;
import Toybox.Lang;

// Small shared text-drawing helpers so per-state screen modules don't each
// reimplement centered-text loops with their own pixel math. drawBody and
// drawScore return the y position just below what they drew, so callers
// stack content (body -> score -> hint) without any two elements needing to
// agree on a shared fixed offset - a fixed layout.scoreY collided with the
// last body line whenever a screen (ChaseScreen) drew more lines than the
// layout was tuned for.
module Hud {

    function drawCenteredText(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, tier as Number, text as String) as Void {
        dc.drawText(metrics.centerX, y, metrics.fontFor(tier), text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Centered text that steps its font tier down until the string fits
    // maxWidth - Garmin's fixed font enum varies wildly per device, so any
    // longer line (outcome headlines especially) can overflow the circle on
    // one watch while fitting fine on another.
    function drawFitCenteredText(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, tier as Number, text as String, maxWidth as Number) as Void {
        var t = tier;
        while (t > 0 && dc.getTextWidthInPixels(text, metrics.fontFor(t)) > maxWidth) {
            t -= 1;
        }
        dc.drawText(metrics.centerX, y, metrics.fontFor(t), text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Draws `lines` centered, one per row, starting at layout.bodyStartY and
    // stepping by layout.bodyLineHeight. Returns the y just below the last line.
    function drawBody(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, tier as Number, lines as Array<String>) as Number {
        var y = layout.bodyStartY;
        for (var i = 0; i < lines.size(); i += 1) {
            drawCenteredText(dc, metrics, y, tier, lines[i]);
            y += layout.bodyLineHeight;
        }
        return y;
    }

    function drawTitle(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, title as String) as Void {
        drawCenteredText(dc, metrics, layout.titleY, 3, title);
    }

    function drawHint(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, hint as String) as Void {
        drawCenteredText(dc, metrics, layout.hintY, 1, hint);
    }

    // y: where to draw the score, typically the value returned by drawBody.
    // Returns the y just below the score line.
    function drawScore(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, score as Number) as Number {
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        drawCenteredText(dc, metrics, y, 1, "Score " + score);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        return y + metrics.px(24);
    }

    // The one-rim-colour-per-state border used across every non-chase
    // screen (setup/warmup/break/paused/summary) in the design handoff -
    // a thick ring on round devices, a rounded border on rectangle ones.
    // ChaseScreen draws its own rim separately since it also needs to
    // strobe in the danger stage.
    function drawRim(dc as Graphics.Dc, metrics as ScreenMetrics, color as Graphics.ColorType, widthBaseline as Number) as Void {
        var rimWidth = metrics.px(widthBaseline);
        if (rimWidth < 2) {
            rimWidth = 2;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(rimWidth);
        if (metrics.isRound) {
            var radius = (metrics.minDim - rimWidth) / 2;
            dc.drawCircle(metrics.centerX, metrics.centerY, radius);
        } else {
            dc.drawRoundedRectangle(rimWidth / 2, rimWidth / 2, metrics.width - rimWidth, metrics.height - rimWidth, metrics.px(14));
        }
        dc.setPenWidth(1);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
}
