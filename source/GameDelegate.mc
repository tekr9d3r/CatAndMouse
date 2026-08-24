import Toybox.Lang;
import Toybox.WatchUi;

class GameDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        var controller = getApp().gameController;
        if (controller.state == GameConstants.STATE_HOME) {
            controller.homeConfirm();
        } else if (controller.state == GameConstants.STATE_INSTRUCTIONS) {
            controller.instructionsAdvance();
        } else if (controller.state == GameConstants.STATE_SETUP) {
            controller.setupConfirm();
        } else if (controller.state == GameConstants.STATE_BREAK) {
            controller.continueFromBreak();
        } else {
            controller.togglePause();
        }
        return true;
    }

    function onNextPage() as Boolean {
        var controller = getApp().gameController;
        if (controller.state == GameConstants.STATE_HOME) {
            controller.homeMove(1);
            return true;
        } else if (controller.state == GameConstants.STATE_INSTRUCTIONS) {
            controller.instructionsMove(1);
            return true;
        } else if (controller.state == GameConstants.STATE_SETUP) {
            controller.setupMoveNext();
            return true;
        }
        return false;
    }

    function onPreviousPage() as Boolean {
        var controller = getApp().gameController;
        if (controller.state == GameConstants.STATE_HOME) {
            controller.homeMove(-1);
            return true;
        } else if (controller.state == GameConstants.STATE_INSTRUCTIONS) {
            controller.instructionsMove(-1);
            return true;
        } else if (controller.state == GameConstants.STATE_SETUP) {
            controller.setupMovePrevious();
            return true;
        }
        return false;
    }

    // Physical MENU button - opens the in-activity menu (Resume / Change
    // Intensity / End Activity / Delete Activity), the only way a session
    // ends now that there's no automatic time limit. Native Menu2/
    // Confirmation, deliberately not custom-styled - this is a functional
    // utility menu, not a gameplay screen.
    function onMenu() as Boolean {
        return openActivityMenu();
    }

    // BACK on the root view's default behavior is to quit the app outright -
    // which, mid-activity, silently abandons the FIT recording with no
    // chance to save or even notice. Route it to the same in-activity menu
    // as MENU instead, so leaving is always a deliberate choice (End/Delete)
    // rather than an accidental button press. Only the un-guarded states
    // (setup, summary) fall through to the default quit-the-app behavior,
    // since there's no in-progress activity to lose there.
    function onBack() as Boolean {
        return openActivityMenu();
    }

    private function openActivityMenu() as Boolean {
        var controller = getApp().gameController;
        var s = controller.state;
        // Pre-activity and post-activity states have no recording to
        // protect. BACK from instructions steps home rather than quitting;
        // from setup it also returns to the home menu; from home it falls
        // through to the default quit-the-app behavior.
        if (s == GameConstants.STATE_INSTRUCTIONS || s == GameConstants.STATE_SETUP) {
            controller.returnHome();
            return true;
        }
        if (s == GameConstants.STATE_HOME || s == GameConstants.STATE_SUMMARY) {
            return false;
        }
        controller.ensurePausedForMenu();
        WatchUi.pushView(new Rez.Menus.ActivityMenu(), new ActivityMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}
