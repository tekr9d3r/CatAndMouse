import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Turn 3's break mockup (3d): waits for SELECT indefinitely, so it leads
// with what still costs the player - session time left, top. Outcome +
// score delta sit in the middle; the SELECT hint names the next role so
// the button is never a mystery. Blue recovery rim, same family as warmup
// and paused.
module BreakScreen {

    var _character as Character?;

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController, phase as Float) as Void {
        Hud.drawRim(dc, metrics, Palette.RECOVERY_RIM, 14);

        // Round layout is a straight port of mockup 3d's y coordinates
        // (416px frame): time top 56, character ~139, outcome 218,
        // score 266, then the two bottom-anchored prompt lines. Originally a
        // "game left" countdown; sessions no longer have a length limit, so
        // this now counts elapsed time up instead.
        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        var timeY = metrics.isRound ? metrics.px(56) : layout.titleY;
        Hud.drawCenteredText(dc, metrics, timeY, 1, (WatchUi.loadResource(Rez.Strings.TimeElapsedLabel) as String) + " " + Utils.formatSeconds(controller.elapsedTotal()));

        var nextRole = controller.pendingNextRole();
        var outcome = controller.lastRoundOutcome();
        var win = OutcomeStrings.isWin(outcome);

        // Mockup 3d pictures the role the player just finished (the escaped
        // mouse, smiling), not the upcoming one - the hint below names the
        // next role instead.
        var playedMouse = (outcome == GameConstants.OUTCOME_CAUGHT_BY_CAT || outcome == GameConstants.OUTCOME_ESCAPED_AS_MOUSE);
        drawPlayedRoleCharacter(dc, metrics, layout, playedMouse ? GameConstants.ROLE_MOUSE : GameConstants.ROLE_CAT, win, phase);
        dc.setColor(win ? Palette.GREEN : Palette.OFF_WHITE, Graphics.COLOR_TRANSPARENT);
        var headlineY = metrics.isRound ? metrics.px(218) : (layout.stageBottom + metrics.px(6));
        Hud.drawFitCenteredText(dc, metrics, headlineY, 3, WatchUi.loadResource(OutcomeStrings.breakIdFor(outcome)) as String, metrics.width - metrics.px(70));

        var scoreY = metrics.isRound ? metrics.px(266) : (headlineY + metrics.px(48));
        drawScoreWithDelta(dc, metrics, scoreY, controller.score(), controller.lastRoundPoints());

        var hintId = (nextRole == GameConstants.ROLE_CAT) ? Rez.Strings.HintBreakToChase : Rez.Strings.HintBreakToRun;
        dc.setColor(Palette.RECOVERY_TITLE, Graphics.COLOR_TRANSPARENT);
        var hintFont = metrics.fontFor(0);
        var hintY = metrics.isRound ? (metrics.height - metrics.px(74) - dc.getFontHeight(hintFont)) : layout.hintY;
        Hud.drawCenteredText(dc, metrics, hintY, 0, WatchUi.loadResource(hintId) as String);

        dc.setColor(Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        var captionFont = metrics.fontFor(0);
        var captionY = metrics.isRound ? (metrics.height - metrics.px(52) - dc.getFontHeight(captionFont)) : (layout.hintY + metrics.px(24));
        Hud.drawCenteredText(dc, metrics, captionY, 0, WatchUi.loadResource(Rez.Strings.BreakCaption) as String);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    function drawPlayedRoleCharacter(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, role as Number, win as Boolean, phase as Float) as Void {
        if (_character == null || (_character as Character).role != role) {
            _character = new Character(role);
        }
        var y = metrics.isRound ? metrics.px(139) : (layout.stageTop + metrics.px(30));
        (_character as Character).smiling = win;
        (_character as Character).draw(dc, metrics.centerX, y, metrics.px(35), 1, phase, 0.0, GameConstants.DANGER_STAGE_REST, Palette.BLACK);
    }

    function drawScoreWithDelta(dc as Graphics.Dc, metrics as ScreenMetrics, y as Number, score as Number, delta as Number) as Void {
        var font = metrics.fontFor(2);
        var scoreText = (WatchUi.loadResource(Rez.Strings.ScoreLabel) as String) + " " + score + " ";
        var deltaText = "+" + delta;

        var scoreW = dc.getTextWidthInPixels(scoreText, font);
        var deltaW = dc.getTextWidthInPixels(deltaText, font);
        var startX = metrics.centerX - (scoreW + deltaW) / 2;

        dc.setColor(Palette.OFF_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, y, font, scoreText, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(delta > 0 ? Palette.GREEN : Palette.MUTED_GREY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + scoreW, y, font, deltaText, Graphics.TEXT_JUSTIFY_LEFT);
    }
}
