import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;

// Shared by STATE_CHASED (player is the mouse) and STATE_CHASING (player is
// the cat) - same structure, mirrored framing. Rebuilt against turn 2 (mouse
// role) and turn 4 (cat role) of the design handoff: danger is communicated
// as a full-screen colour flood plus a rim border, not a meter widget. Three
// stages share their thresholds with Feedback (GameConstants.dangerStage)
// so the screen and the haptics never disagree about what's happening:
//   REST    - black ground, quiet rim, ~70% of a round.
//   CLOSING - amber rim (mouse role also floods amber); the antagonist
//             character grows and, if it's the cat, turns into a black
//             silhouette with glowing eyes.
//   DANGER  - full flood + strobing rim. Mouse role: red, "RUN!". Cat role:
//             orange, "POUNCE!". Red never appears in the cat role.
module ChaseScreen {

    // Character body radii per danger stage, ported from the mockup box
    // sizes (half of each stage's CSS width). The two roles are NOT
    // symmetric in the handoff: the player-mouse stays 66px throughout its
    // own chase (2a-2c) while the threatening cat grows 54->74->104; as the
    // player, the cat starts already big (74) and grows 74->84->104 (4a-4c)
    // while the fleeing mouse only creeps up 50->54->56.
    const OPPONENT_CAT_RADIUS = [27.0, 37.0, 52.0];
    const PLAYER_MOUSE_RADIUS = [33.0, 33.0, 33.0];
    const PLAYER_CAT_RADIUS = [37.0, 42.0, 52.0];
    const OPPONENT_MOUSE_RADIUS = [25.0, 27.0, 28.0];

    // Edge-to-edge separation between the two characters at max/min gap
    // (mockups show 112px at the far snapshot, 14px right before a catch).
    const PAIR_GAP_MAX = 112.0;
    const PAIR_GAP_MIN = 14.0;

    var _catCharacter as Character?;
    var _mouseCharacter as Character?;

    function draw(dc as Graphics.Dc, metrics as ScreenMetrics, layout as HudLayout, controller as GameController, phase as Float) as Void {
        var chase = controller.chase() as ChaseModel;
        var isChased = (controller.state == GameConstants.STATE_CHASED);
        var dangerFrac = GameConstants.dangerFraction(chase.gap);
        var stage = GameConstants.dangerStage(dangerFrac);

        var bg = isChased ? bgForMouse(stage) : bgForCat(stage);
        var rim = isChased ? rimForMouse(stage) : rimForCat(stage);
        var titleColor = isChased ? titleColorForMouse(stage) : titleColorForCat(stage);
        var tint = isChased ? tintForMouse(stage) : tintForCat(stage);

        // The colour flood is the whole point: fill edge-to-edge before
        // anything else draws, on top of GameView's default black clear.
        dc.setColor(bg, bg);
        dc.fillRectangle(0, 0, metrics.width, metrics.height);

        drawRim(dc, metrics, rim, stage, phase);

        dc.setColor(titleColor, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, metrics.px(58), 2, titleFor(isChased, stage, controller.roundIndex()));

        drawCharacters(dc, metrics, chase, isChased, stage, dangerFrac, phase, bg);
        drawGapNumber(dc, metrics, chase.gap, stage, tint);
        drawFooter(dc, metrics, controller, chase, isChased, stage, tint);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
    }

    // --- rim ---

    function drawRim(dc as Graphics.Dc, metrics as ScreenMetrics, color as Graphics.ColorType, stage as Number, phase as Float) as Void {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            // Strobe: roughly a .6s on/off cadence, driven off the shared
            // animation phase rather than a dedicated timer.
            var flashOn = (((phase / 0.6).toNumber()) % 2) == 0;
            if (!flashOn) {
                return;
            }
        }
        var rimWidth = metrics.px(20);
        if (rimWidth < 2) {
            rimWidth = 2;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(rimWidth);
        if (metrics.isRound) {
            var radius = (metrics.minDim - rimWidth) / 2;
            dc.drawCircle(metrics.centerX, metrics.centerY, radius);
        } else {
            dc.drawRoundedRectangle(rimWidth / 2, rimWidth / 2, metrics.width - rimWidth, metrics.height - rimWidth, metrics.px(14));
        }
        dc.setPenWidth(1);
    }

    // --- title ---

    function titleFor(isChased as Boolean, stage as Number, roundIndex as Number) as String {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            var shoutId = isChased ? Rez.Strings.ChaseRun : Rez.Strings.ChasePounce;
            return WatchUi.loadResource(shoutId) as String;
        }
        var labelId = isChased ? Rez.Strings.StateChased : Rez.Strings.StateChasing;
        // Middle dot separator per the mockup titles ("MOUSE! · R3").
        return (WatchUi.loadResource(labelId) as String) + " · R" + roundIndex;
    }

    // --- characters ---

    // Player on the left, the other character on the right - mirroring the
    // mockups' framing for both roles. The pair is centered as a unit (the
    // mockups center the row) and the edge-to-edge separation shrinks
    // linearly with the real gap, so convergence is literal.
    function drawCharacters(dc as Graphics.Dc, metrics as ScreenMetrics, chase as ChaseModel, isChased as Boolean, stage as Number, dangerFrac as Float, phase as Float, bg as Graphics.ColorType) as Void {
        var gapFrac = chase.gap / GameConstants.INITIAL_GAP_METERS;
        if (gapFrac > 1.0) {
            gapFrac = 1.0;
        } else if (gapFrac < 0.0) {
            gapFrac = 0.0;
        }
        var sep = metrics.px(PAIR_GAP_MIN + (PAIR_GAP_MAX - PAIR_GAP_MIN) * gapFrac);

        var playerRole = isChased ? GameConstants.ROLE_MOUSE : GameConstants.ROLE_CAT;
        var otherRole = isChased ? GameConstants.ROLE_CAT : GameConstants.ROLE_MOUSE;

        var playerRadius = metrics.px(radiusBaselineFor(playerRole, true, stage));
        var otherRadius = metrics.px(radiusBaselineFor(otherRole, false, stage));

        // Center the pair (body edge to body edge) around the screen center.
        var totalW = playerRadius * 2 + sep + otherRadius * 2;
        var playerX = metrics.centerX - totalW / 2 + playerRadius;
        var otherX = playerX + playerRadius + sep + otherRadius;

        // Characters stand on a shared baseline (the mockup rows are
        // bottom-aligned, feet at ~y206 of 416).
        var feetY = metrics.isRound ? metrics.px(206) : layoutMidY(metrics);
        var playerY = feetY - playerRadius;
        var otherY = feetY - otherRadius;

        var player = characterFor(playerRole);
        var other = characterFor(otherRole);

        var playerColorStage = colorStageFor(playerRole, true, isChased, stage);
        var otherColorStage = colorStageFor(otherRole, false, isChased, stage);

        // Mockup 2a: at rest the threatening cat doesn't animate - only the
        // player-mouse scurries. Every other stage/role animates both.
        var otherPhase = phase;
        if (isChased && stage == GameConstants.DANGER_STAGE_REST) {
            otherPhase = 0.0;
        }

        // Facing rule from the mockups: the cat faces its prey, the mouse
        // faces away from its hunter. With the player always on the left,
        // that means the whole chase points left in the mouse role and
        // right in the cat role.
        var facing = isChased ? -1 : 1;

        player.draw(dc, playerX, playerY, playerRadius, facing, phase, dangerFrac, playerColorStage, bg);
        other.draw(dc, otherX, otherY, otherRadius, facing, otherPhase, dangerFrac, otherColorStage, bg);
    }

    function layoutMidY(metrics as ScreenMetrics) as Number {
        return (metrics.height * 0.34).toNumber();
    }

    function radiusBaselineFor(role as Number, isPlayer as Boolean, stage as Number) as Float {
        if (role == GameConstants.ROLE_CAT) {
            return isPlayer ? PLAYER_CAT_RADIUS[stage] : OPPONENT_CAT_RADIUS[stage];
        }
        return isPlayer ? PLAYER_MOUSE_RADIUS[stage] : OPPONENT_MOUSE_RADIUS[stage];
    }

    // The player's own cat stays its neutral orange through REST and
    // CLOSING, only turning into the black/amber "pounce" silhouette at the
    // DANGER stage - it's not a threat to itself. An opposing cat (chasing
    // the player-mouse) reads as a threat as soon as it's not at rest.
    function colorStageFor(role as Number, isPlayerCharacter as Boolean, isChased as Boolean, realStage as Number) as Number {
        if (role != GameConstants.ROLE_CAT) {
            return realStage;
        }
        var isPlayerCat = (!isChased) && isPlayerCharacter;
        if (isPlayerCat) {
            return (realStage == GameConstants.DANGER_STAGE_DANGER) ? GameConstants.DANGER_STAGE_DANGER : GameConstants.DANGER_STAGE_REST;
        }
        return realStage;
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

    // --- gap number ---

    function drawGapNumber(dc as Graphics.Dc, metrics as ScreenMetrics, gap as Float, stage as Number, tint as Graphics.ColorType) as Void {
        var numText = gap.format("%.0f");
        var unitText = "m";
        var unitFont = metrics.fontFor(1);
        var unitW = dc.getTextWidthInPixels(unitText, unitFont);
        var unitH = dc.getFontHeight(unitFont);

        // The mockup number is 74px tall in a 416 frame and 2 digits wide;
        // Garmin's big number fonts vary a lot per device, so pick the
        // largest one that respects both the design's height band and (for
        // 3+ digit gaps - the player can outrun the cat) the screen width.
        var font = numberFontFor(metrics);
        var maxW = (metrics.width * 0.62).toNumber();
        var maxH = metrics.px(120);
        while ((dc.getFontHeight(font) > maxH || dc.getTextWidthInPixels(numText, font) + unitW > maxW)
                && font != smallerNumberFont(font)) {
            font = smallerNumberFont(font);
        }
        var numW = dc.getTextWidthInPixels(numText, font);
        var numH = dc.getFontHeight(font);

        // Anchor on the mockup number's vertical center (top 242 + 74/2 of
        // 416) so any Garmin number font sits where the design's digits do.
        var y = metrics.isRound
            ? (metrics.px(279) - numH / 2)
            : ((metrics.height * 0.56).toNumber() - numH / 2);
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
            return Graphics.FONT_NUMBER_HOT;
        } else if (metrics.scale >= 0.55) {
            return Graphics.FONT_NUMBER_MEDIUM;
        }
        return Graphics.FONT_NUMBER_MILD;
    }

    function smallerNumberFont(font as Graphics.FontType) as Graphics.FontType {
        if (font == Graphics.FONT_NUMBER_HOT) {
            return Graphics.FONT_NUMBER_MEDIUM;
        } else if (font == Graphics.FONT_NUMBER_MEDIUM) {
            return Graphics.FONT_NUMBER_MILD;
        }
        return font;
    }

    // --- footer: pace row + score ---

    function drawFooter(dc as Graphics.Dc, metrics as ScreenMetrics, controller as GameController, chase as ChaseModel, isChased as Boolean, stage as Number, tint as Graphics.ColorType) as Void {
        var youLabel = "YOU " + Utils.speedToPaceString(controller.currentPlayerSpeed());
        var themLabelPrefix = isChased ? "CAT " : "MOUSE ";
        var themLabel = themLabelPrefix + Utils.speedToPaceString(chase.characterSpeed);

        var font = metrics.fontFor(1);
        var gap = metrics.px(26);
        var youW = dc.getTextWidthInPixels(youLabel, font);
        var themW = dc.getTextWidthInPixels(themLabel, font);
        var startX = metrics.centerX - (youW + gap + themW) / 2;

        // The mockups anchor the pace row 70px and the score 46px off the
        // bottom edge (CSS bottom offsets), so anchor by text bottom here.
        var paceY = metrics.isRound
            ? (metrics.height - metrics.px(70) - dc.getFontHeight(font))
            : (metrics.height - metrics.px(64));

        // At rest both paces are off-white with the cat's entry picked out
        // in brand orange - YOU when playing the cat, CAT when fleeing it.
        // Flooded stages tint the whole row (2b/2c/4b/4c).
        var restPace = (stage == GameConstants.DANGER_STAGE_REST);
        var paceColor = restPace ? Palette.OFF_WHITE : paceColorFor(isChased, stage);
        var youColor = (restPace && !isChased) ? Palette.BRAND_ORANGE : paceColor;
        var themColor = (restPace && isChased) ? Palette.BRAND_ORANGE : paceColor;

        dc.setColor(youColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX, paceY, font, youLabel, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(themColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + youW + gap, paceY, font, themLabel, Graphics.TEXT_JUSTIFY_LEFT);

        var scoreFont = metrics.fontFor(0);
        var scoreY = metrics.isRound
            ? (metrics.height - metrics.px(46) - dc.getFontHeight(scoreFont))
            : (metrics.height - metrics.px(30));
        dc.setColor(tint, Graphics.COLOR_TRANSPARENT);
        Hud.drawCenteredText(dc, metrics, scoreY, 0, "SCORE " + controller.score());
    }

    function paceColorFor(isChased as Boolean, stage as Number) as Graphics.ColorType {
        if (isChased) {
            return (stage == GameConstants.DANGER_STAGE_DANGER) ? Palette.MOUSE_PACE_DANGER : Palette.MOUSE_PACE_CLOSING;
        }
        return (stage == GameConstants.DANGER_STAGE_DANGER) ? Palette.CAT_PACE_DANGER : Palette.CAT_PACE_CLOSING;
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

    function rimForMouse(stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return Palette.MOUSE_RIM_DANGER;
        } else if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            return Palette.MOUSE_RIM_CLOSING;
        }
        return Palette.MOUSE_RIM_REST;
    }

    function titleColorForMouse(stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return Palette.MOUSE_TITLE_DANGER;
        } else if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            return Palette.MOUSE_TITLE_CLOSING;
        }
        return Palette.MOUSE_TITLE_REST;
    }

    function tintForMouse(stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return Palette.MOUSE_ACCENT_DANGER;
        } else if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            return Palette.MOUSE_ACCENT_CLOSING;
        }
        return Palette.MUTED_GREY;
    }

    function bgForCat(stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return Palette.CAT_BG_DANGER;
        } else if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            return Palette.CAT_BG_CLOSING;
        }
        return Palette.CAT_BG_REST;
    }

    function rimForCat(stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return Palette.CAT_RIM_DANGER;
        } else if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            return Palette.CAT_RIM_CLOSING;
        }
        return Palette.CAT_RIM_REST;
    }

    function titleColorForCat(stage as Number) as Graphics.ColorType {
        if (stage == GameConstants.DANGER_STAGE_DANGER) {
            return Palette.CAT_TITLE_DANGER;
        } else if (stage == GameConstants.DANGER_STAGE_CLOSING) {
            return Palette.CAT_TITLE_CLOSING;
        }
        return Palette.CAT_TITLE_REST;
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
