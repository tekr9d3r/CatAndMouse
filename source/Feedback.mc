import Toybox.Attention;
import Toybox.Lang;

// Centralizes every Attention (tone/vibration) call in one place, wired from
// GameController state transitions and the per-tick proximity check. Kept
// separate from ChaseModel so the simulation stays free of any WatchUi/
// Attention dependency.
//
// None of this project's current target devices have a real speaker -
// Attention.playTone() only plays from a fixed system beep enum, identical
// across every app, so there is no "sound design" here beyond picking which
// stock tone (if any) fires at each moment. Vibration is the channel that's
// actually authored, following the mockup's documented rhythm: silent at
// rest, one short pulse per ~10m of gap closed in the "closing" stage, and a
// continuous buzz in the final "about to be caught/about to pounce" stage -
// a dread double-buzz for the mouse role, a celebratory triple-buzz for the
// cat role (turn 4's "fast triple-buzz, distinct from the mouse role's
// dread double-buzz"). Stage boundaries come from GameConstants.dangerStage
// so haptics and the ChaseScreen visuals never disagree about what stage a
// given gap is in.
class Feedback {

    const PULSE_GAP_STEP_METERS = 10.0;

    private var _hasVibrate as Boolean;
    private var _hasTone as Boolean;
    private var _lastStage as Number;
    private var _lastPulseGap as Float;

    function initialize() {
        _hasVibrate = (Attention has :vibrate);
        _hasTone = (Attention has :playTone);
        _lastStage = GameConstants.DANGER_STAGE_REST;
        _lastPulseGap = GameConstants.INITIAL_GAP_METERS;
    }

    function onRoundStart() as Void {
        _lastStage = GameConstants.DANGER_STAGE_REST;
        _lastPulseGap = GameConstants.INITIAL_GAP_METERS;
        tone(Attention.TONE_START);
        vibrate([new Attention.VibeProfile(100, 300)]);
    }

    // Called once per 1Hz game tick while a round is still in progress (not
    // on the tick that ends it - onRoundEnd covers that separately).
    // wasMouse: true when the player is the one being chased this round
    // (fear stage - red flood, double-buzz), false when the player is the
    // cat (pounce stage - orange flood, triple-buzz). Red must never fire
    // for the cat role, so the two branches stay fully separate here.
    function onProximityTick(gap as Float, wasMouse as Boolean) as Void {
        var stage = GameConstants.dangerStage(GameConstants.dangerFraction(gap));

        if (stage != _lastStage) {
            if (stage == GameConstants.DANGER_STAGE_CLOSING) {
                // Baseline the 10m pulse grid from the gap at entry, rather
                // than pulsing immediately on crossing into the stage.
                _lastPulseGap = gap;
            } else if (stage == GameConstants.DANGER_STAGE_DANGER) {
                tone(wasMouse ? Attention.TONE_ALERT_HI : Attention.TONE_ALERT_LO);
            }
            _lastStage = stage;
        }

        if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            if ((_lastPulseGap - gap) >= PULSE_GAP_STEP_METERS) {
                _lastPulseGap = gap;
                vibrate([new Attention.VibeProfile(50, 150)]);
            }
        } else if (stage == GameConstants.DANGER_STAGE_DANGER) {
            if (wasMouse) {
                vibrate([
                    new Attention.VibeProfile(100, 150),
                    new Attention.VibeProfile(0, 60),
                    new Attention.VibeProfile(100, 150)
                ]);
            } else {
                vibrate([
                    new Attention.VibeProfile(100, 110),
                    new Attention.VibeProfile(0, 50),
                    new Attention.VibeProfile(100, 110),
                    new Attention.VibeProfile(0, 50),
                    new Attention.VibeProfile(100, 110)
                ]);
            }
        }
    }

    // "The cat wakes in the last 10s" - one warning buzz, fired once as the
    // warmup countdown crosses the threshold (see turn 3's warmup mockup).
    function onWarmupWarning() as Void {
        vibrate([new Attention.VibeProfile(60, 250)]);
    }

    function onRoundEnd(playerWon as Boolean) as Void {
        if (playerWon) {
            tone(Attention.TONE_SUCCESS);
            vibrate([
                new Attention.VibeProfile(80, 120),
                new Attention.VibeProfile(0, 80),
                new Attention.VibeProfile(80, 120)
            ]);
        } else {
            tone(Attention.TONE_FAILURE);
            vibrate([new Attention.VibeProfile(100, 500)]);
        }
    }

    function onBreakStart() as Void {
        vibrate([new Attention.VibeProfile(30, 200)]);
    }

    function onGameSummary() as Void {
        tone(Attention.TONE_KEY);
    }

    private function vibrate(profiles as Array<Attention.VibeProfile>) as Void {
        if (!_hasVibrate) {
            return;
        }
        try {
            Attention.vibrate(profiles);
        } catch (ex) {
        }
    }

    private function tone(t as Attention.Tone) as Void {
        if (!_hasTone) {
            return;
        }
        try {
            Attention.playTone(t);
        } catch (ex) {
        }
    }
}
