import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Graphical replacement for Stage 1's native Menu2 intensity picker,
// restyled to match the turn 3 setup mockup (3b): a muted-orange rim,
// vertically stacked pill chips with the selection as the only filled shape
// on screen, and a pair of left-edge UP/DOWN triangles marking the
// button-navigation affordance. There's no session-length step anymore -
// sessions run until ended from the in-activity menu - so this is the only
// setup screen: UP/DOWN (or a touch swipe, unified by
// BehaviorDelegate.onNextPage/onPreviousPage) cycles intensity, SELECT
// starts the game immediately.
module SetupScreen {

    var _previewCharacter as Character?;

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController, phase as Float) as Void {
        Hud.drawRim(dc, metrics, Palette.SETUP_RIM, 14);
        drawNavTriangles(dc, metrics);

        drawTitle(dc, metrics, layout, WatchUi.loadResource(Rez.Strings.MenuIntensityTitle) as String);
        drawGpsStatus(dc, metrics, layout, controller);
        drawChips(dc, metrics, layout, intensityLabels(), controller.setupIntensityIndex(), true);
        drawPreviewCharacter(dc, metrics, layout, controller.setupIntensityIndex(), phase);
        drawHint(dc, metrics, layout, WatchUi.loadResource(Rez.Strings.HintSetupStart) as String);
    }

    // Shown on the setup screen so the user has as much lead time as
    // possible to get a fix before starting - informational only, does not
    // block SELECT. A plain colour dot (no label - text here collided with
    // the title, see commit history). Sits at the same x as the nav
    // triangles (px(35) from the left edge) and dead center vertically, in
    // the gap between the up/down triangles - reuses screen real estate
    // already proven safe inside the round bezel rather than new geometry,
    // and stays clear of the chip stack and the intensity step's preview
    // mouse, which are all on the right/center of the screen.
    function drawGpsStatus(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController) as Void {
        var tier = GameConstants.gpsTier(controller.gpsAccuracy());
        var color;
        if (tier == GameConstants.GPS_TIER_READY) {
            color = Palette.GREEN;
        } else if (tier == GameConstants.GPS_TIER_WEAK) {
            color = Palette.AMBER;
        } else {
            color = Palette.RED;
        }

        var dotR = metrics.px(8);
        if (dotR < 3) {
            dotR = 3;
        }
        var x = metrics.px(35);
        var y = metrics.centerY;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, dotR);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    function intensityLabels() as Array<String> {
        return [
            WatchUi.loadResource(Rez.Strings.IntensityEasy) as String,
            WatchUi.loadResource(Rez.Strings.IntensityMedium) as String,
            WatchUi.loadResource(Rez.Strings.IntensityHard) as String
        ];
    }

    // A pair of left-edge chevrons marking UP/DOWN as the button-navigation
    // affordance, per the mockup - buttons-only baseline, no icon font needed.
    function drawNavTriangles(dc as Graphics.Dc, metrics as ScreenMetrics) as Void {
        var x = metrics.px(35);
        var w = metrics.px(9);
        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);

        var upY = metrics.centerY - metrics.px(40);
        dc.fillPolygon([
            [x - w, upY + w],
            [x, upY - w],
            [x + w, upY + w]
        ]);

        var downY = metrics.centerY + metrics.px(40);
        dc.fillPolygon([
            [x - w, downY - w],
            [x, downY + w],
            [x + w, downY - w]
        ]);
    }

    function drawTitle(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, title as String) as Void {
        dc.setColor(Palette.SETUP_TITLE, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, layout.titleY, 2, title);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    function drawHint(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, hint as String) as Void {
        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        // Mockups anchor the hint 58px off the bottom edge - higher than the
        // generic hint line so it clears the round bezel curve.
        var font = metrics.fontFor(1);
        var y = metrics.isRound ? (metrics.height - metrics.px(58) - dc.getFontHeight(font)) : layout.hintY;
        Hud.drawCenteredText(dc, metrics, y, 1, hint);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // Three pill chips stacked vertically; the selected one is the only
    // filled shape on screen and grows slightly so selection reads without
    // colour on MIP. Chip widths come straight from the mockups - the length
    // step (3a) runs wider chips than the intensity step (3b), whose stack
    // is shifted left to make room for the preview mouse.
    function drawChips(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, labels as Array<String>, selectedIndex as Number, leftAnchored as Boolean) as Void {
        var count = labels.size();
        var chipH = metrics.px(50);
        var selectedChipH = metrics.px(58);
        var chipW = leftAnchored ? metrics.px(150) : metrics.px(180);
        var selectedChipW = leftAnchored ? metrics.px(168) : metrics.px(200);
        var rowGap = metrics.px(14);
        var totalH = chipH * (count - 1) + selectedChipH + rowGap * (count - 1);
        var y = layout.stageTop + (((layout.stageBottom - layout.stageTop) - totalH) / 2);
        var centerX = leftAnchored ? (metrics.centerX - metrics.px(40)) : metrics.centerX;

        for (var i = 0; i < count; i += 1) {
            var selected = (i == selectedIndex);
            var h = selected ? selectedChipH : chipH;
            var w = selected ? selectedChipW : chipW;
            var chipX = centerX - (w / 2);
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
            dc.drawText(centerX, y + h / 2, font, labels[i], Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            y += h + rowGap;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // A small idle mouse whose pace previews the chosen intensity - faster
    // tail/leg animation for harder settings. Positioned right of the chip
    // stack, vertically centered against it (mockup 3b).
    function drawPreviewCharacter(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, intensityIndex as Number, phase as Float) as Void {
        if (_previewCharacter == null) {
            _previewCharacter = new Character(GameConstants.ROLE_MOUSE);
        }
        var speedMul = 1.0 + (intensityIndex * 0.6);
        var x = metrics.centerX + metrics.px(116);
        var y = metrics.centerY + metrics.px(16);
        (_previewCharacter as Character).draw(dc, x, y, metrics.px(28), -1, phase * speedMul, 0.0, GameConstants.DANGER_STAGE_REST, Palette.BLACK);
    }
}
