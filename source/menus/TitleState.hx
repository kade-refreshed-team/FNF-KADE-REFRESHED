package menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import openfl.Assets;

import ui.Alphabet;
import base.Conductor;
import base.Main;

using StringTools;

class TitleState extends base.MusicBeatState
{
	static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var ngSpr:FlxSprite;

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	override public function tryCreate() {
		#if sys
		var modList = sys.io.File.getContent(sys.FileSystem.absolutePath('mods/modList.txt'));
        // polymod.Polymod.init({
        //     modRoot: "./mods/",
        //     dirs: utils.CoolUtil.coolStringFile(modList)
        // });
		Assets.foldersToCheck = [for (line in utils.CoolUtil.coolStringFile(modList)) './mods/$line'];
		Assets.foldersToCheck.push('./assets');
        #end

		super.tryCreate();
	}

	override public function create():Void {
		curWacky = FlxG.random.getObject(getIntroTextShit());

		super.create();

		startIntro();
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var titleText:FlxSprite;
	
	var kadeText:FlxSprite;
	var kadeSpin:FlxSprite;

	function startIntro() {
		if (FlxG.sound.music == null || !FlxG.sound.music.playing) {
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}

		Conductor.changeBPM(102);
		persistentUpdate = true;

		gfDance = new FlxSprite(FlxG.width * 0.4 + 50, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('menu-side/gameStart/gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = true;
		add(gfDance);

		logoBl = new FlxSprite(-100, -100);
		logoBl.frames = Paths.getSparrowAtlas('menu-side/gameStart/logoBumpin');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		add(logoBl);

		kadeText = new FlxSprite(logoBl.x + 120, logoBl.y + logoBl.height - 200, Paths.image("menu-side/KadeRefreshedText"));
		kadeText.scale.set(0.85, 0.85);
		kadeText.updateHitbox();
		kadeText.antialiasing = true;
		add(kadeText);
	
		kadeSpin = new FlxSprite(kadeText.x + kadeText.width - 20, kadeText.y, Paths.image("menu-side/KadeRefreshedArrowThingy"));
		kadeSpin.scale.set(0.33, 0.33);
		kadeSpin.updateHitbox();
		kadeSpin.antialiasing = true;
		add(kadeSpin);

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('menu-side/gameStart/titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = true;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		credGroup = new FlxGroup();
		add(credGroup);

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "ninjamuffin99\nPhantomArcade\nkawaisprite\nevilsk8er", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('menu-side/gameStart/newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = true;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>> {
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [for (i in firstArray) i.split("--")];

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.keys.justPressed.F)
			FlxG.fullscreen = !FlxG.fullscreen;

		if (kadeText != null) {
			var mainRatio = (floatBeat % 2 < 0.5) ? FlxEase.circIn(1 - (floatBeat % 2) * 2) : 0;
			kadeText.scale.x = FlxMath.lerp(0.85, 0.95, mainRatio);
			kadeText.scale.y = kadeText.scale.x;
		
			kadeSpin.scale.x = FlxMath.lerp(0.33, 0.4, mainRatio);
			kadeSpin.scale.y = kadeSpin.scale.x;
			var spinRatio = FlxEase.circIn((1 - floatBeat % 1) * (1 - curBeat % 2));
			kadeSpin.angle = FlxMath.lerp(0, 360, spinRatio);
		}

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

		#if mobile
		for (touch in FlxG.touches.list)
			pressedEnter = pressedEnter || touch.justPressed;
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null) {
			pressedEnter = pressedEnter || gamepad.justPressed.START;

			#if switch
			pressedEnter = pressedEnter || gamepad.justPressed.B;
			#end
		}

		if (pressedEnter && !transitioning && skippedIntro) {
			if (Date.now().getDay() == 5)
				trace('yoooo its friday');

			if (FlxG.save.data.flashing)
				titleText.animation.play('press');

			FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;
			// FlxG.sound.music.stop();

			MainMenuState.firstStart = true;

			new FlxTimer().start(2, function(tmr:FlxTimer) {
				//Dont want the outdated thingy.
				FlxG.switchState(new MainMenuState());

				/*// Get current version of Kade Engine
				
				var http = new haxe.Http("https://raw.githubusercontent.com/KadeDev/Kade-Engine/master/version.downloadMe");
				var returnedData:Array<String> = [];
				
				http.onData = function (data:String)
				{
					returnedData[0] = data.substring(0, data.indexOf(';'));
					returnedData[1] = data.substring(data.indexOf('-'), data.length);
				  	if (!MainMenuState.kadeEngineVer.contains(returnedData[0].trim()) && !OutdatedSubState.leftState && MainMenuState.nightly == "")
					{
						trace('outdated lmao! ' + returnedData[0] + ' != ' + MainMenuState.kadeEngineVer);
						OutdatedSubState.needVer = returnedData[0];
						OutdatedSubState.currChanges = returnedData[1];
						FlxG.switchState(new OutdatedSubState());
					}
					else
					{
						FlxG.switchState(new MainMenuState());
					}
				}
				
				http.onError = function (error) {
				  trace('error: $error');
				  FlxG.switchState(new MainMenuState()); // fail but we go anyway
				}
				
				http.request();*/
			});
			// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
		}

		if (pressedEnter && !skippedIntro && initialized)
			skipIntro();

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>) {
		for (i in 0...textArray.length) {
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200;
			credGroup.add(money);
		}
	}

	function addMoreText(text:String) {
		var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
		coolText.screenCenter(X);
		coolText.y += (credGroup.length * 60) + 200;
		credGroup.add(coolText);
	}

	function deleteCoolText() {
		while (credGroup.length > 1) {
			var member = credGroup.members[1];
			member.destroy();
			credGroup.remove(member, true);
		}
	}

	override function beatHit() {
		super.beatHit();

		if (logoBl != null)
			logoBl.animation.play('bump');

		if (gfDance != null)
			gfDance.animation.play((curBeat % 2 == 0) ? 'danceLeft' : 'danceRight');

		switch (curBeat) {
			case 1:
				createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
			case 3:
				addMoreText('present');
			case 4:
				deleteCoolText();
			case 5:
				createCoolText((Main.watermarks) ? ['Kade Engine', 'by'] : ['In Partnership', 'with']);
			case 7:
				addMoreText((Main.watermarks) ? 'KadeDeveloper' : 'Newgrounds');
				ngSpr.visible = !Main.watermarks;
			case 8:
				deleteCoolText();
				ngSpr.visible = false;
			case 9:
				createCoolText([curWacky[0]]);
			case 11:
				addMoreText(curWacky[1]);
			case 12:
				deleteCoolText();
			case 13:
				addMoreText('Friday');
			case 14:
				addMoreText('Night');
			case 15:
				addMoreText('Funkin');
			case 16:
				skipIntro();
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void {
		if (!skippedIntro) {
			remove(ngSpr);

			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);
			skippedIntro = true;
		}
	}
}
