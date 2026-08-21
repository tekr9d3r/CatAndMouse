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
}
