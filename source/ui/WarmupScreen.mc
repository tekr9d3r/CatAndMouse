import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Turn 7's warmup mockup (7b): all words gone. A sleeping cat and a
// counting-down clock need no caption, and the rim drains through the five
// minutes so the wait has a shape. Live pace is the only secondary number.
//
// 7c is the same screen through the final GameConstants.WARMUP_WARNING_SECONDS:
// the wake cue is entirely graphic - the closed-eye lines open into wide
// circles, the countdown turns blue, and the label switches to CAT WAKES -
// at the same instant Feedback.onWarmupWarning() fires its single warning
// buzz. (7c's blinking is left out: this screen draws off the shared
// animation phase nothing else here needs.)
module WarmupScreen {

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController) as Void {
        var remaining = controller.warmupRemaining();
        var awake = remaining <= GameConstants.WARMUP_WARNING_SECONDS;

        // The rim is the warmup itself draining away (7b sits at 84% left,
        // 7c at 3%), replacing the old flat recovery-blue border.
        Hud.drawTimeRing(dc, metrics, remaining / GameConstants.WARMUP_FIXED_SECONDS, 16, Palette.BLUE, Palette.RECOVERY_RIM);

        var catY = metrics.isRound ? metrics.px(137) : (layout.stageTop + metrics.px(40));
        drawSleepingCat(dc, metrics, catY, awake);

        // 7b: the state as one short word at y206, not a sentence.
        var labelId = awake ? Rez.Strings.WarmupCatWakes : Rez.Strings.WarmupCatSleeps;
        var labelFont = metrics.fontFor(0);
        var labelY = metrics.isRound ? metrics.px(206) : (catY + metrics.px(70));
        dc.setColor(Palette.RECOVERY_TITLE, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, labelY, 0, WatchUi.loadResource(labelId) as String);

        var paceY = drawPace(dc, metrics, layout, controller);
        drawCountdown(dc, metrics, labelY + dc.getFontHeight(labelFont), paceY, remaining, awake);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // The mockup's 96px digits fill the gap between label and pace line
    // (block top 230, pace top 326 of 416). Rather than porting those two
    // numbers as fixed positions, the countdown takes the largest number
    // font that fits whatever gap this device's fonts actually leave, and
    // centres itself in it - the two neighbours can't be collided into.
    function drawCountdown(dc as Graphics.Dc, metrics as ScreenMetrics, bandTop as Number, bandBottom as Number, remaining as Float, awake as Boolean) as Void {
        var text = Utils.formatSeconds(remaining);
        var top = bandTop + metrics.px(6);
        var bottom = bandBottom - metrics.px(4);
        // Start at the largest number font there is rather than a per-device
        // guess: the fit loop steps down from whatever doesn't fit, so a big
        // screen gets the mockup's hero digits and a small one still lands
        // on the biggest size its own fonts allow.
        var font = Hud.fitNumberFont(dc, Graphics.FONT_NUMBER_THAI_HOT, text, (metrics.width * 0.72).toNumber(), bottom - top);

        var y = (top + bottom) / 2 - dc.getFontHeight(font) / 2;
        // 7c: the countdown itself goes blue for the wake window.
        dc.setColor(awake ? Palette.RECOVERY_TITLE : Palette.CREAM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(metrics.centerX, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Live pace, bottom-anchored 66 (7b) - the only secondary number left on
    // the screen. Returns its top edge so the countdown knows where to stop.
    function drawPace(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController) as Number {
        var font = metrics.fontFor(1);
        var text = Utils.speedToPaceString(controller.currentPlayerSpeed())
            + " " + (WatchUi.loadResource(Rez.Strings.PacePerKm) as String);
        var y = metrics.isRound
            ? (metrics.height - metrics.px(66) - dc.getFontHeight(font))
            : layout.hintY;

        dc.setColor(Palette.RECOVERY_TITLE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(metrics.centerX, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
        return y;
    }

    // 7b's cat, ported by ratio off the mockup's 118px body: ears up, tail
    // curled out to the left, and two closed-eye lines across the middle of
    // the face. No "z" - the mockup drops it, leaving the shut eyes to carry
    // the whole idea.
    function drawSleepingCat(dc as Graphics.Dc, metrics as ScreenMetrics, cy as Number, awake as Boolean) as Void {
        var cx = metrics.centerX;
        var headR = metrics.px(59);
        if (headR < 10) {
            headR = 10;
        }

        dc.setColor(Palette.BRAND_ORANGE, Graphics.COLOR_TRANSPARENT);

        // Same ear geometry as Character: apex ~0.5 radii above the circle,
        // base tucked just inside it.
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

        // Tail first so the body covers where it tucks under (7b: a rounded
        // bar off the left side, just below the midline).
        var tailH = (headR * 0.22).toNumber();
        if (tailH < 2) {
            tailH = 2;
        }
        var tailLen = (headR * 0.95).toNumber();
        var tailRight = cx - headR + (headR * 0.07).toNumber();
        dc.fillRoundedRectangle(tailRight - tailLen, cy + (headR * 0.02).toNumber(), tailLen, tailH, tailH / 2);

        dc.fillCircle(cx, cy, headR);

        var eyeOffset = (headR * 0.37).toNumber();
        dc.setColor(Palette.INK, Graphics.COLOR_TRANSPARENT);
        if (awake) {
            // 7c: wide open circles, twice the closed line's weight.
            var eyeR = (headR * 0.19).toNumber();
            if (eyeR < 2) {
                eyeR = 2;
            }
            dc.fillCircle(cx - eyeOffset, cy, eyeR);
            dc.fillCircle(cx + eyeOffset, cy, eyeR);
        } else {
            var lineW = (headR * 0.44).toNumber();
            var lineH = (headR * 0.10).toNumber();
            if (lineH < 2) {
                lineH = 2;
            }
            dc.fillRoundedRectangle(cx - eyeOffset - lineW / 2, cy - lineH / 2, lineW, lineH, lineH / 2);
            dc.fillRoundedRectangle(cx + eyeOffset - lineW / 2, cy - lineH / 2, lineW, lineH, lineH / 2);
        }
    }
}
