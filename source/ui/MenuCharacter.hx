package ui;

import flixel.FlxSprite;

typedef CharacterSetting = {
	var asset:String;
	var prefix:String;
	var x:Int;
	var y:Int;
	var scale:Float;
	var flipped:Bool;
}

class MenuCharacter extends FlxSprite
{
	public static var settings:Map<String, CharacterSetting> = [
		'bf' => {asset: "boyfriend", prefix: "BF idle dance white", x: 0, y: -20, scale: 1, flipped: true},
	];

	public var curAsset:String = "a";
	public var curChar:String = "bf";
	private var flipped:Bool = false;

	public static function reparseSettings() {
		settings = [];
		for (line in utils.CoolUtil.coolTextFile(Paths.txt("storymenu/weekCharList"))) {
			var daVars:Array<String> = line.split(" | ");
			settings.set(daVars[0], {
				asset: daVars[1],
				prefix: daVars[2],
				x: Std.parseInt(daVars[3]),
				y: Std.parseInt(daVars[4]),
				scale: Std.parseFloat(daVars[5]),
				flipped: (daVars[6] == "true")
			});
		}
	}

	public function new(x:Int, y:Int, scale:Float, flipped:Bool)
	{
		super(x, y);
		this.flipped = flipped;

		antialiasing = true;

		setGraphicSize(Std.int(width * scale));
		updateHitbox();
	}

	public function setCharacter(character:String):Void
	{
		curChar = character;
		if (!settings.exists(character)) {
			visible = false;
			return;
		}
		visible = true;

		var setting:CharacterSetting = settings[character];
		if (curAsset != setting.asset) {
			curAsset = setting.asset;
			frames = Paths.getSparrowAtlas('menu-side/storymenu/characters/$curAsset');
			animation.addByPrefix('anim', setting.prefix, 24, (curChar.substr(0, 8) != "CONFIRM_"));
		}

		animation.play('anim');

		offset.set(setting.x, setting.y);
		setGraphicSize(Std.int(width * setting.scale));
		flipX = setting.flipped != flipped;
	}
}
