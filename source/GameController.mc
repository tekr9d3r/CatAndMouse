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
    private var _feedback as Feedback;
    private var _gps as GpsStatus;

    private var _totalGameSeconds as Float;
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

    private var _setupStep as Number;
    private var _setupLengthIndex as Number;
    private var _setupIntensityIndex as Number;

    function initialize() {
        state = GameConstants.STATE_SETUP;
        _recorder = new ActivityRecorder();
        _feedback = new Feedback();
        _gps = new GpsStatus();
        _totalGameSeconds = 0.0;
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
        _setupStep = GameConstants.SETUP_STEP_LENGTH;
        _setupLengthIndex = 0;
        _setupIntensityIndex = 1; // default to Medium
    }

    function setupMoveNext() as Void {
        setupMove(1);
    }

    function setupMovePrevious() as Void {
        setupMove(-1);
    }

    private function setupMove(delta as Number) as Void {
        if (_setupStep == GameConstants.SETUP_STEP_LENGTH) {
            var count = GameConstants.SETUP_LENGTH_OPTIONS.size();
            _setupLengthIndex = ((_setupLengthIndex + delta) + count) % count;
        } else {
            var count = GameConstants.SETUP_INTENSITY_OPTIONS.size();
            _setupIntensityIndex = ((_setupIntensityIndex + delta) + count) % count;
        }
        WatchUi.requestUpdate();
    }

    function setupConfirm() as Void {
        if (_setupStep == GameConstants.SETUP_STEP_LENGTH) {
            _setupStep = GameConstants.SETUP_STEP_INTENSITY;
            WatchUi.requestUpdate();
        } else {
            var minutes = GameConstants.SETUP_LENGTH_OPTIONS[_setupLengthIndex] as Number;
            var intensity = GameConstants.SETUP_INTENSITY_OPTIONS[_setupIntensityIndex] as Number;
            _setupStep = GameConstants.SETUP_STEP_LENGTH;
            configureAndStart(minutes, intensity);
        }
    }

    function setupStep() as Number {
        return _setupStep;
    }

    function setupLengthIndex() as Number {
        return _setupLengthIndex;
    }

    function setupIntensityIndex() as Number {
        return _setupIntensityIndex;
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
        _score = 0;
        _lastRoundPoints = 0;
        _warmupWarned = false;

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
                _lastRoundPoints = playerWon ? computeRoundPoints(chase, wasMouse) : 0;
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

    // Points for the round that just ended, given a win. bonus (0-50) scales
    // by margin left for an escaping mouse, or by speed for a catching cat;
    // the whole thing scales again by intensity. See GameConstants for the
    // shared constants (SCORE_BASE_POINTS, SCORE_MAX_BONUS, multiplier).
    private function computeRoundPoints(chase as ChaseModel, wasMouse as Boolean) as Number {
        var bonus = 0;
        if (wasMouse) {
            var margin = chase.gap - GameConstants.CATCH_THRESHOLD_METERS;
            bonus = Utils.roundToInt(margin / GameConstants.SCORE_BONUS_GAP_SPAN_METERS * GameConstants.SCORE_MAX_BONUS);
        } else {
            var remaining = GameConstants.ROUND_MAX_SECONDS - chase.roundElapsed;
            bonus = Utils.roundToInt(remaining / GameConstants.ROUND_MAX_SECONDS * GameConstants.SCORE_MAX_BONUS);
        }
        bonus = Utils.clampInt(bonus, 0, GameConstants.SCORE_MAX_BONUS);

        var multiplier = GameConstants.intensityMultiplier(chase.intensity);
        return Utils.roundToInt((GameConstants.SCORE_BASE_POINTS + bonus) * multiplier);
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

    private function endGame() as Void {
        state = GameConstants.STATE_SUMMARY;
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
        _recorder.stop();
        _feedback.onGameSummary();
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
