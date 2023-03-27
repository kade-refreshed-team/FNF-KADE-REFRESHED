package funkin;

import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import funkin.Note;

class Strum extends flixel.FlxSprite {
    public var direction:Int = 0;
    public var player:Int = 0;

    public var noteStyle:String = "normal";
	public var styleJson:NoteStyleStruct;
	public var styleSection:NoteStyleSection;

    public var holding:Bool;

    public var keybinds:Array<Int> = [];

    public function new(plr:Int, dir:Int) {
        direction = dir;
        player = plr;
        super(100 + (flixel.FlxG.width / 2 * player) + (Note.swagWidth * direction), 100);
        loadNoteStyle(funkin.PlayState.SONG.noteStyle);

        var keys = [
            [FlxKey.fromString(FlxG.save.data.leftBind), FlxKey.LEFT],
            [FlxKey.fromString(FlxG.save.data.downBind), FlxKey.DOWN],
            [FlxKey.fromString(FlxG.save.data.upBind), FlxKey.UP],
            [FlxKey.fromString(FlxG.save.data.rightBind), FlxKey.RIGHT]
        ];
        keybinds = keys[direction];
    }

    public function loadNoteStyle(style:String) {
		var animToPlay = (animation.curAnim != null) ? animation.curAnim.name : "static";

		noteStyle = style;
		styleJson = Note.getNoteStyle(style);
		styleSection = styleJson.strum;

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

		addAnimFunc("static", styleSection.animSets[0][direction], styleSection.fps);
		addAnimFunc("pressed", styleSection.animSets[1][direction], styleSection.fps, false);
		addAnimFunc("confirm", styleSection.animSets[2][direction], styleSection.fps, false);

		antialiasing = styleSection.antialiasing;
		scale.set(styleSection.scale, styleSection.scale);
		updateHitbox();

		animation.play(animToPlay);
	}
}