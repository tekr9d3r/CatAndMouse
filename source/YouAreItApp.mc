import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class YouAreItApp extends Application.AppBase {

    var gameController as GameController;
    var pendingLengthMinutes as Number;

    function initialize() {
        AppBase.initialize();
        gameController = new GameController();
        pendingLengthMinutes = 10;
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [ new GameView(), new GameDelegate() ];
    }

}

function getApp() as YouAreItApp {
    return Application.getApp() as YouAreItApp;
}
