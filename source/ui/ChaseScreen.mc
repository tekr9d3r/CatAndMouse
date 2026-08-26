import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Shared by STATE_CHASED (player is the mouse) and STATE_CHASING (player is
// the cat). Rebuilt against turn 5 of the design handoff ("revised chase ·
// both roles"):
//   - both animals face the same way and run left-to-right: chaser (cat)
//     behind on the left, prey (mouse) ahead on the right, in both roles;
//   - the screen edge is a round-time progress ring that drains as the
//     round runs out - the rim belongs to time now, so danger is carried
//     entirely by the background flood and the blinking RUN!/GET 'EM! label;
//   - each animal carries its own pace inside its body;
//   - metres are the biggest thing on screen; no score during a round.
// Stage thresholds are shared with Feedback (GameConstants.dangerStage) so
// the screen and the haptics never disagree.
module ChaseScreen {

    // Character body radii per danger stage, from the turn 5 mockup box
    // sizes (half of each stage's CSS width): cat 80->84->90, mouse 64->66.
    const CAT_RADIUS = [40.0, 42.0, 45.0];
    const MOUSE_RADIUS = [32.0, 33.0, 33.0];

    // Edge-to-edge separation between the two characters at max/min gap
    // (turn 5 shows 116px at the far snapshot, 14px right before a catch).
    const PAIR_GAP_MAX = 116.0;
    const PAIR_GAP_MIN = 14.0;

    var _catCharacter as Character?;
    var _mouseCharacter as Character?;

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController, phase as Float) as Void {
        var chase = controller.chase() as ChaseModel;
        var isChased = (controller.state == GameConstants.STATE_CHASED);
        var dangerFrac = GameConstants.dangerFraction(chase.gap);
        var stage = GameConstants.dangerStage(dangerFrac);

        var bg = isChased ? bgForMouse(stage) : bgForCat(stage);

        // The colour flood is the whole point: fill edge-to-edge before
        // anything else draws, on top of GameView's default black clear.
        dc.setColor(bg, bg);
        dc.fillRectangle(0, 0, metrics.width, metrics.height);

        drawTimeRing(dc, metrics, chase, isChased, stage);
        drawDangerShout(dc, metrics, isChased, stage, phase);
        drawCharacters(dc, metrics, controller, chase, isChased, stage, dangerFrac, phase, bg);
        drawGapNumber(dc, metrics, chase.gap, stage, isChased ? tintForMouse(stage) : tintForCat(stage));

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // --- time ring: fills the screen edge, drains clockwise from the top
    // as round time runs out (turn 5: "the rim is time left") ---

    function drawTimeRing(dc as Graphics.Dc, metrics as ScreenMetrics, chase as ChaseModel, isChased as Boolean, stage as Number) as Void {
        var remaining = 1.0 - (chase.roundElapsed / GameConstants.ROUND_MAX_SECONDS);
        Hud.drawTimeRing(dc, metrics, remaining, 18, fillColorFor(stage), trackColorFor(isChased, stage));
    }

    function fillColorFor(stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return Palette.RING_FILL_DANGER;
        } else if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            return Palette.RING_FILL_CLOSING;
        }
        return Palette.RING_FILL_REST;
    }

    // Track darkens toward the flood colour under danger so the drained
    // ring never disappears against the ground (5c uses #5c0808 on red).
    function trackColorFor(isChased as Boolean, stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return isChased ? Palette.RING_TRACK_RED : Palette.RING_TRACK_ORANGE;
        }
        return Palette.RING_TRACK;
    }

    // --- danger shout: the only label left on the chase screen. Blinks in
    // the top safe area during the final stage (5c note: "RUN! blinking") ---

    function drawDangerShout(dc as Graphics.Dc, metrics as ScreenMetrics, isChased as Boolean, stage as Number, phase as Float) as Void {
        if (stage != GameConstants.DANGER_STAGE_DANGER) {
            return;
        }
        var flashOn = (((phase / 0.6).toNumber()) % 2) == 0;
        if (!flashOn) {
            return;
        }
        var shoutId = isChased ? Rez.Strings.ChaseRun : Rez.Strings.ChasePounce;
        dc.setColor(Palette.WARM_WHITE, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, metrics.px(44), 2, WatchUi.loadResource(shoutId) as String);
    }

    // --- characters: chaser behind on the left, prey ahead on the right,
    // both facing/running right (turn 5 - "no more staring contest") ---

    function drawCharacters(dc as Graphics.Dc, metrics as ScreenMetrics, controller as GameController, chase as ChaseModel, isChased as Boolean, stage as Number, dangerFrac as Float, phase as Float, bg as Graphics.ColorType) as Void {
        var gapFrac = chase.gap / GameConstants.INITIAL_GAP_METERS;
        if (gapFrac > 1.0) {
            gapFrac = 1.0;
        } else if (gapFrac < 0.0) {
            gapFrac = 0.0;
        }
        var sep = metrics.px(PAIR_GAP_MIN + (PAIR_GAP_MAX - PAIR_GAP_MIN) * gapFrac);

        var catRadius = metrics.px(CAT_RADIUS[stage]);
        var mouseRadius = metrics.px(MOUSE_RADIUS[stage]);

        // Center the pair (body edge to body edge) around the screen center,
        // feet on a shared baseline inside the central safe square.
        var totalW = catRadius * 2 + sep + mouseRadius * 2;
        var catX = metrics.centerX - totalW / 2 + catRadius;
        var mouseX = catX + catRadius + sep + mouseRadius;
        var feetY = metrics.isRound ? metrics.px(190) : layoutMidY(metrics);
        var catY = feetY - catRadius;
        var mouseY = feetY - mouseRadius;

        // Pace inside each body: the virtual animal shows the simulated
        // speed, the player's animal shows the live GPS pace.
        var playerPace = Utils.speedToPaceString(controller.currentPlayerSpeed());
        var characterPace = Utils.speedToPaceString(chase.characterSpeed);
        var catPace = isChased ? characterPace : playerPace;
        var mousePace = isChased ? playerPace : characterPace;

        var cat = characterFor(GameConstants.ROLE_CAT);
        var mouse = characterFor(GameConstants.ROLE_MOUSE);

        cat.paceText = catPace;
        mouse.paceText = mousePace;
        cat.draw(dc, catX, catY, catRadius, 1, phase, dangerFrac, catColorStage(isChased, stage), bg);
        mouse.draw(dc, mouseX, mouseY, mouseRadius, 1, phase, dangerFrac, mouseColorStage(isChased, stage), bg);

        // Drawn last so it sits over both animals. STATE_CHASED means the
        // player is the mouse being hunted; otherwise they're the cat.
        if (isChased) {
            drawYouTag(dc, metrics, mouseX, mouseY, mouseRadius);
        } else {
            drawYouTag(dc, metrics, catX, catY, catRadius);
        }
    }

    // Turn 12a: a green YOU tag with a pointer, pinned above the player's
    // own animal, so which one you are never has to be worked out at a
    // glance mid-run. Ratios come off the mockup's 66px mouse: the pointer
    // tucks into the gap between the ears, apex 1.27 radii above the body
    // centre, with the pill sitting directly on top of it.
    function drawYouTag(dc as Graphics.Dc, metrics as ScreenMetrics, x as Number, y as Number, s as Number) as Void {
        var text = WatchUi.loadResource(Rez.Strings.YouTag) as String;
        var font = Graphics.FONT_XTINY;
        var pillW = dc.getTextWidthInPixels(text, font) + maxOf((s * 0.27).toNumber(), 2) * 2;
        var pillH = dc.getFontHeight(font) + maxOf((s * 0.09).toNumber(), 1) * 2;

        var pointerH = maxOf((s * 0.21).toNumber(), 3);
        var apexY = y - (s * 1.27).toNumber();
        var pillBottom = apexY - pointerH;
        var pillTop = pillBottom - pillH;

        // A danger-stage cat on a 176px screen is big enough to push the tag
        // off the top, so keep it inside the bezel and let the pointer run
        // shorter instead of drawing the pill under the rim.
        var minTop = metrics.px(24);
        if (pillTop < minTop) {
            var shift = minTop - pillTop;
            pillTop += shift;
            pillBottom += shift;
        }

        dc.setColor(Palette.GREEN, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x - pillW / 2, pillTop, pillW, pillH, pillH / 2);
        if (apexY > pillBottom) {
            dc.fillPolygon([
                [x - pointerH, pillBottom],
                [x + pointerH, pillBottom],
                [x, apexY]
            ]);
        }

        dc.setColor(Palette.INK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, pillTop + pillH / 2, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    function maxOf(a as Number, b as Number) as Number {
        return (a > b) ? a : b;
    }

    function layoutMidY(metrics as ScreenMetrics) as Number {
        return (metrics.height * 0.34).toNumber();
    }

    // The player's own cat stays its neutral brand orange through REST and
    // CLOSING (5d), only turning into the black/amber silhouette at the
    // pounce stage. An opposing cat reads as a threat as soon as the chase
    // stops being safe (5b/5c).
    function catColorStage(isChased as Boolean, realStage as Number) as Number {
        if (isChased) {
            return realStage;
        }
        return (realStage == GameConstants.DANGER_STAGE_DANGER) ? GameConstants.DANGER_STAGE_DANGER : GameConstants.DANGER_STAGE_REST;
    }

    // The mouse warms toward white only under a flood it is part of: every
    // stage in its own role, but as prey in the cat role it stays cream
    // until the pounce flood (5d shows cream at closing).
    function mouseColorStage(isChased as Boolean, realStage as Number) as Number {
        if (isChased) {
            return realStage;
        }
        return (realStage == GameConstants.DANGER_STAGE_DANGER) ? GameConstants.DANGER_STAGE_DANGER : GameConstants.DANGER_STAGE_REST;
    }

    function characterFor(role as Number) as Character {
        if (role == GameConstants.ROLE_CAT) {
            if (_catCharacter == null) {
                _catCharacter = new Character(GameConstants.ROLE_CAT);
            }
            return _catCharacter as Character;
        }
        if (_mouseCharacter == null) {
            _mouseCharacter = new Character(GameConstants.ROLE_MOUSE);
        }
        return _mouseCharacter as Character;
    }

    // --- gap number: the biggest thing on screen (156px of 416 in the
    // mockups, top y198) ---

    function drawGapNumber(dc as Graphics.Dc, metrics as ScreenMetrics, gap as Float, stage as Number, tint as Graphics.ColorType) as Void {
        var numText = gap.format("%.0f");
        var unitText = "m";
        var unitFont = metrics.fontFor(2);
        var unitW = dc.getTextWidthInPixels(unitText, unitFont);
        var unitH = dc.getFontHeight(unitFont);

        // Pick the largest number font that respects the design's height
        // band and (for 3+ digit gaps - the player can outrun the cat) the
        // screen width.
        var font = numberFontFor(metrics);
        var maxW = (metrics.width * 0.72).toNumber();
        var maxH = metrics.px(175);
        while ((dc.getFontHeight(font) > maxH || dc.getTextWidthInPixels(numText, font) + unitW > maxW)
                && font != smallerNumberFont(font)) {
            font = smallerNumberFont(font);
        }
        var numW = dc.getTextWidthInPixels(numText, font);
        var numH = dc.getFontHeight(font);

        // Anchor on the mockup number's vertical center (top 198 + 156/2 of
        // 416) so any Garmin number font sits where the design's digits do.
        var y = metrics.isRound
            ? (metrics.px(276) - numH / 2)
            : ((metrics.height * 0.6).toNumber() - numH / 2);
        var startX = metrics.centerX - (numW + unitW) / 2;

        // Mockups: cream at rest, warm white once the screen floods.
        var numColor = (stage == GameConstants.DANGER_STAGE_REST) ? Palette.CREAM : Palette.WARM_WHITE;
        dc.setColor(numColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, y, font, numText, Graphics.TEXT_JUSTIFY_LEFT);
        // Sit the unit on the digits' baseline like the mockup's inline "m"
        // span - align actual glyph baselines, not font cell bottoms, since
        // Garmin's big number fonts carry a lot of descent padding.
        var unitY = y + (numH - Graphics.getFontDescent(font)) - (unitH - Graphics.getFontDescent(unitFont));
        dc.setColor(tint, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + numW, unitY, unitFont, unitText, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function numberFontFor(metrics as ScreenMetrics) as Graphics.FontType {
        if (metrics.scale >= 0.85) {
            return Graphics.FONT_NUMBER_THAI_HOT;
        } else if (metrics.scale >= 0.55) {
            return Graphics.FONT_NUMBER_HOT;
        }
        return Graphics.FONT_NUMBER_MEDIUM;
    }

    function smallerNumberFont(font as Graphics.FontType) as Graphics.FontType {
        if (font == Graphics.FONT_NUMBER_THAI_HOT) {
            return Graphics.FONT_NUMBER_HOT;
        } else if (font == Graphics.FONT_NUMBER_HOT) {
            return Graphics.FONT_NUMBER_MEDIUM;
        } else if (font == Graphics.FONT_NUMBER_MEDIUM) {
            return Graphics.FONT_NUMBER_MILD;
        }
        return font;
    }

    // --- colour lookups (Palette holds the exact mockup hex values) ---

    function bgForMouse(stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return Palette.MOUSE_BG_DANGER;
        } else if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            return Palette.MOUSE_BG_CLOSING;
        }
        return Palette.MOUSE_BG_REST;
    }

    function bgForCat(stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return Palette.CAT_BG_DANGER;
        } else if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            return Palette.CAT_BG_CLOSING;
        }
        return Palette.CAT_BG_REST;
    }

    function tintForMouse(stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return Palette.MOUSE_ACCENT_DANGER;
        } else if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            return Palette.MOUSE_ACCENT_CLOSING;
        }
        return Palette.MUTED_GREY;
    }

    function tintForCat(stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return Palette.CAT_ACCENT_DANGER;
        } else if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            return Palette.CAT_ACCENT_CLOSING;
        }
        return Palette.MUTED_GREY;
    }
}
