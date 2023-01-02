package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

typedef CharacterSetting = {
	var x:Int;
	var y:Int;
	var scale:Float;
	var flipped:Bool;
}

class MenuCharacter extends FlxSprite
{
	private static var settings:Map<String, CharacterSetting> = [
		'bf' =>     {x: 0, y: -20, scale: 1, flipped: true},
		'gf' =>     {x: 50, y: 80, scale: 1.5, flipped: true},
		'dad' =>    {x: -15, y: 130, scale: 1, flipped: false},
		'spooky' => {x: 20, y: 30, scale: 1, flipped: false},
		'pico' =>   {x: 0, y: 0, scale: 1, flipped: true},
		'mom' =>    {x: -30, y: 140, scale: 0.85, flipped: false},
		'parents-christmas' => {x: 100, y: 130, scale: 1, flipped: false},
		'senpai' => {x: 40, y: -45, scale: 1.4, flipped: false},
	];

	private var flipped:Bool = false;

	public function new(x:Int, y:Int, scale:Float, flipped:Bool)
	{
		super(x, y);
		this.flipped = flipped;

		antialiasing = true;

		frames = Paths.getSparrowAtlas('menu-side/storymenu/campaign_menu_UI_characters');

		animation.addByPrefix('bf', "BF idle dance white", 24);
		animation.addByPrefix('bfConfirm', 'BF HEY!!', 24, false);
		animation.addByPrefix('gf', "GF Dancing Beat WHITE", 24);
		animation.addByPrefix('dad', "Dad idle dance BLACK LINE", 24);
		animation.addByPrefix('spooky', "spooky dance idle BLACK LINES", 24);
		animation.addByPrefix('pico', "Pico Idle Dance", 24);
		animation.addByPrefix('mom', "Mom Idle BLACK LINES", 24);
		animation.addByPrefix('parents-christmas', "Parent Christmas Idle", 24);
		animation.addByPrefix('senpai', "SENPAI idle Black Lines", 24);

		setGraphicSize(Std.int(width * scale));
		updateHitbox();
	}

	public function setCharacter(character:String):Void
	{
		if (character == '')
		{
			visible = false;
			return;
		}
		else
		{
			visible = true;
		}

		animation.play(character);

		var setting:CharacterSetting = settings[character];
		offset.set(setting.x, setting.y);
		setGraphicSize(Std.int(width * setting.scale));
		flipX = setting.flipped != flipped;
	}
}
