import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.Lang;

// A second, independent low-rate timer driving character animation phase,
// separate from GameController's 1Hz game-logic timer. GameView starts/stops
// this explicitly on state transitions so idle states (paused/summary) don't
// keep redrawing and draining battery over a long GPS session.
class AnimationClock {

    const INTERVAL_MS = 200;
    const PHASE_STEP = 0.35; // radians per tick

    private var _timer as Timer.Timer?;
    private var _phase as Float;

    function initialize() {
        _phase = 0.0;
    }

    function start() as Void {
        if (_timer != null) {
            return;
        }
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), INTERVAL_MS, true);
    }

    function stop() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        _phase += PHASE_STEP;
        WatchUi.requestUpdate();
    }

    function phase() as Float {
        return _phase;
    }
}
