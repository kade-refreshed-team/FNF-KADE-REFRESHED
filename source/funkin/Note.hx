package funkin;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
#if polymod
import polymod.format.ParseRules.TargetSignatureElement;
#end
import funkin.PlayState;
import base.Conductor;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var hitByBot:Bool = false;
	public var prevNote:Note;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	public var noteScore:Float = 1;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public var rating:String = "shit";

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false)
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

		var daStage:String = PlayState.curStage;

		var noteTypeCheck:String = PlayState.SONG.noteStyle;

		if (PlayState.SONG.noteStyle == null && PlayState.storyWeek == 6)
			noteTypeCheck = 'pixel';

		switch (noteTypeCheck) {
			case 'pixel':
				loadGraphic(Paths.image('game-side/pixelUI/arrows-pixels','week6'), true, 17, 17);

				animation.add("scroll", [noteData + 4]);

				if (isSustainNote) {
					loadGraphic(Paths.image('game-side/pixelUI/arrowEnds','week6'), true, 7, 6);

					animation.add("hold", [noteData]);
					animation.add("tail", [noteData + 4]);
				}

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();
			default:
				frames = Paths.getSparrowAtlas('game-side/NOTE_assets');

				var noteColors = ["purple", "blue", "green", "red"];
				animation.addByPrefix("scroll", noteColors[noteData] + "0");
				animation.addByPrefix("hold", noteColors[noteData] + " hold piece");
				noteColors = ['pruple end hold', 'blue hold end', 'green hold end', 'red hold end']; //remake the array because of PRUPLE
				animation.addByPrefix("tail", noteColors[noteData]);

				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
				antialiasing = true;
		}

		x += swagWidth * noteData;
		animation.play('scroll');

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

			if (noteTypeCheck == "pixel")
				x += 30;

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
}