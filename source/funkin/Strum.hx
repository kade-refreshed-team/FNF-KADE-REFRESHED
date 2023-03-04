package funkin;

import funkin.Note;
import settings.PlayerSettings;

class Strum extends flixel.FlxSprite {
    public var direction:Int = 0;
    public var player:Int = 0;

    public var noteStyle:String = "normal";
	public var styleJson:NoteStyleStruct;
	public var styleSection:NoteStyleSection;

    public var holding(get, null):Bool;
    dynamic function get_holding()
        return PlayerSettings.player1.controls.LEFT;

    public var pressed(get, null):Bool;
    dynamic function get_pressed()
        return PlayerSettings.player1.controls.LEFT_P;

    public var released(get, null):Bool;
    dynamic function get_released()
        return PlayerSettings.player1.controls.LEFT_R;

    public function new(plr:Int, dir:Int) {
        direction = dir;
        player = plr;
        super(100 + (flixel.FlxG.width / 2 * player) + (Note.swagWidth * direction), 100);
        loadNoteStyle(funkin.PlayState.SONG.noteStyle);

        @:privateAccess {
            var heldActions = [PlayerSettings.player1.controls._left, PlayerSettings.player1.controls._down, PlayerSettings.player1.controls._up, PlayerSettings.player1.controls._right];
            var pressActions = [PlayerSettings.player1.controls._leftP, PlayerSettings.player1.controls._downP, PlayerSettings.player1.controls._upP, PlayerSettings.player1.controls._rightP];
            var releaseActions = [PlayerSettings.player1.controls._leftR, PlayerSettings.player1.controls._downR, PlayerSettings.player1.controls._upR, PlayerSettings.player1.controls._rightR];
            get_holding = heldActions[direction].check;
            get_pressed = pressActions[direction].check;
            get_released = releaseActions[direction].check;
        }
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