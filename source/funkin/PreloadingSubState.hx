package funkin;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import openfl.Assets;
import flixel.FlxSprite;
import flixel.text.FlxText;
import base.Conductor;
import funkin.PlayState;
import funkin.Character;
import funkin.PlayStateChangeables;

using StringTools;

class PreloadingSubState extends base.MusicBeatSubstate {
    var preloadedAssets:Map<String, Dynamic> = [];

    var preloadingText:FlxText;
	var spinnyYay:FlxSprite;
	var curAsset:String = "Player";

    public function new() {
        super();
    
        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        var bg = new FlxSprite().makeGraphic(1280, 720, 0xA0000000);
        bg.scale.scale(1 / cameras[0].zoom);
        bg.updateHitbox();
        bg.active = false;
        add(bg);
        bg.scrollFactor.set();

        preloadingText = new FlxText(0, 480, 1280, 'Preloading Assets for "${PlayState.SONG.song}"...\nCurrent: Player', 18);
        preloadingText.scale.scale(1 / cameras[0].zoom);
        preloadingText.updateHitbox();
        preloadingText.alignment = "center";
        add(preloadingText);
        preloadingText.scrollFactor.set();

		spinnyYay = new FlxSprite(0, 0, Paths.image("menu-side/KadeRefreshedArrowThingy"));
		spinnyYay.screenCenter();
		spinnyYay.y -= 100;
		spinnyYay.antialiasing = true;
		add(spinnyYay);

        sys.thread.Thread.create(preloadStuff);
    }

	var spinnyElapsed:Float = 0;

	override public function update(elapsed:Float) {
		super.update(elapsed);

		spinnyYay.angle -= elapsed * 50;
		spinnyElapsed = (spinnyElapsed + elapsed) % Math.PI;
		spinnyYay.scale.x = 1 + 0.1 * Math.sin(spinnyElapsed);
		spinnyYay.scale.y = spinnyYay.scale.x;
		preloadingText.text = 'Preloading Assets for "${PlayState.SONG.song}"...\nCurrent: $curAsset';
	}

    function preloadStuff() {
		base.CustomFlxGame.clearBitmapCache();
		Assets.cache.clear();
		#if FLX_SOUND_SYSTEM
		FlxG.sound.destroy();
		#end

		cacheChar("bf", PlayState.SONG.player1, 770, 100, true);
		cast (preloadedAssets["bf"], Character).alpha = 0.0001;
		add(preloadedAssets["bf"]);
        curAsset = "Specator";
        var daGF = PlayState.SONG.gfVersion;
        if (daGF == null) {
            switch (PlayState.storyWeek) {
				case 4:
					daGF = 'gf-car';
				case 5:
					daGF = 'gf-christmas';
				case 6:
					daGF = 'gf-pixel';
				default:
					daGF = "gf";
            }
        }
        PlayState.SONG.gfVersion = daGF;
		cacheChar("gf", daGF, 400, 130, false);
		cast (preloadedAssets["gf"], Character).alpha = 0.0001;
		add(preloadedAssets["gf"]);
        curAsset = "Opponent";
		cacheChar("dad", PlayState.SONG.player2, 100, 100, false);
		cast (preloadedAssets["dad"], Character).alpha = 0.0001;
		add(preloadedAssets["dad"]);

        curAsset = "Song Audio";
        PlayState.songLowercase = StringTools.replace(PlayState.SONG.song, " ", "-").toLowerCase();
		switch (PlayState.songLowercase) {
			case 'dad-battle':
				PlayState.songLowercase = 'dadbattle';
			case 'philly-nice':
				PlayState.songLowercase = 'philly';
		}
        cacheSound("inst", Paths.inst(PlayState.SONG.song));
        if (PlayState.SONG.needsVoices)
			cacheSound("vocals", Paths.voices(PlayState.SONG.song));

        curAsset = "Strumline";
        generateStrums();

        curAsset = "Song Notes";
		Conductor.changeBPM(PlayState.SONG.bpm);
		PlayStateChangeables.scrollSpeed = FlxG.save.data.scrollSpeed;
		Note.reparseNoteTypes();
        preloadedAssets.set("notes", generateNotes(PlayState.SONG.notes));

        curAsset = "Countdown";
        var countdownToPreload = ["countdown/intro3", "countdown/intro2", "countdown/intro1", "countdown/introGo", "ready", "set", "go"];
        if (Assets.exists(Paths.songFile("customCountdown.txt", PlayState.SONG.song)))
            countdownToPreload = utils.CoolUtil.coolTextFile(Paths.songFile("customCountdown.txt", PlayState.SONG.song));
        for (i in 0...4) //Preload Sounds
			cacheSound('countdownSound${3 - i}', Paths.sound(countdownToPreload[i]));
        for (i in 4...7) //Preload Images
			cacheImage('countdownImage${i - 4}', Paths.image("game-side/" + countdownToPreload[i]));

		var daStage:Null<String> = PlayState.SONG.stage;
		if (daStage == null) {
			switch (PlayState.storyWeek) {
				case 2:
					daStage = 'halloween';
				case 3:
					daStage = 'philly';
				case 4:
					daStage = 'limo';
				case 5:
					daStage = (PlayState.songLowercase == 'winter-horrorland') ? 'mallEvil' : "mall";
				case 6:
					daStage = (PlayState.songLowercase == 'thorns') ? 'schoolEvil' : "school";
				default:
					daStage = "stage";
			}
		}
        PlayState.SONG.stage = daStage;
        if (Assets.exists(Paths.txt('stageCache/$daStage'))) {
			curAsset = "Stage Assets";
            preloadFromTxt(Paths.txt('stageCache/$daStage'), "Stage");
		}

        if (Assets.exists(Paths.songFile("extraPreload.txt", PlayState.SONG.song))) {
			curAsset = "Extra Song Assets";
            preloadFromTxt(Paths.songFile("extraPreload.txt", PlayState.SONG.song), "Song");
		}

        PlayStateChangeables.useDownscroll = FlxG.save.data.downscroll;
		PlayStateChangeables.PsychUI = FlxG.save.data.psychui;
		PlayStateChangeables.safeFrames = FlxG.save.data.frames;
		PlayStateChangeables.botPlay = FlxG.save.data.botplay;
		preloadedAssets["strumLineNotes"].forEach((spr:FlxSprite) -> {
			spr.alpha = 1;
		});
		remove(preloadedAssets["strumLineNotes"]);
		for (asset in ["bf", "gf", "dad"]) {
			cast (preloadedAssets[asset], Character).alpha = 1;
			remove(preloadedAssets[asset]);
		}
        FlxG.switchState(new PlayState(preloadedAssets));
    }

    function generateStrums() {
        if (PlayState.SONG.noteStyle == null) {
			switch (PlayState.storyWeek) {
				case 6:
					PlayState.SONG.noteStyle = 'pixel';
                default:
                    PlayState.SONG.noteStyle = 'normal';
			}
		}
        var strumLineNotes = new FlxTypedGroup<funkin.Strum>();
		add(strumLineNotes);
		var playerStrums = [];
		var cpuStrums = [];
        for (i in 0...8) {
            var player = Math.floor(i / 4);
            var direction = (i - 4 * player);

			var babyArrow:funkin.Strum = new funkin.Strum(player, direction);
			babyArrow.alpha = 0.0001;
			babyArrow.scrollFactor.set();
			babyArrow.ID = direction;

			var groups = [cpuStrums, playerStrums];
			groups[player].push(babyArrow);

			babyArrow.animation.play('static');

			strumLineNotes.add(babyArrow);
        }
        for (spr in cpuStrums)
			spr.centerOffsets(); // CPU arrows start out slightly off-center

        preloadedAssets.set("playerStrums", playerStrums);
        preloadedAssets.set("cpuStrums", cpuStrums);
        preloadedAssets.set("strumLineNotes", strumLineNotes);
    }

    function generateNotes(sections:Array<funkin.SongClasses.SwagSection>) {
        var unspawnNotes:Array<Note> = [];
        for (section in sections) {
            for (songNotes in section.sectionNotes) {
				var daStrumTime:Float = songNotes[0] + FlxG.save.data.offset + PlayState.songOffset;
				if (daStrumTime < 0)
					daStrumTime = 0;
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = ((songNotes[1] > 3) != section.mustHitSection);
				var daNoteType:String = (songNotes[3] != null && Note.noteTypes.exists(songNotes[3])) ? songNotes[3] : "Default";

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, daNoteType);
				swagNote.jsonData = songNotes;
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, daNoteType);
					sustainNote.jsonData = songNotes;
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);
					for (sustain in swagNote.sustainArray)
						sustain.sustainArray.push(sustainNote);
					swagNote.sustainArray.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2; // general offset
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2; // general offset
            }
        }
        unspawnNotes.sort(noteSort);

        return unspawnNotes;
    }

    function noteSort(note1:funkin.Note, note2:funkin.Note) {
        if (note1.strumTime < note2.strumTime)
            return -1;

        if (note1.strumTime > note2.strumTime)
            return 1;

        return 0;
    }

    function preloadFromTxt(path:String, secondWord:String) {
        for (line in utils.CoolUtil.coolTextFile(path)) {
            var daVars:Array<String> = line.split(" | ");
            switch (daVars[1].toLowerCase().trim()) {
                case "character" | "char":
					Character.preloadCharBitmap(daVars[2].trim());
                case "image" | "graphic":
                    var imagePath = Paths.image(daVars[2].trim());
                    cacheImage(daVars[0], imagePath);
                case "sound" | "audio":
                    var soundPath = Paths.sound(daVars[2].trim());
                    cacheSound(daVars[0], soundPath);
            }
        }
    }

	function cacheChar(name:String, char:String, x:Float, y:Float, isPlr:Bool) {
		var daChar = new Character(x, y, char, isPlr);
		preloadedAssets.set(name, daChar);
	}

	function cacheImage(name:String, path:String) {
		FlxG.bitmap.add(path);
		preloadedAssets.set(name, path);
	}

	function cacheSound(name:String, path:String) {
		FlxG.sound.cache(path);
		preloadedAssets.set(name, path);
	}
}