import Toybox.Lang;

// Shared outcome->string mapping, used by both BreakScreen (feedback after
// each round) and SummaryScreen (feedback after the final round). The two
// screens use different registers in the design handoff: the break screen
// shouts in uppercase ("YOU ESCAPED!", 3d) while the summary headline is
// sentence case ("The mouse got away!", 3f).
module OutcomeStrings {
    function idFor(outcome as Number) as ResourceId {
        if (outcome == GameConstants.OUTCOME_CAUGHT_BY_CAT) {
            return Rez.Strings.OutcomeCaughtByCat;
        } else if (outcome == GameConstants.OUTCOME_CAUGHT_TARGET) {
            return Rez.Strings.OutcomeCaughtTarget;
        } else if (outcome == GameConstants.OUTCOME_TARGET_ESCAPED) {
            return Rez.Strings.OutcomeTargetEscaped;
        }
        return Rez.Strings.OutcomeEscapedAsMouse;
    }

    function breakIdFor(outcome as Number) as ResourceId {
        if (outcome == GameConstants.OUTCOME_CAUGHT_BY_CAT) {
            return Rez.Strings.BreakCaughtByCat;
        } else if (outcome == GameConstants.OUTCOME_CAUGHT_TARGET) {
            return Rez.Strings.BreakCaughtTarget;
        } else if (outcome == GameConstants.OUTCOME_TARGET_ESCAPED) {
            return Rez.Strings.BreakTargetEscaped;
        }
        return Rez.Strings.BreakEscapedAsMouse;
    }

    // Whether `outcome` was a win from the player's perspective - drives the
    // green vs. muted headline colour on the break/summary screens.
    function isWin(outcome as Number) as Boolean {
        return (outcome == GameConstants.OUTCOME_ESCAPED_AS_MOUSE) || (outcome == GameConstants.OUTCOME_CAUGHT_TARGET);
    }
}
