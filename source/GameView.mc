import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Stage 2: thin per-frame dispatcher. Screen geometry lives in
// ScreenMetrics/HudLayout (source/ui/), content lives in one draw module per
// state (source/ui/*Screen.mc), so round-vs-rectangle and resolution scaling
// are handled once instead of duplicated per state as in Stage 1.
class GameView extends WatchUi.View {

    private var _animClock as AnimationClock;
    private var _lastState as Number;

    function initialize() {
        View.initialize();
        _animClock = new AnimationClock();
        _lastState = -1;
    }

    function onShow() as Void {
        syncAnimationClock(getApp().gameController.state);
    }

    function onHide() as Void {
        _animClock.stop();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var controller = getApp().gameController;
        var metrics = new ScreenMetrics(dc);
        var layout = new HudLayout(metrics);
        var state = controller.state;

        if (state != _lastState) {
            syncAnimationClock(state);
            _lastState = state;
        }

        if (state == GameConstants.STATE_HOME) {
            HomeScreen.draw(dc, metrics, layout, controller, _animClock.phase());
        } else if (state == GameConstants.STATE_INSTRUCTIONS) {
            InstructionsScreen.draw(dc, metrics, layout, controller);
        } else if (state == GameConstants.STATE_SETUP) {
            SetupScreen.draw(dc, metrics, layout, controller, _animClock.phase());
        } else if (state == GameConstants.STATE_WARMUP) {
            WarmupScreen.draw(dc, metrics, layout, controller);
        } else if (state == GameConstants.STATE_CHASED || state == GameConstants.STATE_CHASING) {
            ChaseScreen.draw(dc, metrics, layout, controller, _animClock.phase());
        } else if (state == GameConstants.STATE_BREAK) {
            BreakScreen.draw(dc, metrics, layout, controller, _animClock.phase());
        } else if (state == GameConstants.STATE_PAUSED) {
            PausedScreen.draw(dc, metrics, layout, controller);
        } else {
            SummaryScreen.draw(dc, metrics, layout, controller, _animClock.phase());
        }
    }

    // Animation only needs to run while something on screen is actually
    // moving - stopped during pause so the timer doesn't keep waking the CPU
    // and draining battery over what can be a 30+ minute run. Summary keeps
    // animating (turn 11's truce sway) since it's only reached after the
    // recording has already been stopped and saved, so there's no GPS session
    // left to protect.
    private function syncAnimationClock(state as Number) as Void {
        // Instructions are deliberately static (turn 6: "instructions
        // shouldn't compete with the copy"), so the clock stops there too.
        if (state == GameConstants.STATE_PAUSED || state == GameConstants.STATE_INSTRUCTIONS) {
            _animClock.stop();
        } else {
            _animClock.start();
        }
    }
}
