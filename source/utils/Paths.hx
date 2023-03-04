package utils;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

#if sys
import sys.FileSystem;
#end

class Paths
{
	//inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var SOUND_EXT = "ogg";

	static var currentLevel:String;

	static public function setCurrentLevel(name:String) {
		currentLevel = name.toLowerCase();
	}

	static function getPath(file:String, type:AssetType, library:Null<String>){
		return 'assets/$file';
	}

	static public function getLibraryPath(file:String, library = "preload") {
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String) {
		return '$library:assets/$library/$file';
	}

	inline static function getPreloadPath(file:String){
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String) {
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String) {
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String) {
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String) {
		return getPath('data/$key.json', TEXT, library);
	}

	static public function sound(key:String, ?library:String) {
		return getPath('sounds/$key.$SOUND_EXT', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String) {
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String) {
		return getPath('music/$key.$SOUND_EXT', MUSIC, library);
	}

	inline static public function songFile(file:String, songName:String) {
		var songLowercase = StringTools.replace(songName, " ", "-").toLowerCase();
		switch (songLowercase) {
			case 'dad-battle': songLowercase = 'dadbattle';
			case 'philly-nice': songLowercase = 'philly';
		}
		return 'assets/songs/$songLowercase/$file';
	}

	inline static public function voices(song:String) {
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();
			switch (songLowercase) {
				case 'dad-battle': songLowercase = 'dadbattle';
				case 'philly-nice': songLowercase = 'philly';
			}
		return 'assets/songs/${songLowercase}/Voices.$SOUND_EXT';
	}

	inline static public function inst(song:String) {
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase();
			switch (songLowercase) {
				case 'dad-battle': songLowercase = 'dadbattle';
				case 'philly-nice': songLowercase = 'philly';
			}
		return 'assets/songs/${songLowercase}/Inst.$SOUND_EXT';
	}

	inline static public function image(key:String, ?library:String) {
		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function font(key:String) {
		return 'assets/fonts/$key';
	}

	inline static public function getSparrowAtlas(key:String, ?library:String) {
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
	}

	inline static public function getPackerAtlas(key:String, ?library:String) {
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
	}

	#if sys
	public static function folderContents(path:String) {
		var content = [];
		@:privateAccess for (dir in ["./assets"].concat(polymod.Polymod.prevParams.dirs)) {
            if (FileSystem.exists(FileSystem.absolutePath('$dir/$path')) && FileSystem.isDirectory(FileSystem.absolutePath('$dir/$path')))
               content = content.concat(FileSystem.readDirectory('$dir/$path'));
        }
		return content;
	}
	#end
}
