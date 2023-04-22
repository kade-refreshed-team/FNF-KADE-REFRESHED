package funkin;

import haxe.Json;
import openfl.utils.Assets;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var noteStyle:String;
	var stage:String;
	var validScore:Bool;
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = '';
	public var noteStyle:String = '';
	public var stage:String = '';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = Assets.getText(Paths.songFile(jsonInput + ".json", folder)).trim();
		rawJson.substr(0, rawJson.lastIndexOf("}")); //better end scrubbing

		return parseJSONshit(rawJson);
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var parsedJson = Json.parse(rawJson).song;
		for (section in cast (parsedJson.notes, Array<Dynamic>)) {
			if (Reflect.hasField(section, "sectionBeats")) //psych engine lol
				section.lengthInSteps = section.sectionBeats * 4;
			for (sn in cast (section.sectionNotes, Array<Dynamic>)) {
				var note = cast (sn, Array<Dynamic>);
				if (note.length < 4)
					note.push("Default"); // for consistency in the json when saving.
			}
		}

		if (parsedJson.noteStyle == null)
			parsedJson.noteStyle = "normal";

		var swagShit:SwagSong = cast parsedJson;
		swagShit.validScore = true;
		return swagShit;
	}
}