import Toybox.Lang;
import Toybox.System;

module Utils {

    // Whether the watch's own system unit setting (set once in Garmin
    // Connect, same as every other Garmin activity app respects) is
    // statute rather than metric.
    function isStatute() as Boolean {
        return System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE;
    }

    function metersToFeet(meters as Float) as Float {
        return meters * 3.28084;
    }

    function metersToMiles(meters as Float) as Float {
        return meters / 1609.344;
    }

    function formatSeconds(totalSeconds as Float) as String {
        var s = totalSeconds.toNumber();
        if (s < 0) {
            s = 0;
        }
        var m = s / 60;
        var sec = s % 60;
        return m.format("%01d") + ":" + sec.format("%02d");
    }

    // Pace as min:sec per km/mile, matching the device's unit setting. GPS
    // speed near zero would divide toward infinity, so anything below a
    // slow walk reads as "not moving" instead.
    function speedToPaceString(speedMps as Float) as String {
        if (speedMps <= 0.1) {
            return "--:--";
        }
        var unitMeters = isStatute() ? 1609.344 : 1000.0;
        var paceSecPerUnit = unitMeters / speedMps;
        var totalSec = paceSecPerUnit.toNumber();
        var m = totalSec / 60;
        var sec = totalSec % 60;
        return m.format("%01d") + ":" + sec.format("%02d");
    }

}
