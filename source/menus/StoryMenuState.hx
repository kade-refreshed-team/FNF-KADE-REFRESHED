package menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;

import funkin.SongClasses.Song;
import funkin.PlayState;
import utils.Highscore;
import ui.MenuCharacter;
import ui.MenuItem;

#if windows
import Discord.DiscordClient;
#end

using StringTools;

typedef WeekData = {
	var name:String;
	var characters:Array<String>;
	var songs:Array<String>;
	var diffs:Array<String>;
}

class StoryMenuState extends base.MusicBeatState
{
	var scoreText:FlxText;

	var weekArray:Array<WeekData> = [];
	var curDifficulty:Int = 1;

	//public static var weekUnlocked:Array<Bool> = [true, true, true, true, true, true, true];

	var txtWeekTitle:FlxText;

	var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	//var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	override function create()
	{
		#if windows
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Story Mode Menu", null);
		#end

		for (line in utils.CoolUtil.coolTextFile(Paths.txt("storymenu/weekList"))) {
			var daVars:Array<String> = line.split(" | ");
			weekArray.push({
				name: daVars[0],
				characters: [for (char in daVars[1].split(",")) char.trim()],
				songs: [for (song in daVars[2].split(",")) song.trim()],
				diffs: [for (song in daVars[3].split(",")) song.trim().toLowerCase()]
			});
		}
		MenuCharacter.reparseSettings();

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('menu-side/storymenu/campaign_menu_UI_assets');
		var yellowBG:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		//grpLocks = new FlxTypedGroup<FlxSprite>();
		//add(grpLocks);

		for (i in 0...weekArray.length)
		{
			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, i);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekThing.screenCenter(X);
			weekThing.antialiasing = true;
			// weekThing.updateHitbox();

			/*// Needs an offset thingie
			nah it needs to be entirely commented out - Srt
			if (!weekUnlocked[i])
			{
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
				lock.frames = ui_tex;
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.ID = i;
				lock.antialiasing = true;
				grpLocks.add(lock);
			}*/
		}
		curDifficulty = Math.floor(weekArray[0].diffs.length / 2);

		grpWeekCharacters.add(new MenuCharacter(0, 100, 0.5, false));
		grpWeekCharacters.add(new MenuCharacter(450, 25, 0.9, true));
		grpWeekCharacters.add(new MenuCharacter(850, 100, 0.5, true));

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(leftArrow.x + 130, leftArrow.y, Paths.image('menu-side/storymenu/difficulties/${weekArray[0].diffs[curDifficulty]}'));

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 50, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);
		changeDifficulty();

		add(yellowBG);
		add(grpWeekCharacters);

		txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		updateText();

		super.create();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));

		scoreText.text = "WEEK SCORE:" + lerpScore;

		// FlxG.watch.addQuick('font', scoreText.font);

		//difficultySelectors.visible = weekUnlocked[curWeek];

		/*grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});*/

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				if (controls.UP_P)
				{
					changeWeek(-1);
				}

				if (controls.DOWN_P)
				{
					changeWeek(1);
				}

				if (controls.RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.RIGHT_P)
					changeDifficulty(1);
				if (controls.LEFT_P)
					changeDifficulty(-1);
			}

			if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		//if (weekUnlocked[curWeek]) {
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				for (char in grpWeekCharacters.members) {
					if (MenuCharacter.settings.exists("CONFIRM_" + char.curChar))
						char.animation.play("CONFIRM_" + char.curChar);
				}
				stopspamming = true;
			}

			Highscore.diffArray = weekArray[curWeek].diffs;
			PlayState.storyPlaylist = weekArray[curWeek].songs;
			PlayState.isStoryMode = true;
			selectedWeek = true;


			PlayState.storyDifficulty = curDifficulty;
			PlayState.sicks = 0;
			PlayState.bads = 0;
			PlayState.shits = 0;
			PlayState.goods = 0;
			PlayState.campaignMisses = 0;
			PlayState.SONG = Song.loadFromJson(Highscore.diffArray[curDifficulty].toLowerCase(), PlayState.storyPlaylist[0]);
			PlayState.storyWeek = curWeek;
			PlayState.campaignScore = 0;

			for (i in 0...grpWeekText.length)
				grpWeekText.members[i].visible = (i >= curWeek);
			var ogValues = [txtWeekTitle.x, leftArrow.x, sprDifficulty.x,  rightArrow.x];
			var yellowBG:FlxSprite = cast(members[members.indexOf(grpWeekCharacters) - 1], FlxSprite);
			FlxTween.num(0, 1.2, 1, {onComplete: (twn:FlxTween) -> {openSubState(new funkin.PreloadingSubState());}}, function(num:Float) {
				for (i=>text in grpWeekText.members)
					text.targetY = i - curWeek + num * 2.2;
				yellowBG.alpha = 1 - num;
				scoreText.x = 10 - (scoreText.width + 10) * num;
				txtWeekTitle.x = ogValues[0] + (txtWeekTitle.width + 10) * num;
				for (char in grpWeekCharacters.members)
					char.alpha = 1 - num;
				leftArrow.x = ogValues[1] + 460 * num;
				sprDifficulty.x = ogValues[2] + 460 * num;
				rightArrow.x = ogValues[3] + 460 * num;
				txtTracklist.alpha = 1 - num;
			});
		//}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty = (curDifficulty + weekArray[curWeek].diffs.length + change) % weekArray[curWeek].diffs.length;

		sprDifficulty.loadGraphic(Paths.image('menu-side/storymenu/difficulties/${weekArray[curWeek].diffs[curDifficulty]}'));
		sprDifficulty.updateHitbox();
		sprDifficulty.alpha = 0;
		leftArrow.x = grpWeekText.members[curWeek].x + grpWeekText.members[curWeek].width + 10;
		sprDifficulty.x = leftArrow.x + leftArrow.width + 10;
		rightArrow.x = sprDifficulty.x + sprDifficulty.width + 10;

		// USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP
		var daY =  leftArrow.y + leftArrow.height / 2 - sprDifficulty.height / 2;
		sprDifficulty.y = daY - 15;
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
		#end

		FlxTween.tween(sprDifficulty, {y: daY, alpha: 1}, 0.07);
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void {
		curWeek = (curWeek + weekArray.length + change) % weekArray.length;

		txtWeekTitle.text = weekArray[curWeek].name.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) /*&& weekUnlocked[curWeek]*/)
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));

		changeDifficulty();
		updateText();
	}

	function updateText()
	{
		var weekCharacters:Array<String> = weekArray[curWeek].characters;
		grpWeekCharacters.members[0].setCharacter(weekCharacters[0]);
		grpWeekCharacters.members[1].setCharacter(weekCharacters[1]);
		grpWeekCharacters.members[2].setCharacter(weekCharacters[2]);

		txtTracklist.text = "Tracks\n";

		for (i in weekArray[curWeek].songs)
			txtTracklist.text += "\n" + i;

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		txtTracklist.text += "\n";

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
		#end
	}
}
