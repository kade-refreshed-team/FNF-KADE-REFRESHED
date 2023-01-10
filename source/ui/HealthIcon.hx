package ui;

import openfl.Assets;
import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public var char:String;
	public var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		this.isPlayer = isPlayer;
		changeIcon(char);
		antialiasing = true;
		scrollFactor.set();
	}

	public function changeIcon(char:String)
	{
		var dashIndex = char.indexOf("-");
		var noDash:String = char.substring(0, (dashIndex > -1) ? dashIndex : char.length);

		if (char != this.char)
		{
			var assetIndex = [
				Assets.exists(Paths.image('game-side/icons/icon-$char')),
				Assets.exists(Paths.image('game-side/icons/icon-$noDash')),
				true
			].indexOf(true);
			var paths = [
				'game-side/icons/icon-$char',
				'game-side/icons/icon-$noDash',
				'game-side/icons/icon-face'
			];
			loadGraphic(Paths.image(paths[assetIndex]), true, 150, 150);

			animation.add(char, [0, 1], 0, false, isPlayer);
		}
		animation.play(char);
		this.char = char;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
