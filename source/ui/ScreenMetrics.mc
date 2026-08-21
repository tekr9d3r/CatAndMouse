import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;

// Runtime screen shape/resolution snapshot, recomputed once per onUpdate().
// Everything downstream scales off this instead of hardcoded pixel constants,
// so one layout works across the whole round+rectangle Garmin device range.
class ScreenMetrics {

    // The Claude Design handoff ("Cat and Mouse - Chase.dc.html") is the
    // authoritative visual spec and every mockup in it is drawn at 416x416
    // (the Instinct 3 AMOLED baseline), so pixel values are ported straight
    // from the mockup's CSS as px(<mockup value>) instead of converting
    // through the old 260px (fenix7/fr255) baseline.
    const BASELINE_MIN_DIM = 416.0;

    var width as Number;
    var height as Number;
    var centerX as Number;
    var centerY as Number;
    var minDim as Number;
    var scale as Float;
    var isRound as Boolean;

    function initialize(dc as Graphics.Dc) {
        width = dc.getWidth();
        height = dc.getHeight();
        centerX = width / 2;
        centerY = height / 2;
        minDim = (width < height) ? width : height;
        scale = minDim / BASELINE_MIN_DIM;

        var shape = System.getDeviceSettings().screenShape;
        isRound = (shape == System.SCREEN_SHAPE_ROUND
            || shape == System.SCREEN_SHAPE_SEMI_ROUND
            || shape == System.SCREEN_SHAPE_SEMI_OCTAGON);
    }

    // tier: 0=xtiny .. 3=large. Kept as a small discrete scale rather than
    // arbitrary point sizes since Monkey C fonts are a fixed system enum.
    function fontFor(tier as Number) as Graphics.FontType {
        var bumped = (scale >= 1.4) && (tier < 3);
        var t = bumped ? tier + 1 : tier;
        if (t <= 0) {
            return Graphics.FONT_XTINY;
        } else if (t == 1) {
            return Graphics.FONT_TINY;
        } else if (t == 2) {
            return Graphics.FONT_SMALL;
        } else if (t == 3) {
            return Graphics.FONT_MEDIUM;
        }
        return Graphics.FONT_LARGE;
    }

    // Convert a "designed at baseline" pixel length to this screen's scale.
    function px(baselinePixels as Number or Float) as Number {
        return (baselinePixels * scale).toNumber();
    }
}
