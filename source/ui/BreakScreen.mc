import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Turn 10's break redesign, "outcome first" variant (10a): the emotional
// beat leads (ESCAPED! / CAUGHT!), then the rounds-won tally as the hero
// number, then session time and distance as context. A green arrow blinks
// at the 2 o'clock edge - where SELECT physically sits - labeled "NEXT"
// with the upcoming role's name right below it. Blue break rim; waits for
// SELECT indefinitely.
//
// The original bottom row ("Next: you're the mouse" + a mini character)
// overflowed the round bezel on-device - removed in favor of a single short
// role word stacked under the NEXT arrow instead.
module BreakScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController, phase as Float) as Void {
        Hud.drawRim(dc, metrics, Palette.RECOVERY_RIM, 14);

        var outcome = controller.lastRoundOutcome();
        var win = OutcomeStrings.isWin(outcome);

        // Outcome headline (10a: y74, green on a win).
        dc.setColor(win ? Palette.GREEN : Palette.OFF_WHITE, Graphics.COLOR_TRANSPARENT);
        var headlineY = metrics.isRound ? metrics.px(74) : metrics.px(40);
        Hud.drawFitCenteredText(dc, metrics, headlineY, 3, WatchUi.loadResource(OutcomeStrings.breakIdFor(outcome)) as String, metrics.width - metrics.px(90));

        // "ROUND n" - the round just finished (y118).
        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, metrics.px(118), 0, (WatchUi.loadResource(Rez.Strings.BreakRoundLabel) as String) + " " + controller.roundIndex());

        drawSelectArrow(dc, metrics, phase, controller.pendingNextRole());
        drawTally(dc, metrics, controller.score(), controller.roundIndex());
        drawStatsRow(dc, metrics, controller);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Green NEXT + triangle at the 2 o'clock edge, pointing at the SELECT
    // button, blinking slowly (10a: top 120, right 22, ~1s cadence), with
    // the upcoming role's name stacked right below it, same right-justified
    // alignment.
    function drawSelectArrow(dc as Graphics.Dc, metrics as ScreenMetrics, phase as Float, nextRole as Number) as Void {
        var on = (((phase / 0.85).toNumber()) % 2) == 0;
        var triW = metrics.px(13);
        var triH = metrics.px(13);
        var tipX = metrics.width - metrics.px(22);
        var cy = metrics.px(133);

        dc.setColor(Palette.GREEN, Graphics.COLOR_TRANSPARENT);
        if (on) {
            dc.fillPolygon([
                [tipX - triW, cy - triH],
                [tipX, cy],
                [tipX - triW, cy + triH]
            ]);
        }
        var font = metrics.fontFor(0);
        var label = WatchUi.loadResource(Rez.Strings.BreakNextLabel) as String;
        var labelX = tipX - triW - metrics.px(8);
        dc.drawText(labelX, cy, font, label, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        var roleId = (nextRole == GameConstants.ROLE_CAT) ? Rez.Strings.BreakNextRoleCat : Rez.Strings.BreakNextRoleMouse;
        var roleY = cy + dc.getFontHeight(font);
        dc.drawText(labelX, roleY, font, WatchUi.loadResource(roleId) as String, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Rounds-won tally: big mono number with a smaller grey "/n won"
    // suffix on its baseline (10a: y158, 76px + 30px).
    function drawTally(dc as Graphics.Dc, metrics as ScreenMetrics, won as Number, rounds as Number) as Void {
        var numText = won.toString();
        var suffixText = "/" + rounds + " " + (WatchUi.loadResource(Rez.Strings.BreakWonSuffix) as String);

        var font = Graphics.FONT_NUMBER_MEDIUM;
        if (dc.getFontHeight(font) > metrics.px(110)) {
            font = Graphics.FONT_NUMBER_MILD;
        }
        var suffixFont = metrics.fontFor(2);
        var numW = dc.getTextWidthInPixels(numText, font);
        var numH = dc.getFontHeight(font);
        var suffixW = dc.getTextWidthInPixels(suffixText, suffixFont);
        var suffixH = dc.getFontHeight(suffixFont);

        // Anchor the mockup number's vertical center (top 158 + 76/2).
        var y = metrics.px(196) - numH / 2;
        var startX = metrics.centerX - (numW + suffixW) / 2;

        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, y, font, numText, Graphics.TEXT_JUSTIFY_LEFT);
        var suffixY = y + (numH - Graphics.getFontDescent(font)) - (suffixH - Graphics.getFontDescent(suffixFont));
        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + numW, suffixY, suffixFont, suffixText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // Session stats: TIME and KM columns (10a: y250, inside insets 70).
    function drawStatsRow(dc as Graphics.Dc, metrics as ScreenMetrics, controller as GameController) as Void {
        var statute = Utils.isStatute();
        var timeValue = Utils.formatSeconds(controller.elapsedTotal());
        var kmValue = (statute
            ? Utils.metersToMiles(controller.totalDistanceMeters())
            : controller.totalDistanceMeters() / 1000.0).format("%.2f");
        var timeLabel = WatchUi.loadResource(Rez.Strings.BreakTimeLabel) as String;
        var kmLabel = WatchUi.loadResource(statute ? Rez.Strings.BreakMiLabel : Rez.Strings.BreakKmLabel) as String;

        var valueFont = metrics.fontFor(2);
        var labelFont = metrics.fontFor(0);
        var valueY = metrics.px(250);
        var labelY = valueY + dc.getFontHeight(valueFont) + metrics.px(3);

        // Columns pushed to the edges of the central band like the mockup's
        // space-between row: left column starts at inset 70, right column
        // ends at width-70.
        var inset = metrics.px(70);
        var leftW = maxOf(dc.getTextWidthInPixels(timeValue, valueFont), dc.getTextWidthInPixels(timeLabel, labelFont));
        var rightW = maxOf(dc.getTextWidthInPixels(kmValue, valueFont), dc.getTextWidthInPixels(kmLabel, labelFont));
        var leftX = inset + leftW / 2;
        var rightX = metrics.width - inset - rightW / 2;

        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, valueY, valueFont, timeValue, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rightX, valueY, valueFont, kmValue, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, labelY, labelFont, timeLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rightX, labelY, labelFont, kmLabel, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function maxOf(a as Number, b as Number) as Number {
        return (a > b) ? a : b;
    }
}
