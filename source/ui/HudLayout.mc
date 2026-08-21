import Toybox.Lang;

// Named anchor points for the two screen compositions (round/semi-round vs
// rectangle). Per-state screens ask this for "where things go" instead of
// each recomputing geometry inline - this is what generalizes round vs.
// rectangle once, replacing Stage 1's hardcoded y += 26 loop.
class HudLayout {

    var titleY as Number;
    var bodyStartY as Number;
    var bodyLineHeight as Number;
    var hintY as Number;
    var scoreY as Number;

    // Where the chase stage (characters + proximity meter) lives, as a
    // vertical band between the title and the body text - used starting
    // in Stage 2c once characters are drawn there.
    var stageTop as Number;
    var stageBottom as Number;

    function initialize(metrics as ScreenMetrics) {
        if (metrics.isRound) {
            // Round screens lose usable area in the corners, so content is
            // inset further from top/bottom to stay clear of the curve.
            // Values ported from the 416px mockup (turn 3's setup/warmup/
            // break/paused/summary screens all share this rhythm: title
            // ~top:60, main content ~top:110 to height-90, hint ~bottom:40).
            titleY = metrics.px(60);
            stageTop = metrics.px(112);
            stageBottom = metrics.height - metrics.px(92);
            bodyStartY = stageBottom + metrics.px(16);
            bodyLineHeight = metrics.px(30);
            scoreY = metrics.height - metrics.px(66);
            hintY = metrics.height - metrics.px(40);
        } else {
            // Rectangle screens have usable corners, so the safe margins
            // are tighter top/bottom and content can run closer to the edge.
            titleY = metrics.px(34);
            stageTop = metrics.px(66);
            stageBottom = metrics.height - metrics.px(78);
            bodyStartY = stageBottom + metrics.px(14);
            bodyLineHeight = metrics.px(28);
            scoreY = metrics.height - metrics.px(52);
            hintY = metrics.height - metrics.px(24);
        }
    }
}
