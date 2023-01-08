package funkin;

import openfl.Assets;
import haxe.Json;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

//Char Jsons are handled similarly to how Kade 1.8 handles Char Jsons.
typedef CharJson = {
	var asset:String;
	var iconAsset:String;
	var barColor:String;
	var commonSide:String;
	var offsets:CharOffsets;
	var animations:Array<JsonAnim>;

	var ?scale:Float;
	var ?scaleAffectsOffset:Bool;
	var ?flipX:Bool;
	var ?antialiasing:Bool;
	var ?singLength:Float;
}

typedef JsonAnim = {
	var name:String;
	var prefix:String;
	var offsets:Array<Float>;

	var ?looped:Bool;
	var ?flipX:Bool;
	var ?flipY:Bool;
	var ?frameRate:Int;
	var ?frameIndices:Array<Int>;
}

typedef CharOffsets = {
	var x:Float;
	var y:Float;
	var camX:Float;
	var camY:Float;
}

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Float>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var data:CharJson = {
		asset: "characters/BOYFRIEND",
		iconAsset: "bf",
		barColor: "#31D1B0",
		commonSide: "bf",
		offsets: {x: 0, y: 350, camX: 0, camY: 0},
		animations: [{name: "idle", prefix: "bf idle dance", offsets: [-5, 0]}],
		flipX: true
	};
	public var curCharacter:String = 'bf';
	var leftRightDancer:Bool = false;

	public var holdTimer:Float = 0;
	public var hpcolor:FlxColor;

	public var regX:Float = 770;
	public var regY:Float = 100;
	var settingOffsets:Bool = false;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		super(x, y);
		regX = x;
		regY = y;
		animOffsets = new Map<String, Array<Float>>();
		this.isPlayer = isPlayer;
		loadCharacter(character);
			/*case 'RG':
				// DAD ANIMATION LOADING CODE
				tex = Paths.getSparrowAtlas('game-side/characters/RG', 'shared');
				frames = tex;
				animation.addByPrefix('idle', 'RG idle', 24);
				animation.addByPrefix('singUP', 'RG up', 24);
				animation.addByPrefix('singRIGHT', 'RG right', 24);
				animation.addByPrefix('singDOWN', 'RG down', 24);
				animation.addByPrefix('singLEFT', 'RG left', 24);

				addOffset('idle');
				addOffset("singUP", -6, 54);
				addOffset("singRIGHT", 0, -53);
				addOffset("singLEFT", 186, 20);
				addOffset("singDOWN", 30, -249);

				playAnim('idle');

				scale.set(0.4, 0.4);

				setPosition(-187.6, 32);

				hpcolor = 0xFF990000;*/
	}

	public function loadCharacter(charName:String) {
		animOffsets = [];
		curCharacter = charName;
		try {
			data = Json.parse(Assets.getText('assets/characters/$curCharacter.json'));
		} catch(e) {
			lime.app.Application.current.window.alert('Character file "$curCharacter" could not be parsed.\n$e\nThe game will instead load BF.', "Character Parsing Fail");
			curCharacter = "bf";
			data = Json.parse(Assets.getText('assets/characters/bf.json'));
		}

		if (data.scale == null) data.scale = 1;
		if (data.scaleAffectsOffset == null) data.scaleAffectsOffset = false;
		if (data.flipX == null) data.flipX = false;
		if (data.antialiasing == null) data.antialiasing = true;
		if (data.singLength == null) data.singLength = 4;

		// If you wanna add new spritesheet types, add an fileExists function in this array, and add a case in the switch statement.
		var boolIndex:Int = [
			Assets.exists("assets/images/game-side/" + data.asset + ".txt") // txt exists. loading packer sheet.
		].indexOf(true);
		switch (boolIndex) {
			case 0:
				frames = Paths.getPackerAtlas("game-side/" + data.asset);
			default:
				frames = Paths.getSparrowAtlas("game-side/" + data.asset);
		}
		
		hpcolor = utils.CoolUtil.stringColor(data.barColor);

		for (anim in data.animations) {
			if (anim.looped == null) anim.looped = false;
			if (anim.flipX == null) anim.flipX = false;
			if (anim.flipY == null) anim.flipY = false;
			if (anim.frameRate == null) anim.frameRate = 24;

			if (anim.frameIndices != null && anim.frameIndices.length > 0)
				animation.addByIndices(anim.name, anim.prefix, anim.frameIndices, "", anim.frameRate, anim.looped, anim.flipX, anim.flipY);
			else
				animation.addByPrefix(anim.name, anim.prefix, anim.frameRate, anim.looped, anim.flipX, anim.flipY);

			if (data.scaleAffectsOffset) {
				anim.offsets[0] = anim.offsets[0] / data.scale;
				anim.offsets[1] = anim.offsets[1] / data.scale;
			}

			if (!animation.exists(anim.name))
				trace(curCharacter + ": COULDN'T ADD ANIMATION: " + anim.name);

			animOffsets.set(anim.name, anim.offsets);
		}
		leftRightDancer = (animation.exists("danceLeft") && animation.exists("danceRight"));

		scale.set(data.scale, data.scale);
		updateHitbox();
		flipX = (data.flipX && !isPlayer);
		antialiasing = data.antialiasing;

		if ((data.commonSide == "bf") != isPlayer) {
			if (animation.getByName('singRIGHT') != null) {
				var oldFrames = animation.getByName('singRIGHT').frames;
				animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
				animation.getByName('singLEFT').frames = oldFrames;
				var oldOffsets = animOffsets['singRIGHT'];
				animOffsets['singRIGHT'] = animOffsets['singLEFT'];
				animOffsets['singLEFT'] = oldOffsets;
			}

			if (animation.getByName('singRIGHTmiss') != null) {
				var oldMiss = animation.getByName('singRIGHTmiss').frames;
				animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
				animation.getByName('singLEFTmiss').frames = oldMiss;
				var oldOffsets = animOffsets['singRIGHTmiss'];
				animOffsets['singRIGHTmiss'] = animOffsets['singLEFTmiss'];
				animOffsets['singLEFTmiss'] = oldOffsets;
			}
		}

		playAnim(leftRightDancer ? "danceRight" : "idle");
		danced = false;
		dance();

		x = regX + data.offsets.x;
		y = regY + data.offsets.y;
	}

	override function update(elapsed:Float)
	{
		x = regX + data.offsets.x;
		y = regY + data.offsets.y;

		if (!curCharacter.startsWith('bf'))
		{
			if (animation.curAnim.name.startsWith('sing'))
			{
				holdTimer += elapsed;
			}
			if (holdTimer >= base.Conductor.stepCrochet * data.singLength * 0.001)
			{
				dance();
				holdTimer = 0;
			}
		}

		switch (curCharacter)
		{
			case 'gf':
				if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
					playAnim('danceRight');
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode)
		{
			switch (curCharacter)
			{
				case 'gf':
					if (!animation.curAnim.name.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				case 'gf-christmas':
					if (!animation.curAnim.name.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				case 'gf-car':
					if (!animation.curAnim.name.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}
				case 'gf-pixel':
					if (!animation.curAnim.name.startsWith('hair'))
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight');
						else
							playAnim('danceLeft');
					}

				case 'spooky':
					danced = !danced;

					if (danced)
						playAnim('danceRight');
					else
						playAnim('danceLeft');
				default:
					playAnim('idle');
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (!animOffsets.exists(AnimName) || !animation.exists(AnimName))
			return; //Prevent playing animation if unavailable.

		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);

		if (curCharacter == 'gf')
		{
			if (AnimName == 'singLEFT')
			{
				danced = true;
			}
			else if (AnimName == 'singRIGHT')
			{
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}
}
