import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Turn 3's warmup mockup (3c): the countdown is framed as "the cat sleeping"
// - playful, and it primes the chase. Eyes open (closed lines -> open
// circles) in the final GameConstants.WARMUP_WARNING_SECONDS, matching the
// single warning buzz Feedback.onWarmupWarning() fires at the same instant.
module WarmupScreen {
    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController) as Void {
        Hud.drawRim(dc, metrics, Palette.RECOVERY_RIM, 14);

        dc.setColor(Palette.RECOVERY_TITLE, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, layout.titleY, 2, WatchUi.loadResource(Rez.Strings.StateWarmup) as String);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var remaining = controller.warmupRemaining();
        var awake = remaining <= GameConstants.WARMUP_WARNING_SECONDS;
        var catY = metrics.isRound ? metrics.px(160) : layout.stageTop + metrics.px(50);
        drawSleepingCat(dc, metrics, catY, awake);

        var labelY = metrics.isRound ? metrics.px(238) : (catY + metrics.px(76));
        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, labelY, 1, WatchUi.loadResource(Rez.Strings.WarmupWakesIn) as String);

        // Mockup: 64px digits centered on y294 of 416. Garmin number fonts
        // vary a lot per device, so cap the height and anchor the center so
        // the countdown can't spill into the pace line below.
        var countdownFont = countdownFontFor(metrics);
        if (dc.getFontHeight(countdownFont) > metrics.px(110)) {
            countdownFont = Graphics.FONT_NUMBER_MILD;
        }
        var countdownY = metrics.isRound
            ? (metrics.px(294) - dc.getFontHeight(countdownFont) / 2)
            : (labelY + metrics.px(26));
        dc.setColor(Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(metrics.centerX, countdownY, countdownFont, Utils.formatSeconds(remaining), Graphics.TEXT_JUSTIFY_CENTER);

        var paceFont = metrics.fontFor(1);
        var paceY = metrics.isRound ? (metrics.height - metrics.px(62) - dc.getFontHeight(paceFont)) : layout.hintY;
        dc.setColor(Palette.RECOVERY_TITLE, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, paceY, 1, "PACE " + Utils.speedToPaceString(controller.currentPlayerSpeed()));

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    function countdownFontFor(metrics as ScreenMetrics) as Graphics.FontType {
        if (metrics.scale >= 0.85) {
            return Graphics.FONT_NUMBER_MEDIUM;
        }
        return Graphics.FONT_NUMBER_MILD;
    }

    function drawSleepingCat(dc as Graphics.Dc, metrics as ScreenMetrics, cy as Number, awake as Boolean) as Void {
        var cx = metrics.centerX;
        var headR = metrics.px(44);
        if (headR < 10) {
            headR = 10;
        }

        // Same ear geometry as Character: apex ~0.5 radii above the circle,
        // base tucked just inside it.
        dc.setColor(Palette.BRAND_ORANGE, Graphics.COLOR_TRANSPARENT);
        var earHalf = (headR * 0.32).toNumber();
        var earOffset = (headR * 0.54).toNumber();
        var apexY = cy - (headR * 1.5).toNumber();
        var baseY = cy - (headR * 0.75).toNumber();
        dc.fillPolygon([
            [cx - earOffset, apexY],
            [cx - earOffset + earHalf, baseY],
            [cx - earOffset - earHalf, baseY]
        ]);
        dc.fillPolygon([
            [cx + earOffset, apexY],
            [cx + earOffset + earHalf, baseY],
            [cx + earOffset - earHalf, baseY]
        ]);
        dc.fillCircle(cx, cy, headR);
        // Tail: a rounded bar off to the right, per mockup 3c.
        var tailH = metrics.px(10);
        if (tailH < 2) {
            tailH = 2;
        }
        dc.fillRoundedRectangle(cx + headR - metrics.px(6), cy + headR / 2 - tailH / 2, metrics.px(44), tailH, tailH / 2);

        if (awake) {
            dc.setColor(Palette.BLACK, Graphics.COLOR_TRANSPARENT);
            var eyeR = headR / 6;
            if (eyeR < 2) {
                eyeR = 2;
            }
            dc.fillCircle(cx - headR / 2, cy + headR / 10, eyeR);
            dc.fillCircle(cx + headR / 2, cy + headR / 10, eyeR);
        } else {
            dc.setColor(Palette.BLACK, Graphics.COLOR_TRANSPARENT);
            var lineWidth = metrics.px(3);
            dc.setPenWidth(lineWidth > 0 ? lineWidth : 1);
            dc.drawLine(cx - headR * 7 / 10, cy + headR / 10, cx - headR * 3 / 10, cy + headR / 10);
            dc.drawLine(cx + headR * 3 / 10, cy + headR / 10, cx + headR * 7 / 10, cy + headR / 10);
            dc.setPenWidth(1);

            dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx + headR + metrics.px(4), cy - headR, metrics.fontFor(1), "z z", Graphics.TEXT_JUSTIFY_LEFT);
        }
    }
}
