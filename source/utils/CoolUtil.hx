package utils;

import lime.utils.Assets;

using StringTools;

class CoolUtil
{
	public static var difficultyArray:Array<String> = ['EASY', "NORMAL", "HARD"];

	public static function difficultyString():String
		return difficultyArray[funkin.PlayState.storyDifficulty];

	public static function coolTextFile(path:String):Array<String>
		return [for (line in Assets.getText(path).trim().split('\n')) line.trim()];

	public static function coolStringFile(path:String):Array<String>
		return [for (line in path.trim().split('\n')) line.trim()];

	public static function numberArray(max:Int, ?min = 0):Array<Int>
		return [for (i in min...max) i];
}
