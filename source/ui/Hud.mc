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

    // Greedy word-wrap: draws `text` centered in lines no wider than
    // maxWidth, starting at y. Returns the y just below the last line.
    // Needed for the instruction cards' multi-sentence copy - Dc.drawText
    // has no wrapping of its own.
    function drawWrappedCenteredText(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, tier as Number, text as String, maxWidth as Number) as Number {
        var font = metrics.fontFor(tier);
        var lineH = dc.getFontHeight(font);
        var words = splitWords(text);
        var line = "";
        for (var i = 0; i < words.size(); i += 1) {
            var candidate = (line.length() == 0) ? (words[i] as String) : (line + " " + words[i]);
            if (line.length() > 0 && dc.getTextWidthInPixels(candidate, font) > maxWidth) {
                dc.drawText(metrics.centerX, y, font, line, Graphics.TEXT_JUSTIFY_CENTER);
                y += lineH;
                line = words[i] as String;
            } else {
                line = candidate;
            }
        }
        if (line.length() > 0) {
            dc.drawText(metrics.centerX, y, font, line, Graphics.TEXT_JUSTIFY_CENTER);
            y += lineH;
        }
        return y;
    }

    function splitWords(text as String) as Array<String> {
        var words = [] as Array<String>;
        var rest = text;
        var idx = rest.find(" ");
        while (idx != null) {
            if (idx > 0) {
                words.add(rest.substring(0, idx) as String);
            }
            rest = rest.substring(idx + 1, rest.length()) as String;
            idx = rest.find(" ");
        }
        if (rest.length() > 0) {
            words.add(rest);
        }
        return words;
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
