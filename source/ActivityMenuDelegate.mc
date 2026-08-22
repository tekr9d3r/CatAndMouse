import Toybox.Lang;
import Toybox.WatchUi;

// In-activity menu (physical MENU button, see GameDelegate.onMenu()) -
// native Menu2/Confirmation, not custom-styled, since this is a functional
// utility menu rather than a gameplay screen. This is now the only way a
// session ends or gets discarded - there's no more automatic time limit.
class ActivityMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var controller = getApp().gameController;

        if (id == :menu_resume) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            controller.resumeFromMenu();
        } else if (id == :menu_change_intensity) {
            WatchUi.pushView(new Rez.Menus.IntensitySubmenu(), new IntensitySubmenuDelegate(), WatchUi.SLIDE_UP);
        } else if (id == :menu_end_activity) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            controller.endActivityAndSave();
        } else if (id == :menu_delete_activity) {
            var dialog = new WatchUi.Confirmation(WatchUi.loadResource(Rez.Strings.DeleteConfirmMessage) as String);
            WatchUi.pushView(dialog, new DeleteConfirmDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }

    // The system doesn't know about our GameController, so BACK dismissing
    // the menu on its own wouldn't resume the paused game - handle it
    // explicitly rather than relying on default behavior.
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        getApp().gameController.resumeFromMenu();
    }
}

class IntensitySubmenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var intensity = GameConstants.INTENSITY_MEDIUM;
        if (id == :intensity_easy) {
            intensity = GameConstants.INTENSITY_EASY;
        } else if (id == :intensity_hard) {
            intensity = GameConstants.INTENSITY_HARD;
        }

        var controller = getApp().gameController;
        controller.changeIntensity(intensity);

        WatchUi.popView(WatchUi.SLIDE_DOWN); // submenu
        WatchUi.popView(WatchUi.SLIDE_DOWN); // main menu
        controller.resumeFromMenu();
    }

    // Back out of the submenu only - the main menu (and the pause) stays,
    // matching "changed my mind about changing intensity" rather than
    // resuming the game outright.
    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class DeleteConfirmDelegate extends WatchUi.ConfirmationDelegate {

    function initialize() {
        ConfirmationDelegate.initialize();
    }

    function onResponse(response as WatchUi.Confirm) as Boolean {
        var controller = getApp().gameController;
        if (response == WatchUi.CONFIRM_YES) {
            WatchUi.popView(WatchUi.SLIDE_DOWN); // confirmation
            WatchUi.popView(WatchUi.SLIDE_DOWN); // main menu
            controller.endActivityAndDiscard();
        } else {
            WatchUi.popView(WatchUi.SLIDE_DOWN); // confirmation only, stay on the main menu
        }
        return true;
    }
}
