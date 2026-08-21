import Toybox.Position;
import Toybox.WatchUi;
import Toybox.Lang;

// Tracks live GPS fix quality so the setup screens can show it before the
// user starts a session. Location events are enabled once, as early as app
// startup (GameController.initialize()), so a fix has the maximum amount of
// time to acquire while the user is still picking length/intensity - by the
// time they reach warmup, the receiver has typically been warm for a while.
class GpsStatus {

    private var _accuracy as Number;

    function initialize() {
        _accuracy = Position.QUALITY_NOT_AVAILABLE;
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onPosition(info as Position.Info) as Void {
        _accuracy = info.accuracy;
        WatchUi.requestUpdate();
    }

    function accuracy() as Number {
        return _accuracy;
    }
}
