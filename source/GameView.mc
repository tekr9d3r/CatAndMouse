import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Stage 1 UI is plain text only, drawn programmatically since each state
// shows a different set of dynamic lines - graphics/layout come in a later stage.
class GameView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var controller = getApp().gameController;
        var lines = linesForState(controller);

        var centerX = dc.getWidth() / 2;
        var y = 30;
        for (var i = 0; i < lines.size(); i += 1) {
            dc.drawText(centerX, y, Graphics.FONT_SMALL, lines[i] as String, Graphics.TEXT_JUSTIFY_CENTER);
            y += 26;
        }
    }

    private function linesForState(controller as GameController) as Array<String> {
        var state = controller.state;

        if (state == GameConstants.STATE_SETUP) {
            return [
                WatchUi.loadResource(Rez.Strings.SetupTitle) as String,
                WatchUi.loadResource(Rez.Strings.SetupPrompt) as String,
                WatchUi.loadResource(Rez.Strings.SetupPromptLine2) as String
            ];
        }

        if (state == GameConstants.STATE_WARMUP) {
            return [
                WatchUi.loadResource(Rez.Strings.StateWarmup) as String,
                "Warm up: " + Utils.formatSeconds(controller.warmupRemaining()),
                "Pace: " + Utils.speedToPaceString(controller.currentPlayerSpeed())
            ];
        }

        if (state == GameConstants.STATE_CHASED || state == GameConstants.STATE_CHASING) {
            var chase = controller.chase() as ChaseModel;
            var labelId = (state == GameConstants.STATE_CHASED) ? Rez.Strings.StateChased : Rez.Strings.StateChasing;
            return [
                (WatchUi.loadResource(labelId) as String) + "  R" + controller.roundIndex(),
                "Gap: " + chase.gap.format("%.0f") + " m",
                "You: " + Utils.speedToPaceString(controller.currentPlayerSpeed()),
                "Them: " + Utils.speedToPaceString(chase.characterSpeed)
            ];
        }

        if (state == GameConstants.STATE_PAUSED) {
            return [
                WatchUi.loadResource(Rez.Strings.StatePaused) as String,
                "Press SELECT",
                "to resume"
            ];
        }

        // STATE_SUMMARY
        var resultId = controller.playerCaughtByChaser() ? Rez.Strings.SummaryCaughtByChaser : Rez.Strings.SummaryCaughtTarget;
        return [
            WatchUi.loadResource(Rez.Strings.StateSummary) as String,
            WatchUi.loadResource(resultId) as String,
            "Rounds: " + controller.roundIndex()
        ];
    }
}
