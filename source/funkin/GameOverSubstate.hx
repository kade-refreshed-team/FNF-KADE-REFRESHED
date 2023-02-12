package funkin;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import funkin.PlayState;
import menus.StoryMenuState;
import menus.FreeplayState;
import base.Conductor;

class GameOverSubstate extends base.MusicBeatSubstate
{
	var bg:FlxSprite;
	var bf:Character;
	var camFollow:FlxObject;

	var stageSuffix:String = "";
	var deadMus:String;
	var deadEnd:String;

	public function new(x:Float, y:Float, deadChr:String, deadSFX:String, deadMus:String, deadEnd:String) {
		super();

		this.deadMus = deadMus;
		this.deadEnd = deadEnd;
		this.bf = PlayState.instance.boyfriend;

		Conductor.songPosition = 0;

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		var zoom = Math.min(FlxG.camera.zoom, 1);
		bg.scale.scale(1 / zoom);
		bg.scrollFactor.set();
		bg.alpha = 0;
		add(bg);

		bf.loadCharacter(deadChr);
		PlayState.instance.remove(bf, true);
		add(bf);

		var bfMidpoint = bf.getMidpoint();
		camFollow = new FlxObject(
			bfMidpoint.x - 100 + PlayState.instance.camOffsets.bfCamX + bf.data.offsets.camX,
			bfMidpoint.y - 100 + PlayState.instance.camOffsets.bfCamY + bf.data.offsets.camY,
			1,
			1
		);
		add(camFollow);
		FlxG.camera.follow(camFollow, LOCKON, 0.04 * (30 / (cast(openfl.Lib.current.getChildAt(0), base.Main)).getFPS()));
		bfMidpoint.put();

		PlayState.instance.gf.playAnim("sad");
		PlayState.instance.dad.playAnim("victory");
		bf.playAnim('firstDeath');
		FlxG.sound.play(Paths.sound(deadSFX));
		Conductor.changeBPM(100);

		FlxTween.tween(bg, {alpha: 0.7}, 1);
		FlxTween.tween(PlayState.instance.camHUD, {alpha: 0}, 1);
		FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {ease: FlxEase.circOut});
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		@:privateAccess {
			PlayState.instance.dad.updateAnimation(elapsed);
			PlayState.instance.gf.updateAnimation(elapsed);
		}

		if (controls.ACCEPT)
			endBullshit();
		
		if (isEnding) return;

		if (controls.BACK) {
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();

			if (PlayState.isStoryMode)
				FlxG.switchState(new StoryMenuState());
			else
				FlxG.switchState(new FreeplayState());
			PlayState.loadRep = false;

			isEnding = true;
			return;
		}

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;

		//You cant force a looped anim sooo...
		if (PlayState.instance.gf.animation.curAnim != null && PlayState.instance.gf.animation.curAnim.name == "sad" && PlayState.instance.gf.animation.curAnim.finished)
			PlayState.instance.gf.playAnim("sad");

		if (bf.animation.curAnim != null && bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished) {
			FlxG.sound.playMusic(Paths.music(deadMus));
			bf.playAnim('deathLoop');
		}
	}

	var isEnding:Bool = false;

	function endBullshit():Void {
		if (isEnding) return;

		isEnding = true;
		bf.playAnim('deathConfirm', true);
		PlayState.instance.gf.playAnim("cheer");
		FlxG.sound.music.stop();
		FlxG.sound.play(Paths.music(deadEnd));
		new FlxTimer().start(0.7, function(tmr:FlxTimer) {
			FlxG.camera.fade(FlxColor.BLACK, 2, false, function() {
				openSubState(new funkin.PreloadingSubState());
			});
		});
	}
}
