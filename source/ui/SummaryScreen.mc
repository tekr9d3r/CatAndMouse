import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Turn 3's summary mockup (3f): static hero character in the player's final
// role, the last outcome as the headline, two numbers. Idle state - no
// animation, safe to leave on screen (GameView already stops the animation
// clock here). Same orange rim family as setup.
module SummaryScreen {

    var _character as Character?;

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController) as Void {
        Hud.drawRim(dc, metrics, Palette.SUMMARY_RIM, 14);

        dc.setColor(Palette.SUMMARY_TITLE, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, layout.titleY, 2, WatchUi.loadResource(Rez.Strings.StateSummary) as String);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        // Round layout ports mockup 3f directly: hero character centered
        // ~y162 (box top 122, 80px tall), outcome headline at 242, the two
        // numbers bottom-anchored 96, footer bottom-anchored 62.
        var outcome = controller.lastRoundOutcome();
        var wasMouse = (outcome == GameConstants.OUTCOME_CAUGHT_BY_CAT || outcome == GameConstants.OUTCOME_ESCAPED_AS_MOUSE);
        var role = wasMouse ? GameConstants.ROLE_MOUSE : GameConstants.ROLE_CAT;
        if (_character == null || (_character as Character).role != role) {
            _character = new Character(role);
        }
        var win = OutcomeStrings.isWin(outcome);
        var heroY = metrics.isRound ? metrics.px(162) : (layout.stageTop + metrics.px(32));
        (_character as Character).smiling = win;
        (_character as Character).draw(dc, metrics.centerX, heroY, metrics.px(40), 1, 0.0, 0.0, GameConstants.DANGER_STAGE_REST, Palette.BLACK);
        dc.setColor(win ? Palette.GREEN : Palette.OFF_WHITE, Graphics.COLOR_TRANSPARENT);
        var headlineY = metrics.isRound ? metrics.px(242) : (layout.stageBottom + metrics.px(10));
        Hud.drawFitCenteredText(dc, metrics, headlineY, 3, WatchUi.loadResource(OutcomeStrings.idFor(outcome)) as String, metrics.width - metrics.px(70));

        var numbersFont = metrics.fontFor(2);
        var numbersY = metrics.isRound
            ? (metrics.height - metrics.px(96) - dc.getFontHeight(numbersFont))
            : (headlineY + metrics.px(56));
        drawRoundsAndScore(dc, metrics, numbersY, controller.roundIndex(), controller.score());

        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        var footerFont = metrics.fontFor(0);
        var footerY = metrics.isRound ? (metrics.height - metrics.px(62) - dc.getFontHeight(footerFont)) : layout.hintY;
        Hud.drawCenteredText(dc, metrics, footerY, 0, WatchUi.loadResource(Rez.Strings.SummaryFooter) as String);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    function drawRoundsAndScore(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, rounds as Number, score as Number) as Void {
        var font = metrics.fontFor(2);
        var roundsText = (WatchUi.loadResource(Rez.Strings.RoundsLabel) as String) + " " + rounds;
        var scoreText = (WatchUi.loadResource(Rez.Strings.ScoreLabel) as String) + " " + score;
        var gap = metrics.px(30);

        var roundsW = dc.getTextWidthInPixels(roundsText, font);
        var scoreW = dc.getTextWidthInPixels(scoreText, font);
        var startX = metrics.centerX - (roundsW + gap + scoreW) / 2;

        dc.setColor(Palette.OFF_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, y, font, roundsText, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(Palette.SUMMARY_TITLE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + roundsW + gap, y, font, scoreText, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
