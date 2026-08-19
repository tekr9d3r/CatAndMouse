import Toybox.ActivityRecording;
import Toybox.Activity;
import Toybox.Lang;

// Thin wrapper so the whole game session - warmup included - records as a
// single continuous Running FIT activity that syncs to Garmin Connect.
class ActivityRecorder {

    private var _session as ActivityRecording.Session?;

    function start() as Void {
        if (_session != null) {
            return;
        }
        _session = ActivityRecording.createSession({
            :name => "You Are It",
            :sport => Activity.SPORT_RUNNING,
            :subSport => Activity.SUB_SPORT_STREET
        });
        _session.start();
    }

    function stop() as Void {
        if (_session == null) {
            return;
        }
        if (_session.isRecording()) {
            _session.stop();
        }
        _session.save();
        _session = null;
    }
}
