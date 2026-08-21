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

    // Round-half-up to the nearest integer. Toybox.Math.round() returns a
    // Float, so callers doing integer scoring math would need a second
    // conversion anyway - this does both steps at once.
    function roundToInt(x as Float) as Number {
        if (x < 0.0) {
            return -((-x + 0.5).toNumber());
        }
        return (x + 0.5).toNumber();
    }

    function clampInt(v as Number, lo as Number, hi as Number) as Number {
        if (v < lo) {
            return lo;
        }
        if (v > hi) {
            return hi;
        }
        return v;
    }

}
