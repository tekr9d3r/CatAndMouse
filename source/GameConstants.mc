import Toybox.Lang;
import Toybox.Position;

module GameConstants {
    const STATE_SETUP = 0;
    const STATE_WARMUP = 1;
    const STATE_CHASED = 2;
    const STATE_CHASING = 3;
    const STATE_PAUSED = 4;
    const STATE_SUMMARY = 5;
    const STATE_BREAK = 6;
    const STATE_HOME = 7;
    const STATE_INSTRUCTIONS = 8;

    // Home menu rows (turn 6 mockup 6a), top to bottom.
    const HOME_START = 0;
    const HOME_HOW_TO = 1;
    const HOME_EXIT = 2;
    const HOME_OPTION_COUNT = 3;

    const INSTRUCTIONS_PAGE_COUNT = 3;

    const INTENSITY_EASY = 0;
    const INTENSITY_MEDIUM = 1;
    const INTENSITY_HARD = 2;

    const SETUP_INTENSITY_OPTIONS = [INTENSITY_EASY, INTENSITY_MEDIUM, INTENSITY_HARD];

    // Outcome of the round just finished, from the player's perspective.
    const OUTCOME_CAUGHT_BY_CAT = 0;    // was the mouse, got caught
    const OUTCOME_ESCAPED_AS_MOUSE = 1; // was the mouse, survived to the round timeout
    const OUTCOME_CAUGHT_TARGET = 2;    // was the cat, caught the mouse
    const OUTCOME_TARGET_ESCAPED = 3;   // was the cat, mouse survived to the round timeout

    // Why the round just finished (mirrors ChaseModel.roundEndReason). Kept
    // here rather than as class consts on ChaseModel/Character since Monkey C
    // class-level consts aren't reachable as ClassName.CONST from outside the
    // class - only module consts are.
    const REASON_NONE = 0;
    const REASON_CAUGHT = 1;
    const REASON_TIMEOUT = 2;

    const INITIAL_GAP_METERS = 50.0;
    const CATCH_THRESHOLD_METERS = 5.0;

    const ROLE_CAT = 0;
    const ROLE_MOUSE = 1;

    // Safety valve so a matched pace can't stall a round forever. Lives here
    // (not as a ChaseModel class const) because Monkey C class-level consts
    // aren't reachable as ClassName.CONST from outside the class - only
    // module consts are, and GameController's scoring needs this value too.
    const ROUND_MAX_SECONDS = 240.0;

    // Warmup is a fixed duration, independent of any game length (there is
    // no game length anymore - a session runs until ended from the
    // in-activity menu).
    const WARMUP_FIXED_SECONDS = 300.0; // 5 minutes

    // How long before the warmup ends the "cat wakes up" warning fires -
    // matches the mockup's "eyes open in the last 10s + one warning buzz".
    const WARMUP_WARNING_SECONDS = 10.0;

    // --- Danger staging, shared by ChaseScreen (visuals) and Feedback
    // (haptics) so both read the same three-tier state off the same gap.
    // Design intent (turn 2/4 mockups): resting is the vast majority of a
    // round (~70%), closing is a warning band, and the final "about to be
    // caught/about to pounce" band is rare enough to stay a shock.
    const DANGER_STAGE_REST = 0;
    const DANGER_STAGE_CLOSING = 1;
    const DANGER_STAGE_DANGER = 2;

    const DANGER_CLOSING_THRESHOLD = 0.35;
    const DANGER_DANGER_THRESHOLD = 0.72;

    // 0.0 (gap at INITIAL_GAP_METERS, totally safe) .. 1.0 (gap at
    // CATCH_THRESHOLD_METERS, about to end the round).
    function dangerFraction(gap as Float) as Float {
        var g = gap;
        if (g > INITIAL_GAP_METERS) {
            g = INITIAL_GAP_METERS;
        } else if (g < CATCH_THRESHOLD_METERS) {
            g = CATCH_THRESHOLD_METERS;
        }
        var span = INITIAL_GAP_METERS - CATCH_THRESHOLD_METERS;
        return 1.0 - ((g - CATCH_THRESHOLD_METERS) / span);
    }

    function dangerStage(fraction as Float) as Number {
        if (fraction >= DANGER_DANGER_THRESHOLD) {
            return DANGER_STAGE_DANGER;
        } else if (fraction >= DANGER_CLOSING_THRESHOLD) {
            return DANGER_STAGE_CLOSING;
        }
        return DANGER_STAGE_REST;
    }

    // --- GPS status, shown on the setup screens so the user can see a fix
    // is coming in before they start (informational only - does not block
    // starting the game).
    const GPS_TIER_SEARCHING = 0; // no fix yet, or only a stale last-known one
    const GPS_TIER_WEAK = 1;      // 2-D fix only, poor precision
    const GPS_TIER_READY = 2;     // usable or good 3-D fix

    function gpsTier(accuracy as Number) as Number {
        if (accuracy >= Position.QUALITY_USABLE) {
            return GPS_TIER_READY;
        } else if (accuracy == Position.QUALITY_POOR) {
            return GPS_TIER_WEAK;
        }
        return GPS_TIER_SEARCHING;
    }
}
