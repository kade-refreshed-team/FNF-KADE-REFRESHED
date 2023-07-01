package debug;

import menus.MainMenuState;
import flixel.addons.ui.FlxUIInputText;
import flixel.ui.FlxButton;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

import funkin.Character;

/**
	*DEBUG MODE
 */
class AnimationDebug extends FlxState
{
	var char:Character;
	var shadow:Character;
	var textAnim:FlxText;
	var offsetList:FlxText;
	var animList:Array<String> = [];
	var curAnim:Int = 0;
	var daAnim:String = 'spooky';
	var camFollow:FlxObject;

	public function new(daAnim:String = 'spooky')
	{
		super();
		this.daAnim = daAnim;
	}

	override function create()
	{
		FlxG.sound.music.stop();

		var gridBG:FlxSprite = FlxGridOverlay.create(25, 25, FlxG.width, FlxG.height, true, 0xFF404344, 0xFF303334);
		gridBG.scrollFactor.set();
		add(gridBG);
		
		var bfCharData:funkin.Character.CharJson = haxe.Json.parse(openfl.Assets.getText('assets/data/characters/bf.json'));
		var charData:funkin.Character.CharJson = bfCharData;
		try {
			charData = haxe.Json.parse(openfl.Assets.getText('assets/data/characters/$daAnim.json'));
		} catch(e) {
			lime.app.Application.current.window.alert('Character file "$daAnim" could not be parsed.\n$e\nThe game will instead load BF.', "Character Parsing Fail");
			daAnim = "bf";
			charData = bfCharData;
		}

		var isPlayer = (charData.commonSide == "bf");
		shadow = new Character(0, 0, daAnim, isPlayer);
		shadow.screenCenter();
		shadow.debugMode = true;
		shadow.alpha = 0.5;
		shadow.color = 0x000000;
		add(shadow);

		char = new Character(0, 0, daAnim, isPlayer);
		char.screenCenter();
		char.debugMode = true;
		add(char);

		offsetList = new FlxText(5, 5, 0, "", 15);
		offsetList.scrollFactor.set();
		add(offsetList);

		textAnim = new FlxText(300, 16);
		textAnim.size = 26;
		textAnim.scrollFactor.set();
		add(textAnim);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.camera.follow(camFollow);

		super.create();
	}

	function genBoyOffsets(pushList:Bool = true):Void {
		offsetList.text = "";

		for (anim => offsets in char.animOffsets){
			offsetList.text += '$anim: $offsets\n';

			if (pushList)
				animList.push(anim);
		}
	}

	override function update(elapsed:Float) {
		textAnim.text = char.animation.curAnim.name;

		if (FlxG.keys.justPressed.E)
			FlxG.camera.zoom += 0.25;
		if (FlxG.keys.justPressed.Q)
			FlxG.camera.zoom -= 0.25;

		if (FlxG.keys.justPressed.ESCAPE)
			openSubState(new funkin.PreloadingSubState());

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L) {
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -90;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 90;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -90;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 90;
			else
				camFollow.velocity.x = 0;
		}
		else
		{
			camFollow.velocity.set();
		}

		if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
			curAnim += (FlxG.keys.justPressed.W) ? -1 : 1;

		curAnim = (curAnim + animList.length) % animList.length;

		if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE) {
			char.playAnim(animList[curAnim]);

			genBoyOffsets(false);
		}

		var upP = FlxG.keys.justPressed.UP;
		var rightP = FlxG.keys.justPressed.RIGHT;
		var downP = FlxG.keys.justPressed.DOWN;
		var leftP = FlxG.keys.justPressed.LEFT;

		var holdShift = FlxG.keys.pressed.SHIFT;
		var multiplier = 1;
		if (holdShift)
			multiplier = 10;

		if (upP || rightP || downP || leftP) {
			for (i => pressed in [upP, downP, leftP, rightP]) {
				if (pressed) {
					var mult = 1 - 2 * (i % 2);
					var index = Math.floor(i * 0.5);
					char.animOffsets[animList[curAnim]][index] += 1 * multiplier * mult;
				}
			}

			genBoyOffsets(false);
			char.playAnim(animList[curAnim]);
		}

		super.update(elapsed);
	}
}
