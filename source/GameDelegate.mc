import Toybox.Lang;
import Toybox.WatchUi;

class GameDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() as Boolean {
        var controller = getApp().gameController;
        if (controller.state == GameConstants.STATE_SETUP) {
            WatchUi.pushView(new Rez.Menus.LengthMenu(), new LengthMenuDelegate(), WatchUi.SLIDE_UP);
        } else {
            controller.togglePause();
        }
        return true;
    }
}
