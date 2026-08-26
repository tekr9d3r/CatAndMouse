import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

// Turn 11's summary redesign, "distance as hero" variant (11a): the
// runner's answer first - how far - as a huge number, with average pace and
// rounds beneath as equals and a green saved-checkmark at the bottom. Up
// top the chase is finally called off: cat and mouse side by side, both
// smiling front-facing, the cat's tail curled around the mouse, swaying
// together on one slow loop. Orange setup-family rim.
module SummaryScreen {

    var _catCharacter as Character?;
    var _mouseCharacter as Character?;

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController, phase as Float) as Void {
        Hud.drawRim(dc, metrics, Palette.SUMMARY_RIM, 14);

        drawTrucePair(dc, metrics, phase);
        drawDistanceHero(dc, metrics, controller);
        drawStatsRow(dc, metrics, controller);
        drawSavedCheck(dc, metrics);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Cat (r32) and mouse (r22) bottom-aligned side by side (11a: top 66,
    // 26px apart), swaying on the same slow 2.4s bob, with the cat's tail
    // hooked around toward the mouse: truce, not chase.
    function drawTrucePair(dc as Graphics.Dc, metrics as ScreenMetrics, phase as Float) as Void {
        if (_catCharacter == null) {
            _catCharacter = new Character(GameConstants.ROLE_CAT);
            (_catCharacter as Character).truce = true;
            (_catCharacter as Character).smiling = true;
        }
        if (_mouseCharacter == null) {
            _mouseCharacter = new Character(GameConstants.ROLE_MOUSE);
            (_mouseCharacter as Character).truce = true;
            (_mouseCharacter as Character).smiling = true;
        }

        var catRadius = metrics.px(32);
        var mouseRadius = metrics.px(22);
        var gap = metrics.px(26);
        var feetY = metrics.px(130);
        var totalW = catRadius * 2 + gap + mouseRadius * 2;
        var catX = metrics.centerX - totalW / 2 + catRadius;
        var mouseX = catX + catRadius + gap + mouseRadius;

        // Slow shared sway: same phase for both so they move as one.
        var slowPhase = phase * 0.4;

        drawCurledTail(dc, metrics, catX, feetY - catRadius, catRadius, slowPhase);
        (_catCharacter as Character).draw(dc, catX, feetY - catRadius, catRadius, 1, slowPhase, 0.0, GameConstants.DANGER_STAGE_REST, Palette.BLACK);
        (_mouseCharacter as Character).draw(dc, mouseX, feetY - mouseRadius, mouseRadius, 1, slowPhase, 0.0, GameConstants.DANGER_STAGE_REST, Palette.BLACK);
    }

    // The cat's tail attaches near its feet (angle ~65 = just past
    // straight down, screen coords where 0 = 3 o'clock, 90 = 6 o'clock)
    // and hooks up toward the mouse. Radius grows monotonically outward
    // from the body edge at every sampled point, so the whole curve stays
    // outside the body circle and the first point sits exactly on it -
    // guaranteed attachment with no reliance on Dc.drawArc's sweep
    // direction (an earlier version anchored near cheek height, which
    // read as a stray line off the face rather than a tail off the rear).
    function drawCurledTail(dc as Graphics.Dc, metrics as ScreenMetrics, catX as Number, catY as Number, catRadius as Number, phase as Float) as Void {
        var bob = (Math.sin(phase) * catRadius * 0.08).toNumber();
        var penW = (catRadius * 0.17).toNumber();
        if (penW < 2) {
            penW = 2;
        }

        var steps = 7;
        var angleStart = 65.0;
        var angleEnd = -25.0;
        var points = new [steps + 1];
        for (var i = 0; i <= steps; i += 1) {
            var t = i.toFloat() / steps;
            var rad = Math.toRadians(angleStart + (angleEnd - angleStart) * t);
            var r = catRadius * (1.0 + 0.5 * t);
            points[i] = [
                catX + (r * Math.cos(rad)).toNumber(),
                catY + (r * Math.sin(rad)).toNumber() + bob
            ];
        }

        dc.setColor(Palette.BRAND_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(penW);
        for (var i = 0; i < points.size() - 1; i += 1) {
            var a = points[i] as Array<Number>;
            var b = points[i + 1] as Array<Number>;
            dc.drawLine(a[0], a[1], b[0], b[1]);
        }
        var tip = points[steps] as Array<Number>;
        dc.fillCircle(tip[0], tip[1], (penW * 0.65).toNumber());
        dc.setPenWidth(1);
    }

    // Session distance as the hero number (11a: 108px at y154, "km" unit
    // on its baseline in grey).
    function drawDistanceHero(dc as Graphics.Dc, metrics as ScreenMetrics, controller as GameController) as Void {
        var numText = (controller.totalDistanceMeters() / 1000.0).format("%.2f");
        var unitText = "km";
        var unitFont = metrics.fontFor(2);
        var unitW = dc.getTextWidthInPixels(unitText, unitFont);
        var unitH = dc.getFontHeight(unitFont);

        // Height band is the mockup's own 108px digits plus a little slack
        // for the descent padding Garmin's number fonts carry - any taller
        // and the font cell reaches the stats row at y268.
        var maxW = (metrics.width * 0.78).toNumber() - unitW;
        var font = Hud.fitNumberFont(dc, Graphics.FONT_NUMBER_HOT, numText, maxW, metrics.px(118));
        var numW = dc.getTextWidthInPixels(numText, font);
        var numH = dc.getFontHeight(font);

        // Anchor on the mockup number's vertical center (top 154 + 108/2).
        var y = metrics.px(208) - numH / 2;
        var startX = metrics.centerX - (numW + unitW) / 2;

        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, y, font, numText, Graphics.TEXT_JUSTIFY_LEFT);
        var unitY = y + (numH - Graphics.getFontDescent(font)) - (unitH - Graphics.getFontDescent(unitFont));
        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + numW, unitY, unitFont, unitText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // AVG /KM (brand orange) and ROUNDS columns beneath the hero number
    // (11a: y268, inside insets 62).
    function drawStatsRow(dc as Graphics.Dc, metrics as ScreenMetrics, controller as GameController) as Void {
        var distance = controller.totalDistanceMeters();
        var elapsed = controller.elapsedTotal();
        var avgSpeed = (elapsed > 0.0) ? (distance / elapsed) : 0.0;
        var paceValue = Utils.speedToPaceString(avgSpeed);
        var roundsValue = controller.roundIndex().toString();
        var paceLabel = WatchUi.loadResource(Rez.Strings.SummaryAvgLabel) as String;
        var roundsLabel = WatchUi.loadResource(Rez.Strings.RoundsLabel) as String;

        // Value font stepped down a tier from the original design (was
        // fontFor(2)) - the value+label pair was overflowing into the saved
        // checkmark below on-device. labelFont was already at the smallest
        // system size (fontFor(0) = FONT_XTINY on most devices), so the
        // value is the only lever left to free vertical room.
        var valueFont = metrics.fontFor(1);
        var labelFont = metrics.fontFor(0);
        var valueY = metrics.px(268);
        var labelY = valueY + dc.getFontHeight(valueFont) + metrics.px(3);

        var inset = metrics.px(62);
        var leftW = maxOf(dc.getTextWidthInPixels(paceValue, valueFont), dc.getTextWidthInPixels(paceLabel, labelFont));
        var rightW = maxOf(dc.getTextWidthInPixels(roundsValue, valueFont), dc.getTextWidthInPixels(roundsLabel, labelFont));
        var leftX = inset + leftW / 2;
        var rightX = metrics.width - inset - rightW / 2;

        dc.setColor(Palette.BRAND_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, valueY, valueFont, paceValue, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightX, valueY, valueFont, roundsValue, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftX, labelY, labelFont, paceLabel, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(rightX, labelY, labelFont, roundsLabel, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function maxOf(a as Number, b as Number) as Number {
        return (a > b) ? a : b;
    }

    // Green circle with a dark checkmark at the bottom (11a: 26px circle,
    // bottom 48) - the activity is saved, no words needed.
    function drawSavedCheck(dc as Graphics.Dc, metrics as ScreenMetrics) as Void {
        var r = metrics.px(13);
        if (r < 5) {
            r = 5;
        }
        var cx = metrics.centerX;
        var cy = metrics.height - metrics.px(48) - r;

        dc.setColor(Palette.GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, r);

        var penW = (r * 0.24).toNumber();
        dc.setColor(Palette.INK, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(penW > 1 ? penW : 2);
        dc.drawLine(cx - (r * 0.45).toNumber(), cy, cx - (r * 0.1).toNumber(), cy + (r * 0.35).toNumber());
        dc.drawLine(cx - (r * 0.1).toNumber(), cy + (r * 0.35).toNumber(), cx + (r * 0.5).toNumber(), cy - (r * 0.3).toNumber());
        dc.setPenWidth(1);
    }
}
