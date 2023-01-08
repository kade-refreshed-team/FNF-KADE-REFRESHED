package utils;

import lime.utils.Assets;
import flixel.util.FlxColor;

using StringTools;

class CoolUtil
{
	public static function difficultyString():String
		return utils.Highscore.diffArray[funkin.PlayState.storyDifficulty].toUpperCase();

	public static function coolTextFile(path:String):Array<String>
		return [for (line in Assets.getText(path).trim().split('\n')) line.trim()];

	public static function coolStringFile(path:String):Array<String>
		return [for (line in path.trim().split('\n')) line.trim()];

	public static function numberArray(max:Int, ?min = 0):Array<Int>
		return [for (i in min...max) i];

	public static function stringColor(color:String) {
		if (color.contains(",")) {
			var rgbArray:Array<Int> = [];
			for (colorNum in color.split(','))
				rgbArray.push(Std.parseInt(colorNum.trim()));
			return FlxColor.fromRGB(rgbArray[0], rgbArray[1], rgbArray[2]);
		}
		return (color.startsWith("#") || color.startsWith("0x")) ? FlxColor.fromString(color) : FlxColor.fromString("#" + color);
	}
}
