import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Turn 6's how-to-play cards (6b/6c/6d): three static pages a first-timer
// actually needs - what the game is (pace is the controller), how a round
// works (the rim is time), and what the colours/buzzes mean. Blue recovery
// rim, blue letterspaced card title. UP/DOWN pages, SELECT advances and
// finally returns home.
//
// Turn 12: how to advance is now shown purely by position - a green arrow
// at the 2 o'clock edge pointing at the SELECT button - instead of a bottom
// "SELECT > next" line, which the body copy kept overflowing into. The copy
// itself is bounded to the space above that old hint line so a card that
// wraps to one more line shrinks a tier instead of running off the card.
// Deliberately no animation - instructions shouldn't compete with the copy.
module InstructionsScreen {

    var _catCharacter as Character?;
    var _mouseCharacter as Character?;

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController) as Void {
        Hud.drawRim(dc, metrics, Palette.RECOVERY_RIM, 14);

        var page = controller.instructionsPage();
        if (page == 0) {
            drawPageGame(dc, metrics);
        } else if (page == 1) {
            drawPageRound(dc, metrics);
        } else {
            drawPageSignals(dc, metrics);
        }

        drawSelectIndicator(dc, metrics);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Bottom of the space the body copy may use: where the old "SELECT >"
    // hint line used to start, which is as low as centered text can sit
    // before the round card's curve starts eating the ends of a line.
    function bodyBottom(metrics as ScreenMetrics) as Number {
        return metrics.isRound
            ? (metrics.height - metrics.px(56))
            : (metrics.height - metrics.px(30));
    }

    function drawTitle(dc as Graphics.Dc, metrics as ScreenMetrics, titleId as ResourceId) as Void {
        dc.setColor(Palette.BLUE, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, metrics.px(78), 1, WatchUi.loadResource(titleId) as String);
    }

    // 6b THE GAME: the two animals side by side, then the one sentence a
    // new player must grasp - pace is the controller.
    function drawPageGame(dc as Graphics.Dc, metrics as ScreenMetrics) as Void {
        drawTitle(dc, metrics, Rez.Strings.InstrTitleGame);

        if (_catCharacter == null) {
            _catCharacter = new Character(GameConstants.ROLE_CAT);
        }
        if (_mouseCharacter == null) {
            _mouseCharacter = new Character(GameConstants.ROLE_MOUSE);
        }
        var catRadius = metrics.px(28);
        var mouseRadius = metrics.px(21);
        var gap = metrics.px(20);
        var feetY = metrics.px(178);
        var totalW = catRadius * 2 + gap + mouseRadius * 2;
        var catX = metrics.centerX - totalW / 2 + catRadius;
        var mouseX = catX + catRadius + gap + mouseRadius;
        // phase 0: static characters on the instruction cards.
        (_catCharacter as Character).draw(dc, catX, feetY - catRadius, catRadius, 1, 0.0, 0.0, GameConstants.DANGER_STAGE_REST, Palette.BLACK);
        (_mouseCharacter as Character).draw(dc, mouseX, feetY - mouseRadius, mouseRadius, 1, 0.0, 0.0, GameConstants.DANGER_STAGE_REST, Palette.BLACK);

        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitWrappedCenteredText(dc, metrics, metrics.px(206), 1, WatchUi.loadResource(Rez.Strings.InstrBodyGame) as String, metrics.width - metrics.px(120), bodyBottom(metrics));
    }

    // 6c A ROUND: the round screen in miniature - a draining time ring with
    // the metre number inside it.
    function drawPageRound(dc as Graphics.Dc, metrics as ScreenMetrics) as Void {
        drawTitle(dc, metrics, Rez.Strings.InstrTitleRound);

        var ringR = metrics.px(52);
        var ringW = metrics.px(11);
        if (ringW < 3) {
            ringW = 3;
        }
        var cy = metrics.px(116) + ringR;

        dc.setPenWidth(ringW);
        dc.setColor(Palette.RING_TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(metrics.centerX, cy, ringR - ringW / 2);
        dc.setColor(Palette.BLUE, Graphics.COLOR_TRANSPARENT);
        // 62% full, clockwise from the top like the real chase ring.
        dc.drawArc(metrics.centerX, cy, ringR - ringW / 2, Graphics.ARC_CLOCKWISE, 90, (90 - 223 + 360) % 360);
        dc.setPenWidth(1);

        var numFont = metrics.fontFor(2);
        var unitFont = metrics.fontFor(0);
        var numText = "45";
        var numW = dc.getTextWidthInPixels(numText, numFont);
        var unitW = dc.getTextWidthInPixels("m", unitFont);
        var startX = metrics.centerX - (numW + unitW) / 2;
        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, cy, numFont, numText, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + numW, cy, unitFont, "m", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitWrappedCenteredText(dc, metrics, metrics.px(232), 1, WatchUi.loadResource(Rez.Strings.InstrBodyRound) as String, metrics.width - metrics.px(104), bodyBottom(metrics));
    }

    // 6d EYES UP: the safety card - what amber, red, and a buzz mean, so
    // the watch can stay on the wrist.
    function drawPageSignals(dc as Graphics.Dc, metrics as ScreenMetrics) as Void {
        drawTitle(dc, metrics, Rez.Strings.InstrTitleSignals);

        var dotR = metrics.px(22);
        var rowGap = metrics.px(16);
        var rowH = dotR * 2;
        var x = metrics.px(76) + dotR;
        var textX = x + dotR + metrics.px(16);
        var y = metrics.px(118) + dotR;
        var font = metrics.fontFor(0);

        dc.setColor(Palette.AMBER, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, dotR);
        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, y, font, WatchUi.loadResource(Rez.Strings.InstrAmber) as String, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        y += rowH + rowGap;
        dc.setColor(Palette.RED, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, dotR);
        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, y, font, WatchUi.loadResource(Rez.Strings.InstrRed) as String, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        y += rowH + rowGap;
        dc.setColor(Palette.DK_PANEL, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, dotR);
        dc.setColor(Palette.CHIP_GREY, Graphics.COLOR_TRANSPARENT);
        var innerR = metrics.px(8);
        dc.fillCircle(x, y, innerR > 1 ? innerR : 1);
        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, y, font, WatchUi.loadResource(Rez.Strings.InstrBuzz) as String, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Palette.CHIP_GREY, Graphics.COLOR_TRANSPARENT);
        Hud.drawFitWrappedCenteredText(dc, metrics, metrics.px(302), 0, WatchUi.loadResource(Rez.Strings.InstrFooter) as String, metrics.width - metrics.px(112), bodyBottom(metrics));
    }

    // Green triangle at the 2 o'clock edge, pointing at the SELECT button -
    // the same "press this" marker the break screen puts there, so the one
    // gesture the cards need is taught by position rather than by a line of
    // copy competing with the card's own text. Static, unlike the break
    // screen's, since these pages don't animate; and identical on every page
    // because SELECT always moves forward, whether that's the next card or
    // back home from the last one.
    function drawSelectIndicator(dc as Graphics.Dc, metrics as ScreenMetrics) as Void {
        var triW = metrics.px(13);
        var triH = metrics.px(13);
        var tipX = metrics.width - metrics.px(22);
        var cy = metrics.px(133);

        dc.setColor(Palette.GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [tipX - triW, cy - triH],
            [tipX, cy],
            [tipX - triW, cy + triH]
        ]);
    }
}
