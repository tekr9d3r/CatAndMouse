import Toybox.Graphics;
import Toybox.Math;
import Toybox.Lang;

// Procedural cat/mouse, drawn entirely from Dc primitives so it scales
// losslessly across any resolution/color depth and needs no bitmap assets.
// Anatomy is a direct port of the turn 5/6 mockup characters: a circular
// body, two ears on top (triangles for the cat, circles for the mouse), a
// rounded-bar tail on the side opposite the facing direction, and a profile
// face - the cat gets a single eye toward its facing side, the mouse a pink
// nose on its leading edge. During a chase each animal carries its own pace
// centered inside its body (turn 5: "each animal carries its own pace"), in
// which case the mouse drops its eye so the digits own the face.
class Character {

    var role as Number;

    // The break/summary mockups give the hero character a smile; the chase
    // never does. Callers flip this before draw() where the design shows one.
    var smiling as Boolean;

    // Pace string centered inside the body during a chase (turn 5), or null
    // for screens without one. A property rather than a draw() parameter
    // because Instinct 2's runtime caps methods at 9 arguments.
    var paceText as String?;

    // Turn 11 summary pose: the chase is called off, so the character faces
    // the viewer - two symmetric eyes instead of the profile face, no tail,
    // no nose. Callers pair it with smiling=true per the mockup.
    var truce as Boolean;

    function initialize(role as Number) {
        self.role = role;
        smiling = false;
        paceText = null;
        truce = false;
    }

    // x,y: body center. size: body radius in pixels (baseline-scaled by the
    // caller via ScreenMetrics.px). facing: +1 faces right, -1 left - the
    // tail goes on the opposite side. phase: animation clock in radians;
    // urgency: 0..1 drives the "closing in" size pulse. stage:
    // GameConstants.DANGER_STAGE_* - only REST vs non-REST matters, driving
    // the mockup colour swap (neutral orange cat -> black silhouette with
    // amber accents once it's a threat; cream mouse -> warm white on a
    // flood). groundColor: the screen colour behind the character - the
    // mouse's pace digits are punched through in it.
    function draw(dc as Graphics.Dc, x as Number, y as Number, size as Number, facing as Number, phase as Float, urgency as Float, stage as Number, groundColor as Graphics.ColorType) as Void {
        var u = clamp01(urgency);
        var pulse = 1.0 + 0.10 * u * (0.5 + 0.5 * Math.sin(phase * 3.0));
        var s = (size * pulse).toNumber();
        if (s < 4) {
            s = 4;
        }

        // Mockup motion: the cat creeps (x sway), the mouse scurries (a
        // two-step vertical hop). Truce pairs sway together on one slow
        // gentle bob instead (turn 11) - callers share the same phase.
        if (truce) {
            y += (Math.sin(phase) * s * 0.08).toNumber();
        } else if (role == GameConstants.ROLE_CAT) {
            x += (Math.sin(phase * 1.5) * s * 0.12).toNumber();
        } else {
            var hop = ((phase * 4.0).toNumber() % 2 == 0) ? 0 : (s * 0.1).toNumber();
            y -= hop;
        }

        var resting = (stage == GameConstants.DANGER_STAGE_REST);
        var bodyColor;
        var accentColor;
        var earColor;
        if (role == GameConstants.ROLE_CAT) {
            bodyColor = resting ? Palette.BRAND_ORANGE : Palette.BLACK;
            accentColor = resting ? Palette.INK : Palette.AMBER;
            earColor = bodyColor;
        } else {
            // Mouse ears/tail run a shade darker than the body in every
            // mockup (d8d5cf on cream, ffe9c9 on warm white).
            bodyColor = resting ? Palette.CREAM : Palette.WARM_WHITE;
            accentColor = (groundColor == Palette.BLACK) ? Palette.INK : groundColor;
            earColor = resting ? Palette.OFF_WHITE : 0xffe9c9;
        }

        if (!truce) {
            drawTail(dc, x, y, s, facing, earColor);
        }
        drawEars(dc, x, y, s, earColor);

        dc.setColor(bodyColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, s);

        if (truce) {
            drawTruceEyes(dc, x, y, s, accentColor);
        } else if (role == GameConstants.ROLE_CAT) {
            drawCatEye(dc, x, y, s, facing, accentColor, paceText != null);
        } else {
            drawNose(dc, x, y, s, facing);
            if (paceText == null) {
                drawMouseEye(dc, x, y, s, facing, accentColor);
            }
        }

        if (paceText != null) {
            drawPace(dc, x, y, s, accentColor, paceText as String);
        }
        if (smiling) {
            drawSmile(dc, x, y, s, truce ? 0 : facing, accentColor);
        }
    }

    private function clamp01(v as Float) as Float {
        if (v < 0.0) {
            return 0.0;
        } else if (v > 1.0) {
            return 1.0;
        }
        return v;
    }

    // Rounded horizontal bar on the side opposite the facing direction,
    // sitting just below the body's midline like the mockups.
    private function drawTail(dc as Graphics.Dc, x as Number, y as Number, s as Number, facing as Number, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var tailH = (s * 0.22).toNumber();
        if (tailH < 2) {
            tailH = 2;
        }
        var tailLen = (s * 1.05).toNumber();
        var tailY = y + (s * 0.1).toNumber() - tailH / 2;
        var tailX = (facing > 0) ? (x - s - tailLen + (s * 0.15).toNumber()) : (x + s - (s * 0.15).toNumber());
        dc.fillRoundedRectangle(tailX, tailY, tailLen, tailH, tailH / 2);
    }

    private function drawEars(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (role == GameConstants.ROLE_CAT) {
            // Two triangles, apex up, peaking ~0.5 body-radii above the
            // circle with their base tucked just inside it.
            var earHalf = (s * 0.32).toNumber();
            var apexY = y - (s * 1.5).toNumber();
            var baseY = y - (s * 0.75).toNumber();
            var offset = (s * 0.54).toNumber();
            dc.fillPolygon([
                [x - offset, apexY],
                [x - offset + earHalf, baseY],
                [x - offset - earHalf, baseY]
            ]);
            dc.fillPolygon([
                [x + offset, apexY],
                [x + offset + earHalf, baseY],
                [x + offset - earHalf, baseY]
            ]);
        } else {
            // Two circles half-overlapped by the body top.
            var earR = (s * 0.4).toNumber();
            if (earR < 2) {
                earR = 2;
            }
            var offset = (s * 0.55).toNumber();
            dc.fillCircle(x - offset, y - s, earR);
            dc.fillCircle(x + offset, y - s, earR);
        }
    }

    // Single eye toward the facing side. With pace digits in the body the
    // eye rides high on the leading edge (turn 5); without them it sits
    // mid-face (turn 6 home).
    private function drawCatEye(dc as Graphics.Dc, x as Number, y as Number, s as Number, facing as Number, color as Graphics.ColorType, hasPace as Boolean) as Void {
        var eyeR = (s * 0.12).toNumber();
        if (eyeR < 1) {
            eyeR = 1;
        }
        var ex = x + facing * (s * (hasPace ? 0.6 : 0.45)).toNumber();
        var ey = y - (s * (hasPace ? 0.5 : 0.2)).toNumber();
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(ex, ey, eyeR);
    }

    // Two symmetric front-facing eyes for the turn 11 truce pose.
    private function drawTruceEyes(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Graphics.ColorType) as Void {
        var eyeR = (s * 0.14).toNumber();
        if (eyeR < 1) {
            eyeR = 1;
        }
        var spread = (s * 0.39).toNumber();
        var eyeY = y - (s * 0.1).toNumber();
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - spread, eyeY, eyeR);
        dc.fillCircle(x + spread, eyeY, eyeR);
    }

    private function drawMouseEye(dc as Graphics.Dc, x as Number, y as Number, s as Number, facing as Number, color as Graphics.ColorType) as Void {
        var eyeR = (s * 0.16).toNumber();
        if (eyeR < 1) {
            eyeR = 1;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x + facing * (s * 0.4).toNumber(), y - (s * 0.15).toNumber(), eyeR);
    }

    // Pink nose dot on the mouse's leading edge (turn 5/6 mockups).
    private function drawNose(dc as Graphics.Dc, x as Number, y as Number, s as Number, facing as Number) as Void {
        var noseR = (s * 0.16).toNumber();
        if (noseR < 1) {
            noseR = 1;
        }
        dc.setColor(Palette.PINK_NOSE, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x + facing * (s + (noseR / 2)), y + (s * 0.15).toNumber(), noseR);
    }

    // Pace digits centered in the body - drawn only when a font tier fits
    // inside the circle, so tiny screens degrade to a clean plain body
    // rather than clipped digits.
    private function drawPace(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Graphics.ColorType, text as String) as Void {
        var font = null;
        if (dc.getTextWidthInPixels(text, Graphics.FONT_TINY) <= (s * 1.7).toNumber()) {
            font = Graphics.FONT_TINY;
        } else if (dc.getTextWidthInPixels(text, Graphics.FONT_XTINY) <= (s * 1.8).toNumber()) {
            font = Graphics.FONT_XTINY;
        }
        if (font == null) {
            return;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawSmile(dc as Graphics.Dc, x as Number, y as Number, s as Number, facing as Number, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var penW = (s * 0.1).toNumber();
        dc.setPenWidth(penW > 0 ? penW : 1);
        var r = (s * 0.25).toNumber();
        if (r < 2) {
            r = 2;
        }
        // Lower half-arc under the face (bottom of the circle is 270 deg).
        dc.drawArc(x + facing * (s * 0.1).toNumber(), y + (s * 0.2).toNumber(), r, Graphics.ARC_COUNTER_CLOCKWISE, 200, 340);
        dc.setPenWidth(1);
    }
}
