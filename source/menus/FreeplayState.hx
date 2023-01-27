package menus;

import utils.CoolUtil;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.Alphabet;
import ui.HealthIcon;
import utils.Highscore;
import funkin.PlayState;
#if windows
import Discord.DiscordClient;
#end

using StringTools;

class FreeplayState extends base.MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var combo:String = '';

	var bg:FlxSprite;
	var grpSongs:FlxTypedGroup<Alphabet>;
	var opIcon:HealthIcon;
	var plIcon:HealthIcon;
	var lastColor:FlxColor = 0xFFFFFFFF;
	var sinceLastSelect:Float = 0;
	var curPlaying:Bool = false;

	// private var iconArray:Array<HealthIcon> = [];

	override function create()
	{
		songs = SongMetadata.createSongs(utils.CoolUtil.coolTextFile(Paths.txt('freeplaySonglist')));

		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		 */

		#if windows
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Freeplay Menu", null);
		#end

		// LOAD MUSIC

		// LOAD CHARACTERS

		bg = new FlxSprite().loadGraphic(Paths.image('menu-side/menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false, true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			if (!FlxG.save.data.ogfreeplay)
			{
				var scaledY = FlxMath.remapToRange(i, 0, 1, 0, 1.3);
				songText.y = (scaledY * 120) + (FlxG.height * 0.48);
			}
		}
		bg.color = songs[0].color;

		opIcon = new HealthIcon(songs[0].songCharacter);
		opIcon.x = grpSongs.members[0].x - opIcon.width - 10;
		opIcon.y = 380 - opIcon.height / 2;
		add(opIcon);
		plIcon = new HealthIcon(songs[0].songPlayer);
		plIcon.y = 380 - plIcon.height / 2;
		plIcon.flipX = true;
		if (!FlxG.save.data.ogfreeplay)
			add(plIcon);

		scoreText = new FlxText(0, grpSongs.members[0].y + grpSongs.members[0].height + 5, FlxG.width, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		if (!FlxG.save.data.ogfreeplay)
			add(scoreText);

		if (FlxG.save.data.ogfreeplay)
		{
			scoreText.setPosition(FlxG.width * 0.7, 5);
			scoreText.alignment = LEFT;

			var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
			scoreBG.alpha = 0.6;
			add(scoreBG);
			add(scoreText);
		}

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		sinceLastSelect = Math.min(sinceLastSelect + elapsed * 2, 1);
		bg.color = FlxColor.interpolate(lastColor, songs[curSelected].color, sinceLastSelect);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (combo.trim() == "")
			combo = (intendedScore == 0) ? "UNFINISHED" : "CLEARED";
		if (!FlxG.save.data.ogfreeplay)
			scoreText.text = '[${songs[curSelected].diffs[curDifficulty].toUpperCase()}] - High Score: $lerpScore ($combo)';
		else
			scoreText.text = 'Score: $lerpScore ($combo)\n[${songs[curSelected].diffs[curDifficulty].toUpperCase()}]';

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.LEFT_P)
			changeDiff(-1);
		if (controls.RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			FlxG.switchState(new menus.MainMenuState());
		}

		if (accepted)
		{
			Highscore.diffArray = songs[curSelected].diffs;
			PlayState.SONG = funkin.SongClasses.Song.loadFromJson(Highscore.diffArray[curDifficulty].toLowerCase(), songs[curSelected].songName);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			PlayState.storyWeek = songs[curSelected].week;
			trace('CUR WEEK' + PlayState.storyWeek);
			openSubState(new funkin.PreloadingSubState());
		}

		for (text in grpSongs.members)
			if (!FlxG.save.data.ogfreeplay)
			{
				text.x = 640 - text.width / 2;
				opIcon.x = grpSongs.members[curSelected].x - opIcon.width - 10;
				plIcon.x = grpSongs.members[curSelected].x + grpSongs.members[curSelected].width + 10;
				scoreText.y = grpSongs.members[curSelected].y + grpSongs.members[curSelected].height + 5;
			}
			else
			{
				text.x -= 10;
				opIcon.x = opIcon.x = grpSongs.members[curSelected].x + grpSongs.members[curSelected].width + 4;
			}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty = (curDifficulty + songs[curSelected].diffs.length + change) % songs[curSelected].diffs.length;

		// adjusting the highscore song name to be compatible (changeDiff)
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");
		switch (songHighscore)
		{
			case 'Dad-Battle':
				songHighscore = 'Dadbattle';
			case 'Philly-Nice':
				songHighscore = 'Philly';
		}

		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty);
		combo = Highscore.getCombo(songHighscore, curDifficulty);
		#end
	}

	function changeSelection(change:Int = 0)
	{
		#if !switch
		// NGio.logEvent('Fresh');
		#end

		// NGio.logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		lastColor = bg.color;
		sinceLastSelect = 0;
		curSelected = (curSelected + songs.length + change) % songs.length;
		changeDiff();

		opIcon.changeIcon(songs[curSelected].songCharacter);
		plIcon.changeIcon(songs[curSelected].songPlayer);

		// selector.y = (70 * curSelected) + 30;

		// adjusting the highscore song name to be compatible (changeSelection)
		// would read original scores if we didn't change packages
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");
		switch (songHighscore)
		{
			case 'Dad-Battle':
				songHighscore = 'Dadbattle';
			case 'Philly-Nice':
				songHighscore = 'Philly';
		}

		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty);
		combo = Highscore.getCombo(songHighscore, curDifficulty);
		// lerpScore = 0;
		#end

		FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);

		for (bullShit => item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;

			// nah we dont got if statements
			item.alpha = 1 - 0.4 * Math.min(Math.abs(item.targetY), 1);
		}
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var diffs:Array<String> = [];
	public var songCharacter:String = "";
	public var songPlayer:String = "";
	public var color:FlxColor = 0xFFFFFFFF;
	public var week:Int = 0;

	public function new(song:String, week:Int, songCharacter:String, songPlayer:String, color:FlxColor, diffs:Array<String>)
	{
		this.songName = song;
		this.diffs = diffs;
		this.songCharacter = songCharacter;
		this.songPlayer = songPlayer;
		this.color = color;
		this.week = week;
	}

	public static function createSongs(lines:Array<String>)
	{
		var songs:Array<SongMetadata> = [];
		for (line in lines)
		{
			var daVars:Array<String> = line.split(" | ");
			var daSongs:Array<String> = daVars[0].split(",");
			var iconSplit:Array<String> = daVars[1].split(":");
			var daDiffs:Array<String> = [for (diff in daVars[2].split(",")) diff.trim().toLowerCase()];
			for (song in daSongs)
				songs.push(new SongMetadata(song.trim(), Std.parseInt(daVars[4].trim()), iconSplit[0].trim(), iconSplit[1].trim(),
					CoolUtil.stringColor(daVars[3]), daDiffs));
		}

		return songs;
	}
}
