import Toybox.Lang;
import Toybox.WatchUi;

class GameDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        var controller = getApp().gameController;
        if (controller.state == GameConstants.STATE_SETUP) {
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
        if (controller.state == GameConstants.STATE_SETUP) {
            controller.setupMoveNext();
            return true;
        }
        return false;
    }

    function onPreviousPage() as Boolean {
        var controller = getApp().gameController;
        if (controller.state == GameConstants.STATE_SETUP) {
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
        var controller = getApp().gameController;
        var s = controller.state;
        if (s == GameConstants.STATE_SETUP || s == GameConstants.STATE_SUMMARY) {
            return false;
        }
        controller.ensurePausedForMenu();
        WatchUi.pushView(new Rez.Menus.ActivityMenu(), new ActivityMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}
