package funkin;

import openfl.display.BitmapData;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import funkin.PlayState;
import base.Conductor;

using StringTools;

typedef NoteStyleStruct = {
	var strum:NoteStyleSection;
	var glowOffsets:Array<Array<Float>>;
	var regularArrow:NoteStyleSection;
	var sustain:NoteStyleSection;
}

typedef NoteStyleSection = {
	var asset:String;
	var spritesheetType:String;
	var ?gridX:Int;
	var ?gridY:Int;
	var antialiasing:Bool;
	var scale:Float;
	var fps:Int;

	var animSets:Array<Array<Any>>;
}

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var jsonData:Array<Dynamic> = [];

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var sustainArray:Array<Note> = [];

	public var noteStyle:String = "normal";
	public var styleJson:NoteStyleStruct;
	public var styleSection:NoteStyleSection;
	public var noteType:String = "Default";

	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var hitByBot:Bool = false;

	public var prevNote:Note;

	public var noteScore:Float = 1;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public var rating:String = "shit";

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?noteType:String = "Default")
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		x += 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = Math.round(strumTime);

		if (this.strumTime < 0 )
			this.strumTime = 0;

		this.noteData = noteData;
		this.noteType = noteType;

		loadNoteStyle(noteTypes.get(noteType));

		x += swagWidth * noteData;

		moves = false;

		// trace(prevNote);

		// we make sure its downscroll and its a SUSTAIN NOTE (aka a trail, not a note)
		// and flip it so it doesn't look weird.
		// THIS DOESN'T FUCKING FLIP THE NOTE, CONTRIBUTERS DON'T JUST COMMENT THIS OUT JESUS
		if (FlxG.save.data.downscroll && sustainNote) 
			flipY = true;

		if (isSustainNote && prevNote != null) {
			noteScore * 0.2;
			alpha = 0.6;

			x += width / 2;
			animation.play("tail");
			updateHitbox();
			x -= width / 2;

			if (prevNote.isSustainNote) {
				prevNote.animation.play('hold');

				if(FlxG.save.data.scrollSpeed != 1)
					prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * FlxG.save.data.scrollSpeed;
				else
					prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.SONG.speed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		canBeHit = mustPress && ((isSustainNote && strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * 1.5) && strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
							 || (!isSustainNote && strumTime > Conductor.songPosition - Conductor.safeZoneOffset && strumTime < Conductor.songPosition + Conductor.safeZoneOffset));

		wasGoodHit = wasGoodHit || (!mustPress && strumTime <= Conductor.songPosition);
		tooLate = tooLate || (strumTime < Conductor.songPosition - Conductor.safeZoneOffset * Conductor.timeScale && !wasGoodHit);

		if (tooLate && alpha > 0.3)
			alpha = 0.3;
	}

	//Json parsing can build up so cache.
	static var jsonCache:Map<String, NoteStyleStruct> = [];
	public static function getNoteStyle(style:String):NoteStyleStruct {
		if (jsonCache.exists(style))
			return jsonCache[style];

		try {
			var daJson = haxe.Json.parse(openfl.Assets.getText(Paths.json('noteStyles/$style')));
			jsonCache.set(style, daJson);
			return daJson;
		} catch(e) {
			lime.app.Application.current.window.alert('Note style "$style" could not be parsed.\n$e\nThe game will instead load the default style.', "Note Style Parsing Fail");
			var daJson = haxe.Json.parse(openfl.Assets.getText(Paths.json('noteStyles/normal')));
			jsonCache.set(style, daJson);
			return daJson;
		}
	}

	public function loadNoteStyle(style:String) {
		var animToPlay = (animation.curAnim != null) ? animation.curAnim.name : "scroll";

		noteStyle = style;
		styleJson = getNoteStyle(style);
		styleSection = isSustainNote ? styleJson.sustain : styleJson.regularArrow;

		var addAnimFunc:Dynamic = animation.addByPrefix;
		switch (styleSection.spritesheetType) {
			case "packer":
				frames = Paths.getPackerAtlas(styleSection.asset);
			case "grid":
				loadGraphic(Paths.image(styleSection.asset), true, styleSection.gridX, styleSection.gridY);
				addAnimFunc = animation.add;
			default:
				frames = Paths.getSparrowAtlas(styleSection.asset);
		}

		if (isSustainNote) {
			addAnimFunc("hold", styleSection.animSets[0][noteData], styleSection.fps);
			addAnimFunc("tail", styleSection.animSets[1][noteData], styleSection.fps);
		} else {
			addAnimFunc("scroll", styleSection.animSets[0][noteData], styleSection.fps);
		}

		animation.play(animToPlay);

		antialiasing = styleSection.antialiasing;
		scale.set(styleSection.scale, styleSection.scale);
		if (animToPlay == 'hold') {
			var songSpeed = funkin.PlayStateChangeables.scrollSpeed == 1 ? PlayState.SONG.speed : funkin.PlayStateChangeables.scrollSpeed;
			scale.y *= Conductor.stepCrochet / 100 * 1.5 * songSpeed;
		}
		updateHitbox();
	}

	public static var noteTypes:Map<String, String> = [];
	public static function reparseNoteTypes() {
		noteTypes = [];
		for (line in utils.CoolUtil.coolTextFile(Paths.txt("lists/noteTypeList"))) {
			var daVars = line.split(" | ");
			noteTypes.set(daVars[0], daVars[1].replace("<CURRENT>", PlayState.SONG.noteStyle));
		}
	}
}