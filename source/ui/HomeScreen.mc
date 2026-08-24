import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Turn 6's home mockup (6a): the app opens on the chase itself - the cat
// trailing the mouse across the top in a slow loop is the only motion -
// over the CAT&MOUSE wordmark and a three-row menu. START is pre-selected
// so a returning player opens and presses once. UP/DOWN moves the
// selection, SELECT chooses; the selected row is the only filled shape on
// screen. Orange setup-family rim.
module HomeScreen {

    var _catCharacter as Character?;
    var _mouseCharacter as Character?;

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController, phase as Float) as Void {
        Hud.drawRim(dc, metrics, Palette.SETUP_RIM, 14);
        drawNavTriangles(dc, metrics);
        drawChaseVignette(dc, metrics, phase);
        drawWordmark(dc, metrics);
        drawMenu(dc, metrics, controller.homeIndex());
    }

    // Same left-edge UP/DOWN affordance as setup, but in the rim colour
    // like mockup 6a (quieter than setup's grey - the menu is the focus).
    function drawNavTriangles(dc as Graphics.Dc, metrics as ScreenMetrics) as Void {
        var x = metrics.px(35);
        var w = metrics.px(9);
        dc.setColor(Palette.SETUP_RIM, Graphics.COLOR_TRANSPARENT);

        var upY = metrics.centerY - metrics.px(31);
        dc.fillPolygon([
            [x - w, upY + w],
            [x, upY - w],
            [x + w, upY + w]
        ]);

        var downY = metrics.centerY + metrics.px(47);
        dc.fillPolygon([
            [x - w, downY - w],
            [x, downY + w],
            [x + w, downY - w]
        ]);
    }

    // Cat chasing the mouse across the top band (6a: insets 96, feet ~y134;
    // cat r33 creeping slowly, mouse r23 scurrying).
    function drawChaseVignette(dc as Graphics.Dc, metrics as ScreenMetrics, phase as Float) as Void {
        if (_catCharacter == null) {
            _catCharacter = new Character(GameConstants.ROLE_CAT);
        }
        if (_mouseCharacter == null) {
            _mouseCharacter = new Character(GameConstants.ROLE_MOUSE);
        }
        var catRadius = metrics.px(33);
        var mouseRadius = metrics.px(23);
        var feetY = metrics.px(134);
        var catX = metrics.px(96) + catRadius;
        var mouseX = metrics.width - metrics.px(96) - mouseRadius;

        // The cat creeps on a slower clock than the mouse's scurry (1.4s vs
        // .5s in the mockup).
        (_catCharacter as Character).draw(dc, catX, feetY - catRadius, catRadius, 1, phase * 0.6, 0.0, GameConstants.DANGER_STAGE_REST, Palette.BLACK);
        (_mouseCharacter as Character).draw(dc, mouseX, feetY - mouseRadius, mouseRadius, 1, phase, 0.0, GameConstants.DANGER_STAGE_REST, Palette.BLACK);
    }

    // CAT&MOUSE - cream with the ampersand in brand orange (6a, y142).
    function drawWordmark(dc as Graphics.Dc, metrics as ScreenMetrics) as Void {
        var left = WatchUi.loadResource(Rez.Strings.HomeTitleLeft) as String;
        var amp = WatchUi.loadResource(Rez.Strings.HomeTitleAmp) as String;
        var right = WatchUi.loadResource(Rez.Strings.HomeTitleRight) as String;

        // Largest tier whose full wordmark fits the safe width.
        var tier = 4;
        var maxW = metrics.width - metrics.px(90);
        var font = metrics.fontFor(tier);
        while (tier > 1 && dc.getTextWidthInPixels(left + amp + right, font) > maxW) {
            tier -= 1;
            font = metrics.fontFor(tier);
        }

        var leftW = dc.getTextWidthInPixels(left, font);
        var ampW = dc.getTextWidthInPixels(amp, font);
        var rightW = dc.getTextWidthInPixels(right, font);
        var startX = metrics.centerX - (leftW + ampW + rightW) / 2;
        var y = metrics.isRound ? metrics.px(142) : metrics.px(60);

        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, y, font, left, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Palette.BRAND_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + leftW, y, font, amp, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + leftW + ampW, y, font, right, Graphics.TEXT_JUSTIFY_LEFT);
    }

    // Three stacked pills (6a: y196, gap 9): the selected row is the only
    // filled shape; unselected rows are outlined with grey labels.
    function drawMenu(dc as Graphics.Dc, metrics as ScreenMetrics, selectedIndex as Number) as Void {
        var labels = [
            WatchUi.loadResource(Rez.Strings.HomeStart) as String,
            WatchUi.loadResource(Rez.Strings.HomeHowTo) as String,
            WatchUi.loadResource(Rez.Strings.HomeExit) as String
        ];
        var y = metrics.isRound ? metrics.px(196) : metrics.px(104);
        var rowGap = metrics.px(9);

        for (var i = 0; i < labels.size(); i += 1) {
            var selected = (i == selectedIndex);
            var h = selected ? metrics.px(54) : metrics.px(44);
            var w = selected ? metrics.px(196) : metrics.px(176);
            var chipX = metrics.centerX - (w / 2);
            var radius = h / 2;
            var font = metrics.fontFor(selected ? 2 : 1);

            if (selected) {
                dc.setColor(Palette.BRAND_ORANGE, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(chipX, y, w, h, radius);
                dc.setColor(Palette.INK, Graphics.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Palette.DK_PANEL, Graphics.COLOR_TRANSPARENT);
                dc.setPenWidth(metrics.px(3) > 0 ? metrics.px(3) : 1);
                dc.drawRoundedRectangle(chipX, y, w, h, radius);
                dc.setPenWidth(1);
                dc.setColor(Palette.CHIP_GREY, Graphics.COLOR_TRANSPARENT);
            }
            dc.drawText(metrics.centerX, y + h / 2, font, labels[i], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            y += h + rowGap;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }
}
