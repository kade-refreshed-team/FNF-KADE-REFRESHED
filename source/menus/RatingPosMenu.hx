package menus;

import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxSprite;
import flixel.FlxG;

class RatingPosMenu extends base.MusicBeatSubstate {
    var bg:FlxSprite;
    var sick:FlxSprite;
    var info:FlxText;
    var strums:Array<FlxSprite> = [];
    var alpha:Float = 0;

    override public function create() {
        super.create();

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xB0000000);
        bg.alpha = 0;
        add(bg);

        sick = new FlxSprite(FlxG.save.data.ratingX, FlxG.save.data.ratingY, Paths.image("game-side/hitPopups/sick"));
        sick.antialiasing = true;
        sick.scale.scale(0.7);
        sick.updateHitbox();
        add(sick);

        info = new FlxText(0, 600, 1280, "[MOUSE-LEFT] - Move the rating to the mouse's position\n[BACKSPACE/ESC] - Leave Menu\n[R] - Reset rating's position");
        info.setFormat(Paths.font("vcr.ttf"), 32, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
        add(info);

        generateStrums();

        FlxTween.tween(this, {alpha: 1}, 1, {ease: FlxEase.expoInOut});
    }

    function generateStrums() {
        for (i in 0...8) {
            var player = Math.floor(i / 4);
            var direction = (i - 4 * player);
            var babyArrow:FlxSprite = new FlxSprite(100 + (FlxG.width / 2 * player) + (funkin.Note.swagWidth * direction), (FlxG.save.data.downscroll) ? FlxG.height - 165 : 50);
            babyArrow.frames = Paths.getSparrowAtlas('game-side/NOTE_assets');

            babyArrow.antialiasing = true;
            babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

            var anims = ["left", "down", "up", "right"];
            babyArrow.animation.addByPrefix('static', 'arrow${anims[direction].toUpperCase()}');
            babyArrow.animation.addByPrefix('pressed', '${anims[direction]} press', 24, false);
            babyArrow.animation.addByPrefix('confirm', '${anims[direction]} confirm', 24, false);

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			babyArrow.ID = direction;

			babyArrow.animation.play('static');

			add(babyArrow);
            strums.push(babyArrow);

            if (player == 0)
                babyArrow.centerOffsets(); // CPU arrows start out slightly off-center
        }
    }

    var exiting:Bool = false;

    override public function update(elapsed:Float) {
        super.update(elapsed);

        bg.alpha = alpha;
        sick.alpha = alpha;
        for (strum in strums)
            strum.alpha = alpha;
        info.alpha = alpha;

        if (exiting) return;

        if (FlxG.keys.justPressed.R) {
            sick.x = FlxG.width * 0.55 - 125;
            sick.y = FlxG.height * 0.5 - 50;
        }

        if (controls.BACK) {
            exiting = true;
            FlxG.save.data.ratingX = sick.x;
            FlxG.save.data.ratingY = sick.y;
            FlxTween.tween(this, {alpha: 0}, 1, {ease: FlxEase.expoInOut, onComplete: (twn:FlxTween) -> {close();}});
        }

        if (FlxG.mouse.pressed) {
            sick.x = Math.floor((FlxG.mouse.screenX - sick.width * 0.5) / 5) * 5;
            sick.y = Math.floor((FlxG.mouse.screenY - sick.height * 0.5) / 5) * 5;
        }
    }
}