import Toybox.Graphics;
import Toybox.Math;
import Toybox.Lang;

// Procedural cat/mouse, drawn entirely from Dc primitives so it scales
// losslessly across any resolution/color depth and needs no bitmap assets.
// The anatomy is a direct port of the Claude Design mockup characters: a
// single circular body, two ears on top (triangles for the cat, circles for
// the mouse), eyes on the body, and a rounded-bar tail sticking out the side
// opposite the facing direction. No separate head, no legs - the mockups'
// motion is a whole-body creep (cat, x sway) or scurry (mouse, y hop).
class Character {

    var role as Number;

    // The break/summary mockups give the hero character a smile; the chase
    // never does. Callers flip this before draw() where the design shows one.
    var smiling as Boolean;

    function initialize(role as Number) {
        self.role = role;
        smiling = false;
    }

    // x,y: body center. size: body radius in pixels (baseline-scaled by the
    // caller via ScreenMetrics.px). facing: +1 faces right, -1 left - the
    // tail goes on the opposite side. phase: animation clock in radians;
    // urgency: 0..1 drives the "closing in" size pulse. stage:
    // GameConstants.DANGER_STAGE_* - only REST vs non-REST matters, driving
    // the mockup colour swap (neutral orange cat -> black silhouette with
    // amber eyes once it's a threat; cream mouse -> warm white on a flood).
    // groundColor: the screen colour behind the character - the mockups draw
    // the mouse's eye punched through in the ground colour.
    function draw(dc as Graphics.Dc, x as Number, y as Number, size as Number, facing as Number, phase as Float, urgency as Float, stage as Number, groundColor as Graphics.ColorType) as Void {
        var u = clamp01(urgency);
        var pulse = 1.0 + 0.10 * u * (0.5 + 0.5 * Math.sin(phase * 3.0));
        var s = (size * pulse).toNumber();
        if (s < 4) {
            s = 4;
        }

        // Mockup motion: the cat creeps (x sway), the mouse scurries (a
        // two-step vertical hop).
        if (role == GameConstants.ROLE_CAT) {
            x += (Math.sin(phase * 1.5) * s * 0.12).toNumber();
        } else {
            var hop = ((phase * 4.0).toNumber() % 2 == 0) ? 0 : (s * 0.1).toNumber();
            y -= hop;
        }

        var resting = (stage == GameConstants.DANGER_STAGE_REST);
        var bodyColor;
        var eyeColor;
        if (role == GameConstants.ROLE_CAT) {
            bodyColor = resting ? Palette.BRAND_ORANGE : Palette.BLACK;
            eyeColor = resting ? Palette.INK : Palette.AMBER;
        } else {
            bodyColor = resting ? Palette.CREAM : Palette.WARM_WHITE;
            eyeColor = groundColor;
        }

        drawTail(dc, x, y, s, facing, bodyColor);
        drawEars(dc, x, y, s, bodyColor);

        dc.setColor(bodyColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y, s);

        drawEyes(dc, x, y, s, facing, eyeColor);
        if (smiling) {
            drawSmile(dc, x, y, s, facing, eyeColor);
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
        var tailLen = (s * 1.1).toNumber();
        var tailY = y + (s * 0.1).toNumber() - tailH / 2;
        var tailX = (facing > 0) ? (x - s - tailLen + (s * 0.15).toNumber()) : (x + s - (s * 0.15).toNumber());
        dc.fillRoundedRectangle(tailX, tailY, tailLen, tailH, tailH / 2);
    }

    private function drawEars(dc as Graphics.Dc, x as Number, y as Number, s as Number, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (role == GameConstants.ROLE_CAT) {
            // Two triangles, apex up, straddling the top of the body. The
            // mockup ears peak ~0.5 body-radii above the circle with their
            // base tucked just inside it, so most of the triangle stays
            // visible once the body is drawn over it.
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

    private function drawEyes(dc as Graphics.Dc, x as Number, y as Number, s as Number, facing as Number, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (role == GameConstants.ROLE_CAT) {
            // Two eyes shifted slightly toward the facing direction.
            var eyeR = (s * 0.18).toNumber();
            if (eyeR < 1) {
                eyeR = 1;
            }
            var shift = facing * (s * 0.12).toNumber();
            var spread = (s * 0.4).toNumber();
            var eyeY = y - (s * 0.08).toNumber();
            dc.fillCircle(x + shift - spread, eyeY, eyeR);
            dc.fillCircle(x + shift + spread, eyeY, eyeR);
        } else {
            // Single eye on the facing side.
            var eyeR = (s * 0.15).toNumber();
            if (eyeR < 1) {
                eyeR = 1;
            }
            dc.fillCircle(x + facing * (s * 0.45).toNumber(), y - (s * 0.15).toNumber(), eyeR);
        }
    }

    private function drawSmile(dc as Graphics.Dc, x as Number, y as Number, s as Number, facing as Number, color as Graphics.ColorType) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        var penW = (s * 0.1).toNumber();
        dc.setPenWidth(penW > 0 ? penW : 1);
        var r = (s * 0.25).toNumber();
        if (r < 2) {
            r = 2;
        }
        // Lower half-arc under the eyes (bottom of the circle is 270 deg).
        dc.drawArc(x + facing * (s * 0.1).toNumber(), y + (s * 0.2).toNumber(), r, Graphics.ARC_COUNTER_CLOCKWISE, 200, 340);
        dc.setPenWidth(1);
    }
}
