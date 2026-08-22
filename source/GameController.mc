import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.Activity;

class GameController {

    const TICK_MS = 1000;

    var state as Number;

    private var _timer as Timer.Timer?;
    private var _chase as ChaseModel?;
    private var _recorder as ActivityRecorder;
    private var _feedback as Feedback;
    private var _gps as GpsStatus;

    private var _warmupSeconds as Float;
    private var _elapsedTotal as Float;
    private var _warmupElapsed as Float;
    private var _roundIndex as Number;
    private var _stateBeforePause as Number;
    private var _score as Number;
    private var _lastRoundPoints as Number;
    private var _pendingNextState as Number;
    private var _lastRoundOutcome as Number;
    private var _warmupWarned as Boolean;

    private var _setupIntensityIndex as Number;

    function initialize() {
        state = GameConstants.STATE_SETUP;
        _recorder = new ActivityRecorder();
        _feedback = new Feedback();
        _gps = new GpsStatus();
        _warmupSeconds = 0.0;
        _elapsedTotal = 0.0;
        _warmupElapsed = 0.0;
        _roundIndex = 0;
        _stateBeforePause = GameConstants.STATE_SETUP;
        _score = 0;
        _lastRoundPoints = 0;
        _pendingNextState = GameConstants.STATE_CHASED;
        _lastRoundOutcome = GameConstants.OUTCOME_ESCAPED_AS_MOUSE;
        _warmupWarned = false;
        _setupIntensityIndex = 1; // default to Medium
    }

    function setupMoveNext() as Void {
        setupMove(1);
    }

    function setupMovePrevious() as Void {
        setupMove(-1);
    }

    private function setupMove(delta as Number) as Void {
        var count = GameConstants.SETUP_INTENSITY_OPTIONS.size();
        _setupIntensityIndex = ((_setupIntensityIndex + delta) + count) % count;
        WatchUi.requestUpdate();
    }

    function setupConfirm() as Void {
        var intensity = GameConstants.SETUP_INTENSITY_OPTIONS[_setupIntensityIndex] as Number;
        configureAndStart(intensity);
    }

    function setupIntensityIndex() as Number {
        return _setupIntensityIndex;
    }

    function configureAndStart(intensity as Number) as Void {
        _warmupSeconds = GameConstants.WARMUP_FIXED_SECONDS;

        _chase = new ChaseModel(intensity);
        _elapsedTotal = 0.0;
        _warmupElapsed = 0.0;
        _roundIndex = 0;
        _score = 0;
        _lastRoundPoints = 0;
        _warmupWarned = false;

        _recorder.start();
        state = GameConstants.STATE_WARMUP;

        _timer = new Timer.Timer();
        _timer.start(method(:onTick), TICK_MS, true);
    }

    // Applies to the next round only (see ChaseModel.changeIntensity) -
    // reachable from the in-activity menu while a session is running.
    function changeIntensity(newIntensity as Number) as Void {
        if (_chase != null) {
            (_chase as ChaseModel).changeIntensity(newIntensity);
        }
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

    // Guarded wrappers around togglePause() for the in-activity menu, which
    // needs to pause unconditionally (not toggle) when opened, and only
    // resume if it actually paused things. Menu access itself is excluded
    // from SETUP/SUMMARY at the call site (GameDelegate.onMenu()), so those
    // states never reach here, but the guards make these safe regardless.
    function ensurePausedForMenu() as Void {
        if (state != GameConstants.STATE_PAUSED && state != GameConstants.STATE_SETUP && state != GameConstants.STATE_SUMMARY) {
            togglePause();
        }
    }

    function resumeFromMenu() as Void {
        if (state == GameConstants.STATE_PAUSED) {
            togglePause();
        }
    }

    function onTick() as Void {
        var dt = 1.0;
        _elapsedTotal += dt;

        if (state == GameConstants.STATE_WARMUP) {
            _warmupElapsed += dt;
            var warmupRemainingNow = _warmupSeconds - _warmupElapsed;
            if (!_warmupWarned && warmupRemainingNow <= GameConstants.WARMUP_WARNING_SECONDS) {
                _warmupWarned = true;
                _feedback.onWarmupWarning();
            }
            if (_warmupElapsed >= _warmupSeconds) {
                beginRound(GameConstants.STATE_CHASED);
            }
        } else if (state == GameConstants.STATE_CHASED || state == GameConstants.STATE_CHASING) {
            var chase = _chase as ChaseModel;
            var wasMouse = (state == GameConstants.STATE_CHASED);
            var direction = (state == GameConstants.STATE_CHASING) ? 1 : -1;
            var roundOver = chase.tick(currentPlayerSpeed(), dt, direction);
            if (roundOver) {
                var caught = (chase.roundEndReason == GameConstants.REASON_CAUGHT);
                var playerWon = false;
                if (wasMouse) {
                    _lastRoundOutcome = caught ? GameConstants.OUTCOME_CAUGHT_BY_CAT : GameConstants.OUTCOME_ESCAPED_AS_MOUSE;
                    playerWon = !caught;
                } else {
                    _lastRoundOutcome = caught ? GameConstants.OUTCOME_CAUGHT_TARGET : GameConstants.OUTCOME_TARGET_ESCAPED;
                    playerWon = caught;
                }
                _lastRoundPoints = playerWon ? 1 : 0;
                _score += _lastRoundPoints;
                var nextState = wasMouse ? GameConstants.STATE_CHASING : GameConstants.STATE_CHASED;
                _feedback.onRoundEnd(playerWon);
                enterBreak(nextState);
            } else {
                _feedback.onProximityTick(chase.gap, wasMouse);
            }
        }

        WatchUi.requestUpdate();
    }

    private function enterBreak(nextState as Number) as Void {
        _pendingNextState = nextState;
        state = GameConstants.STATE_BREAK;
        _feedback.onBreakStart();
    }

    function continueFromBreak() as Void {
        if (state != GameConstants.STATE_BREAK) {
            return;
        }
        beginRound(_pendingNextState);
        WatchUi.requestUpdate();
    }

    private function beginRound(nextState as Number) as Void {
        _roundIndex += 1;
        state = nextState;
        (_chase as ChaseModel).startRound(_roundIndex);
        _feedback.onRoundStart();
    }

    // The only way a session ends now - there's no more automatic time
    // limit, this is only ever called from the in-activity menu's "End
    // Activity" item.
    function endActivityAndSave() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        _recorder.stop();
        state = GameConstants.STATE_SUMMARY;
        _feedback.onGameSummary();
        WatchUi.requestUpdate();
    }

    // "Delete Activity" from the in-activity menu - discards the FIT
    // recording instead of saving it, and returns straight to setup rather
    // than a summary screen, since there's nothing worth summarizing for a
    // discarded run.
    function endActivityAndDiscard() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        _recorder.discard();
        resetToSetup();
        WatchUi.requestUpdate();
    }

    private function resetToSetup() as Void {
        state = GameConstants.STATE_SETUP;
        _chase = null;
        _elapsedTotal = 0.0;
        _warmupElapsed = 0.0;
        _roundIndex = 0;
        _score = 0;
        _lastRoundPoints = 0;
        _warmupWarned = false;
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

    function warmupRemaining() as Float {
        var remaining = _warmupSeconds - _warmupElapsed;
        return (remaining > 0.0) ? remaining : 0.0;
    }

    function roundIndex() as Number {
        return _roundIndex;
    }

    function score() as Number {
        return _score;
    }

    function lastRoundPoints() as Number {
        return _lastRoundPoints;
    }

    function lastRoundOutcome() as Number {
        return _lastRoundOutcome;
    }

    function pendingNextRole() as Number {
        return (_pendingNextState == GameConstants.STATE_CHASING) ? GameConstants.ROLE_CAT : GameConstants.ROLE_MOUSE;
    }

    function gpsAccuracy() as Number {
        return _gps.accuracy();
    }
}
