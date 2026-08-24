import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Turn 10's break redesign, "outcome first" variant (10a): the emotional
// beat leads (ESCAPED! / CAUGHT!), then the rounds-won tally as the hero
// number, then session time and distance as context. A green arrow blinks
// at the 2 o'clock edge - where SELECT physically sits - and the bottom row
// names the next role beside a mini character. Blue break rim; waits for
// SELECT indefinitely.
module BreakScreen {

    var _nextRoleCharacter as Character?;

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

        drawSelectArrow(dc, metrics, phase);
        drawTally(dc, metrics, controller.score(), controller.roundIndex());
        drawStatsRow(dc, metrics, controller);
        drawNextRoleRow(dc, metrics, controller.pendingNextRole());

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Green NEXT + triangle at the 2 o'clock edge, pointing at the SELECT
    // button, blinking slowly (10a: top 120, right 22, ~1s cadence).
    function drawSelectArrow(dc as Graphics.Dc, metrics as ScreenMetrics, phase as Float) as Void {
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
        var label = WatchUi.loadResource(Rez.Strings.BreakNextLabel) as String;
        dc.drawText(tipX - triW - metrics.px(8), cy, metrics.fontFor(0), label, Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
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
        var timeValue = Utils.formatSeconds(controller.elapsedTotal());
        var kmValue = (controller.totalDistanceMeters() / 1000.0).format("%.2f");
        var timeLabel = WatchUi.loadResource(Rez.Strings.BreakTimeLabel) as String;
        var kmLabel = WatchUi.loadResource(Rez.Strings.BreakKmLabel) as String;

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

    // Bottom row: static mini character in the upcoming role beside
    // "Next: you're the cat/mouse" in break blue (10a: bottom 56).
    function drawNextRoleRow(dc as Graphics.Dc, metrics as ScreenMetrics, nextRole as Number) as Void {
        if (_nextRoleCharacter == null || (_nextRoleCharacter as Character).role != nextRole) {
            _nextRoleCharacter = new Character(nextRole);
        }
        var isCat = (nextRole == GameConstants.ROLE_CAT);
        var text = WatchUi.loadResource(isCat ? Rez.Strings.BreakNextCat : Rez.Strings.BreakNextMouse) as String;
        var font = metrics.fontFor(1);
        var textW = dc.getTextWidthInPixels(text, font);
        var charR = metrics.px(17);
        var rowGap = metrics.px(12);

        var totalW = charR * 2 + rowGap + textW;
        var charX = metrics.centerX - totalW / 2 + charR;
        var cy = metrics.height - metrics.px(56) - metrics.px(17);

        (_nextRoleCharacter as Character).draw(dc, charX, cy, charR, 1, 0.0, 0.0, GameConstants.DANGER_STAGE_REST, Palette.BLACK);

        dc.setColor(Palette.RECOVERY_TITLE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(charX + charR + rowGap, cy, font, text, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
