package utils;

import openfl.utils.Assets;
import flixel.util.FlxColor;

import funkin.PlayState;

using StringTools;

class CoolUtil
{
	public static function difficultyString():String
		return utils.Highscore.diffArray[funkin.PlayState.storyDifficulty].toUpperCase();

	public static function coolTextFile(path:String):Array<String>
		return [for (line in Assets.getText(path).trim().split('\n')) line.trim()];

	public static function coolStringFile(path:String):Array<String>
		return [for (line in path.trim().split('\n')) line.trim()];

	public static function numberArray(max:Int, ?min:Int = 0):Array<Int>
		return [for (i in min...max) i];

	/**
	 * A helper function to load a color from a string.
	 * Will use RGB if the string contains commas. Otherwise, it will use hex.
	 * @param color 						The string of the color to load.
	 */
	public static function stringColor(color:String) {
		if (color.contains(",")) {
			var rgbArray:Array<Int> = [];
			for (colorNum in color.split(','))
				rgbArray.push(Std.parseInt(colorNum.trim()));
			return FlxColor.fromRGB(rgbArray[0], rgbArray[1], rgbArray[2]);
		}
		return (color.startsWith("#") || color.startsWith("0x")) ? FlxColor.fromString(color) : FlxColor.fromString("#" + color);
	}

	/**
	 * A helper function to load weeks. TBH, this was made bc lua week loading was crashing.
	 * @param songs							The songs of the week.
	 * @param diffs							The avalible difficulties of the week.
	 * @param diffToLoad					The position of the diff to load. Ex: If diffs were `["easy", "normal", "hard"]`, then you would use `0` to load `"easy"`, `1` to load `"normal"`, etc.
	 * @param num							The story week number.
	 */
	public static function loadWeek(songs:Array<String>, diffs:Array<String>, diffToLoad:Int, num:Int) {
		PlayState.sicks = PlayState.goods = PlayState.bads = PlayState.shits = PlayState.campaignMisses = PlayState.campaignScore = 0;
		utils.Highscore.diffArray = diffs;
		PlayState.storyPlaylist = songs;
		PlayState.isStoryMode = true;
		PlayState.storyDifficulty = diffToLoad;
		PlayState.storyWeek = num;
		PlayState.SONG = funkin.SongClasses.Song.loadFromJson(Highscore.diffArray[diffToLoad].toLowerCase(), PlayState.storyPlaylist[0]);
		flixel.FlxG.state.openSubState(new funkin.PreloadingSubState());
	}
}
