import Toybox.Lang;

module Utils {

    function formatSeconds(totalSeconds as Float) as String {
        var s = totalSeconds.toNumber();
        if (s < 0) {
            s = 0;
        }
        var m = s / 60;
        var sec = s % 60;
        return m.format("%01d") + ":" + sec.format("%02d");
    }

    // Pace as min:sec per km. GPS speed near zero would divide toward
    // infinity, so anything below a slow walk reads as "not moving" instead.
    function speedToPaceString(speedMps as Float) as String {
        if (speedMps <= 0.1) {
            return "--:--";
        }
        var paceSecPerKm = 1000.0 / speedMps;
        var totalSec = paceSecPerKm.toNumber();
        var m = totalSec / 60;
        var sec = totalSec % 60;
        return m.format("%01d") + ":" + sec.format("%02d");
    }

}
