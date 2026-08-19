import Toybox.Lang;
import Toybox.WatchUi;

class LengthMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        var minutes = 10;
        if (id == :length_20) {
            minutes = 20;
        } else if (id == :length_30) {
            minutes = 30;
        }
        getApp().pendingLengthMinutes = minutes;
        WatchUi.pushView(new Rez.Menus.IntensityMenu(), new IntensityMenuDelegate(), WatchUi.SLIDE_UP);
    }
}

class IntensityMenuDelegate extends WatchUi.Menu2InputDelegate {

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

        var app = getApp();
        app.gameController.configureAndStart(app.pendingLengthMinutes, intensity);

        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
