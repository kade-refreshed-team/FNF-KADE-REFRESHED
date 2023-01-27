package menus;

import funkin.PlayState;
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxSprite;

using StringTools;

class RgPortraitShader extends flixel.system.FlxAssets.FlxShader
{
	@:glFragmentSource('
		#pragma header

		void main()
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            float twoPixels = (2 / openfl_TextureSize.y);
            color.rgb += 0.125;
            if (mod(openfl_TextureCoordv.y, (twoPixels * 2)) < twoPixels);
                color.rgb -= 0.1;

            gl_FragColor = color;
		}')
	public function new()
	{
		super();
	}
}


class CoolRgStoryMenu extends base.MusicBeatSubstate {
    var bg:FlxSprite;
    var storyBar:FlxSprite;
    var portraits:Array<FlxSprite> = [];
    var weeks:Array<{name:String, songs:Array<String>}> = [];

    public function new() {
        super();

        FlxG.mouse.visible = true;

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        bg.scrollFactor.set();
		bg.alpha = 0;
		add(bg);
        FlxTween.tween(bg, {alpha: 0.6}, 0.25, {ease: FlxEase.quartInOut});

        for (line in utils.CoolUtil.coolTextFile(Paths.txt('storymenu/rgWeeks'))) {
            var daVars = line.split(" | ");
            var daSongs:Array<String> = [for (song in daVars[1].split(",")) song.trim()];
            weeks.push({name: daVars[0], songs: daSongs});
        }

        var shader:RgPortraitShader = new RgPortraitShader();
        var coords:Array<Array<Float>> = [];
        for (line in utils.CoolUtil.coolTextFile(Paths.txt("storymenu/portraitCoords"))) {
            var split = [for (num in line.split(",")) num.trim()];
            coords.push([Std.parseFloat(split[0]), Std.parseFloat(split[1])]);
        }
        for (i in 0...weeks.length) {
            var portrait = new FlxSprite(coords[i][0], coords[i][1], Paths.image('menu-side/storymenu/portrait$i'));
            portrait.scrollFactor.set();
            portrait.visible = false;
            portrait.shader = shader;
            portrait.scale.scale(2);
            portrait.updateHitbox();
            add(portrait);
            portraits.push(portrait);
        }
        storyBar = new FlxSprite(1280, 360);
        storyBar.frames = Paths.getSparrowAtlas('menu-side/storymenu/storybar');
        storyBar.animation.addByIndices("slide", "open ses", [0], "");
        storyBar.animation.addByPrefix("open", 'open ses', 24, false);
        //Reverse anims broke finish callback.
        storyBar.animation.addByIndices("close", 'open ses', [5, 4, 3, 2, 1, 0], "", 24, false);
        storyBar.animation.addByPrefix("flash", 'flash', 24, false);
        storyBar.animation.play("slide");
        storyBar.scrollFactor.set();
        storyBar.scale.scale(2);
        storyBar.updateHitbox();
        add(storyBar);
        storyBar.y -= storyBar.frameHeight;

        FlxTween.tween(storyBar, {x: 1280 - storyBar.frameWidth * 2 + 20}, 0.15, {ease: FlxEase.circOut, onComplete:(twn:FlxTween) -> {
            storyBar.animation.play("open");
            storyBar.animation.finishCallback = (name:String) -> {
                storyBar.animation.play("flash");
                storyBar.animation.finishCallback = null;
                for (port in portraits)
                    port.visible = true;
            }
        }});
    }

    function overlapsSprite(sprite:FlxSprite)
        return (FlxG.mouse.screenX >= sprite.x && FlxG.mouse.screenX <= sprite.x + sprite.width && FlxG.mouse.screenY >= sprite.y && FlxG.mouse.screenY <= sprite.y + sprite.height);

    var selectedWeek:Bool = false;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (selectedWeek) return;

        for (i=>port in portraits) {
            var overlaps = overlapsSprite(port);
            port.color = (overlaps) ? 0xFFFFFFFF : 0xFFD0D0D0;
            if (FlxG.mouse.justPressed && overlaps) {
                for (portrait in portraits)
                    portrait.visible = false;
                selectedWeek = true;
                storyBar.animation.play("close");
                storyBar.animation.finishCallback = (name:String) -> {
                    FlxTween.tween(bg, {alpha: 1}, 0.15);
                    FlxTween.tween(storyBar, {x: 1280}, 0.15, {ease: FlxEase.circOut, onComplete: (twn:FlxTween) -> {
                        FlxG.state.add(bg);
                        utils.Highscore.diffArray = ["hard"];
                        PlayState.storyPlaylist = weeks[i].songs;
                        PlayState.isStoryMode = true;
            
                        PlayState.storyDifficulty = PlayState.sicks = PlayState.goods = PlayState.bads = PlayState.shits = PlayState.campaignMisses = PlayState.campaignScore = 0;
                        PlayState.SONG = funkin.SongClasses.Song.loadFromJson("hard", PlayState.storyPlaylist[0]);
                        PlayState.storyWeek = 7 + i;
                        openSubState(new funkin.PreloadingSubState());
                    }});
                }
                return;
            }
        }

        if (controls.BACK) {
            for (portrait in portraits)
                portrait.visible = false;
            selectedWeek = true;
            storyBar.animation.play("close");
            storyBar.animation.finishCallback = (name:String) -> {
                FlxTween.tween(storyBar, {x: 1280}, 0.15, {ease: FlxEase.circOut, onComplete: (twn:FlxTween) -> {
                    close();
                }});
            }
            return;
        }
    }

    override public function close() {
        super.close();
        FlxG.mouse.visible = false;
    }
}