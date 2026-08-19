import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.Activity;

class GameController {

    const TICK_MS = 1000;
    const WARMUP_FRACTION = 0.075;      // within the 5-10% spec
    const WARMUP_MAX_SECONDS = 300.0;   // never more than 5 minutes

    var state as Number;

    private var _timer as Timer.Timer?;
    private var _chase as ChaseModel?;
    private var _recorder as ActivityRecorder;

    private var _totalGameSeconds as Float;
    private var _warmupSeconds as Float;
    private var _elapsedTotal as Float;
    private var _warmupElapsed as Float;
    private var _roundIndex as Number;
    private var _stateBeforePause as Number;
    private var _lastCatchWasPlayerCaught as Boolean;

    function initialize() {
        state = GameConstants.STATE_SETUP;
        _recorder = new ActivityRecorder();
        _totalGameSeconds = 0.0;
        _warmupSeconds = 0.0;
        _elapsedTotal = 0.0;
        _warmupElapsed = 0.0;
        _roundIndex = 0;
        _stateBeforePause = GameConstants.STATE_SETUP;
        _lastCatchWasPlayerCaught = false;
    }

    function configureAndStart(lengthMinutes as Number, intensity as Number) as Void {
        _totalGameSeconds = lengthMinutes * 60.0;
        _warmupSeconds = _totalGameSeconds * WARMUP_FRACTION;
        if (_warmupSeconds > WARMUP_MAX_SECONDS) {
            _warmupSeconds = WARMUP_MAX_SECONDS;
        }

        _chase = new ChaseModel(intensity);
        _elapsedTotal = 0.0;
        _warmupElapsed = 0.0;
        _roundIndex = 0;

        _recorder.start();
        state = GameConstants.STATE_WARMUP;

        _timer = new Timer.Timer();
        _timer.start(method(:onTick), TICK_MS, true);
    }

    function togglePause() as Void {
        if (state == GameConstants.STATE_PAUSED) {
            state = _stateBeforePause;
            _timer = new Timer.Timer();
            _timer.start(method(:onTick), TICK_MS, true);
        } else if (state != GameConstants.STATE_SETUP && state != GameConstants.STATE_SUMMARY) {
            _stateBeforePause = state;
            state = GameConstants.STATE_PAUSED;
            if (_timer != null) {
                _timer.stop();
                _timer = null;
            }
        }
        WatchUi.requestUpdate();
    }

    function onTick() as Void {
        var dt = 1.0;
        _elapsedTotal += dt;

        if (_elapsedTotal >= _totalGameSeconds) {
            endGame();
            return;
        }

        if (state == GameConstants.STATE_WARMUP) {
            _warmupElapsed += dt;
            if (_warmupElapsed >= _warmupSeconds) {
                beginRound(GameConstants.STATE_CHASED);
            }
        } else if (state == GameConstants.STATE_CHASED || state == GameConstants.STATE_CHASING) {
            var chase = _chase as ChaseModel;
            var direction = (state == GameConstants.STATE_CHASING) ? 1 : -1;
            var roundOver = chase.tick(currentPlayerSpeed(), dt, direction);
            if (roundOver) {
                _lastCatchWasPlayerCaught = (state == GameConstants.STATE_CHASED);
                var nextState = (state == GameConstants.STATE_CHASED) ? GameConstants.STATE_CHASING : GameConstants.STATE_CHASED;
                beginRound(nextState);
            }
        }

        WatchUi.requestUpdate();
    }

    private function beginRound(nextState as Number) as Void {
        _roundIndex += 1;
        state = nextState;
        (_chase as ChaseModel).startRound(_roundIndex);
    }

    private function endGame() as Void {
        state = GameConstants.STATE_SUMMARY;
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        _recorder.stop();
        WatchUi.requestUpdate();
    }

    function currentPlayerSpeed() as Float {
        var info = Activity.getActivityInfo();
        if (info != null && info.currentSpeed != null) {
            return info.currentSpeed;
        }
        return 0.0;
    }

    function chase() as ChaseModel? {
        return _chase;
    }

    function elapsedTotal() as Float {
        return _elapsedTotal;
    }

    function totalGameSeconds() as Float {
        return _totalGameSeconds;
    }

    function warmupRemaining() as Float {
        var remaining = _warmupSeconds - _warmupElapsed;
        return (remaining > 0.0) ? remaining : 0.0;
    }

    function roundIndex() as Number {
        return _roundIndex;
    }

    function playerCaughtByChaser() as Boolean {
        return _lastCatchWasPlayerCaught;
    }
}
