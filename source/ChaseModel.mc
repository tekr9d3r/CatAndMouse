import Toybox.Lang;
import Toybox.Math;

// Tracks the virtual character as a 1D distance gap (meters) to the player,
// rather than a simulated 2D position - the gap is purely a function of the
// real-time pace differential integrated over time. See project plan.
class ChaseModel {

    // Round-to-round difficulty ramp: each successive round's base/max speed
    // is 5% higher than the last (round 1 = 1.0x, round 2 = 1.05x, round 3 =
    // 1.1025x, ...). Compounding, not additive - since sessions no longer
    // have a time limit, this ramp is what eventually makes a round
    // unwinnable rather than a fixed end time. Kept as a class const (not in
    // GameConstants) since nothing outside ChaseModel reads it.
    const ROUND_ESCALATION_PCT = 0.05;

    var intensity as Number;
    var roundIndex as Number;
    var characterSpeed as Float;
    var gap as Float;
    var roundElapsed as Float;
    var roundEndReason as Number;

    private var _baseSpeed as Float;
    private var _maxSpeed as Float;
    private var _escalationPerSec as Float;

    function initialize(intensity as Number) {
        self.intensity = intensity;
        roundIndex = 0;
        characterSpeed = 0.0;
        gap = GameConstants.INITIAL_GAP_METERS;
        roundElapsed = 0.0;
        roundEndReason = GameConstants.REASON_NONE;
        _baseSpeed = 0.0;
        _maxSpeed = 0.0;
        _escalationPerSec = 0.0;
    }

    function startRound(roundIndex as Number) as Void {
        self.roundIndex = roundIndex;
        roundElapsed = 0.0;
        roundEndReason = GameConstants.REASON_NONE;
        gap = GameConstants.INITIAL_GAP_METERS;

        var params = paramsFor(intensity);
        var escalationMultiplier = Math.pow(1.0 + ROUND_ESCALATION_PCT, roundIndex - 1) as Float;
        _baseSpeed = (params.get(:base) as Float) * escalationMultiplier;
        _maxSpeed = (params.get(:max) as Float) * escalationMultiplier;
        _escalationPerSec = params.get(:escalationPerSec) as Float;
        characterSpeed = _baseSpeed;
    }

    // Takes effect on the next startRound() call, not retroactively on the
    // round in progress - changing intensity mid-round would be a jarring
    // difficulty jump. Round-to-round escalation is unaffected: it keeps
    // compounding off the same roundIndex regardless of this change.
    function changeIntensity(newIntensity as Number) as Void {
        intensity = newIntensity;
    }

    private function paramsFor(intensity as Number) as Dictionary {
        if (intensity == GameConstants.INTENSITY_EASY) {
            return { :base => 1.76, :max => 2.64, :escalationPerSec => 0.0032 };
        } else if (intensity == GameConstants.INTENSITY_HARD) {
            return { :base => 3.0, :max => 4.3, :escalationPerSec => 0.006 };
        }
        return { :base => 2.2, :max => 3.3, :escalationPerSec => 0.004 };
    }

    // direction: +1 while the player is chasing (gap shrinks when the player
    // is faster), -1 while the player is being chased (gap shrinks when the
    // player is slower). Returns true when the round has ended (catch or timeout).
    function tick(playerSpeed as Float, dt as Float, direction as Number) as Boolean {
        roundElapsed += dt;

        characterSpeed += _escalationPerSec * dt;
        if (characterSpeed > _maxSpeed) {
            characterSpeed = _maxSpeed;
        }

        gap += direction * (characterSpeed - playerSpeed) * dt;

        if (gap <= GameConstants.CATCH_THRESHOLD_METERS) {
            roundEndReason = GameConstants.REASON_CAUGHT;
        } else if (roundElapsed >= GameConstants.ROUND_MAX_SECONDS) {
            roundEndReason = GameConstants.REASON_TIMEOUT;
        }

        return (roundEndReason != GameConstants.REASON_NONE);
    }
}
