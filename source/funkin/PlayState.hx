package funkin;

import scripts.BaseScript;
import lime.ui.Window;
import webm.WebmPlayer;
import lime.app.Application;
import openfl.Lib;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import lime.utils.Assets;
import ui.HealthIcon;
import utils.*;
import base.*;
import funkin.SongClasses;
import funkin.GraphicBar;
import menus.*;
#if windows
import Discord.DiscordClient;
#end
#if windows
import Sys;
import sys.FileSystem;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState = null;

	public static var curStage:String = '';
	public static var songLowercase:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	var storyDifficultyText:String = "";

	public static var weekSong:Int = 0;
	public static var weekScore:Int = 0;
	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public var songScore:Int = 0;
	public static var misses:Int = 0;
	public static var shits:Int = 0;
	public static var bads:Int = 0;
	public static var goods:Int = 0;
	public static var sicks:Int = 0;

	private var combo:Int = 0;

	public var accuracy:Float = 0.00;
	private var accuracyDefault:Float = 0.00;
	private var totalNotesHit:Float = 0;
	private var totalNotesHitDefault:Float = 0;
	private var totalPlayed:Int = 0;

	public static var rep:Replay;
	public static var loadRep:Bool = false;
	
	var halloweenLevel:Bool = false;

	#if windows
	// Discord RPC variables
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	private var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	public var strumLine:FlxSprite;

	private var curSection:Int = 0;

	private var camFollow:FlxObject;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	public var deadChr:String = "bf";
	public var deadSFX:String = "fnf_loss_sfx";
	public var deadMus:String = "gameOver";
	public var deadEnd:String = "gameOverEnd";

	private var gfSpeed:Int = 1;

	public var healthBar:GraphicBar;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	var scoreTxt:FlxText;
	public var health:Float = 1;

	public var songPosBar:GraphicBar;
	var songName:FlxText;
	var songLength:Float = 0;
	var rgEngineWatermark:FlxText;

	public var strumLineNotes:FlxTypedGroup<FlxSprite> = null;
	public var playerStrums:Array<FlxSprite> = null;
	public var cpuStrums:Array<FlxSprite> = null;
	public var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	public var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	public static var offsetTesting:Bool = false;

	var notesHitArray:Array<Date> = [];
	var currentFrames:Int = 0;

	public var dialogue:Array<String> = ['dad:blah blah blah', 'bf:coolswag'];

	var scripts:Array<BaseScript> = [];
	var stageSprites:Map<String, FlxSprite> = [];
	public var camOffsets:{bfCamX:Float, bfCamY:Float, gfCamX:Float, gfCamY:Float, dadCamX:Float, dadCamY:Float} = {
		bfCamX: 0.0,
		bfCamY: 0.0,
		gfCamX: 0.0,
		gfCamY: 0.0,
		dadCamX: 0.0,
		dadCamY: 0.0
	}
	public var defaultCamZoom:Float = 1.05;
	public static var daPixelZoom:Float = 6;

	var songScoreDef:Int = 0;
	var currentTimingShown:FlxText = null;

	public static var theFunne:Bool = true;

	var inCutscene:Bool = false;

	public static var repPresses:Int = 0;
	public static var repReleases:Int = 0;

	public static var timeCurrently:Float = 0;
	public static var timeCurrentlyR:Float = 0;

	// Will fire once to prevent debug spam messages and broken animations
	private var triggeredAlready:Bool = false;

	// Will decide if she's even allowed to headbang at all depending on the song
	private var allowedToHeadbang:Bool = false;

	// Per song additive offset
	public static var songOffset:Float = 0;

	// Replay shit
	private var saveNotes:Array<Dynamic> = [];

	public static var highestCombo:Int = 0;

	private var executeModchart = false;

	//To work with lua
	public function memberIndex(member:FlxBasic)
		return members.indexOf(member);

	public var preloadedAssets:Map<String, Dynamic>;

	public function new(preloaded:Map<String, Dynamic>) {
		super();
		preloadedAssets = preloaded;
	}

	override public function create() {
		instance = this;

		if (FlxG.save.data.fpsCap > 290)
			(cast(Lib.current.getChildAt(0), Main)).setFPSCap(800);

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (!isStoryMode) {
			sicks = 0;
			bads = 0;
			shits = 0;
			goods = 0;
		}
		misses = 0;

		repPresses = 0;
		repReleases = 0;

		removedVideo = false;

		#if windows
		executeModchart = FileSystem.exists(Paths.songFile("modchart.lua", songLowercase));
		#end
		#if !cpp
		executeModchart = false; // FORCE disable for non cpp targets
		#end

		storyDifficultyText = Highscore.diffArray[storyDifficulty].toUpperCase();

		iconRPC = SONG.player2;

		#if windows
		// To avoid having duplicate images in Discord assets
		switch (iconRPC)
		{
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: Week " + storyWeek;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		var discordText:String = ' ${SONG.song} ($storyDifficultyText) ${Ratings.GenerateLetterRank(accuracy)}';
		var discordText2:String = '\nAcc: ${HelperFunctions.truncateFloat(accuracy, 2)}% | Score: $songScore | Misses: $misses';
		DiscordClient.changePresence(detailsText + discordText, discordText2, iconRPC);
		#end

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('normal', 'tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		// dialogue shit
		switch (songLowercase)
		{
			case 'tutorial':
				dialogue = ["Hey you're pretty cute.", 'Use the arrow keys to keep up \nwith me singing.'];
			case 'bopeebo':
				dialogue = [
					'HEY!',
					"You think you can just sing\nwith my daughter like that?",
					"If you want to date her...",
					"You're going to have to go \nthrough ME first!"
				];
			case 'fresh':
				dialogue = ["Not too shabby boy.", ""];
			case 'dadbattle':
				dialogue = [
					"gah you think you're hot stuff?",
					"If you can beat me here...",
					"Only then I will even CONSIDER letting you\ndate my daughter!"
				];
			default:
				if (Assets.exists(Paths.songFile('Dialogue.txt', songLowercase)))
					dialogue = CoolUtil.coolTextFile(Paths.songFile('Dialogue.txt', songLowercase));
				else
					dialogue = [':bf: null?', ':dad: yep', ':bf: WHAAAAAAAAAAAA'];
					trace(Paths.songFile('Dialogue.txt', songLowercase));
		}

		gf = preloadedAssets.get("gf");
		gf.scrollFactor.set(0.95, 0.95);

		dad = preloadedAssets.get("dad");

		boyfriend = preloadedAssets.get("bf");

		curStage = SONG.stage;
		stageSprites = HelperFunctions.parseStage(Paths.txt('stages/$curStage'), this);
		scripts.push(BaseScript.makeScript('assets/data/stages/$curStage'));

		var scriptListPath = Paths.songFile('scripts.txt', songLowercase);
		if (Assets.exists(scriptListPath)) {
			for (file in CoolUtil.coolTextFile(scriptListPath)) {
				var filePath = file.replace("SONG_PATH", 'songs/$songLowercase');
				var fileWithoutExt = haxe.io.Path.withoutExtension(filePath);
				scripts.push(BaseScript.makeScript('assets/$fileWithoutExt'));
			}
		}
		#if sys
		var exts = [];
		for (type in BaseScript.scriptTypes)
			exts = exts.concat(type.exts);

		var directoriesToRead:Array<String> = [];
        if (FileSystem.exists(FileSystem.absolutePath('assets/data/gameScripts')) && FileSystem.isDirectory(FileSystem.absolutePath('assets/data/gameScripts')))
            directoriesToRead.push(FileSystem.absolutePath('assets/data/gameScripts'));
        @:privateAccess for (modDir in polymod.Polymod.prevParams.dirs) {
            if (FileSystem.exists(FileSystem.absolutePath('$modDir/data/gameScripts')) && FileSystem.isDirectory(FileSystem.absolutePath('$modDir/data/gameScripts')))
                directoriesToRead.push(FileSystem.absolutePath('$modDir/data/gameScripts'));
        }

		for (daDirectory in directoriesToRead) {
            for (file in FileSystem.readDirectory(daDirectory)) {
				if (exts.contains(haxe.io.Path.extension(file)))
					scripts.push(BaseScript.makeScript('assets/data/gameScripts/${haxe.io.Path.withoutExtension(file)}'));
			}
        }
		#end

		for (s in scripts) {
			s.parent = this;
			s.setVar("parent", this);
			s.execute();
			s.callFunc('create');
		}

		if (dad.data.commonSide == "gf") {
			dad.x = gf.x;
			dad.y = gf.y;
			camOffsets.dadCamX = camOffsets.gfCamX;
			camOffsets.dadCamY = camOffsets.gfCamY;
			gf.visible = false;
			if (isStoryMode) 
				tweenCamIn();
		}

		if (loadRep)
		{
			FlxG.watch.addQuick('rep rpesses', repPresses);
			FlxG.watch.addQuick('rep releases', repReleases);
			// FlxG.watch.addQuick('Queued',inputsQueued);

			PlayStateChangeables.useDownscroll = rep.replay.isDownscroll;
			PlayStateChangeables.safeFrames = rep.replay.sf;
			PlayStateChangeables.botPlay = true;
		}

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (PlayStateChangeables.useDownscroll)
			strumLine.y = FlxG.height - 165;

		strumLineNotes = preloadedAssets.get("strumLineNotes");
		add(strumLineNotes);

		playerStrums = preloadedAssets.get("playerStrums");
		cpuStrums = preloadedAssets.get("cpuStrums");

		generateSong(SONG.song);

		//Cam stuff
		camFollow = new FlxObject(0, 0, 1, 1);
		FlxG.camera.zoom = defaultCamZoom;

		add(camFollow);
		FlxG.camera.follow(camFollow, LOCKON, 0.04 * (30 / (cast(Lib.current.getChildAt(0), Main)).getFPS()));
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;
		if (PlayState.SONG.notes[0] != null && SONG.notes[0].mustHitSection) {
			var bfMidpoint = boyfriend.getMidpoint();
			bfMidpoint.x = bfMidpoint.x - 100 + camOffsets.bfCamX + boyfriend.data.offsets.camX;
			bfMidpoint.y = bfMidpoint.y - 100 + camOffsets.bfCamY + boyfriend.data.offsets.camY;
			camFollow.setPosition(bfMidpoint.x, bfMidpoint.y);
			FlxG.camera.focusOn(bfMidpoint);
			bfMidpoint.put();
		} else {
			var dadMidpoint = dad.getMidpoint();
			dadMidpoint.x = dadMidpoint.x - 100 + camOffsets.dadCamX + dad.data.offsets.camX;
			dadMidpoint.y = dadMidpoint.y - 100 + camOffsets.dadCamY + dad.data.offsets.camY;
			camFollow.setPosition(dadMidpoint.x, dadMidpoint.y);
			FlxG.camera.focusOn(dadMidpoint);
			dadMidpoint.put();
		}

		if (FlxG.save.data.songPosition) // I dont wanna talk about this code :(
		{
			songPosBar = new GraphicBar('game-side/healthBar', 0xFF00FF00, 0xFF808080, (PlayStateChangeables.useDownscroll) ? FlxG.height * 0.9 + 45 : 10);
			songPosBar.scrollFactor.set();
			songPosBar.cameras = [camHUD];
			add(songPosBar);

			songName = new FlxText(songPosBar.x, songPosBar.y + songPosBar.height / 2, songPosBar.width, '${SONG.song} - [$storyDifficultyText]', 16);
			songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			songName.scrollFactor.set();
			add(songName);
			songName.y -= songName.height / 2;
			songName.cameras = [camHUD];
			if (PlayStateChangeables.PsychUI)
			{
				songName.y = (PlayStateChangeables.useDownscroll) ? FlxG.height - 44 : 19;
				songName.size = 32;
				songName.borderSize = 2;

				songPosBar.setGraphicSize(400, 19);
				songPosBar.updateHitbox();
				songPosBar.setPosition(FlxG.width / 2 - songPosBar.width / 2, songName.y + (songName.height / 4));
				songPosBar.fillColor = 0xFFFFFFFF;
				songPosBar.emptyColor = 0xFF000000;

				Application.current.window.title = 'Friday Night Funkin : Psych Engine';
			}
		}

		healthBar = new GraphicBar('game-side/healthBar', boyfriend.hpColor, dad.hpColor, (PlayStateChangeables.useDownscroll) ? 50 : FlxG.height * 0.9);
		healthBar.scrollFactor.set();
		healthBar.inverted = true;
		add(healthBar);

		// Add Kade Engine watermark
		rgEngineWatermark = new FlxText(5, FlxG.height - 5, 0, 'RG Engine v${MainMenuState.kadeEngineVer}', 16);
		rgEngineWatermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		rgEngineWatermark.scrollFactor.set();
		rgEngineWatermark.visible = (Main.watermarks && !PlayStateChangeables.PsychUI);
		add(rgEngineWatermark);
		rgEngineWatermark.y -= rgEngineWatermark.height;

		scoreTxt = new FlxText(0, healthBar.y + 40, FlxG.width, "", 20);
		scoreTxt.scrollFactor.set();
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (PlayStateChangeables.PsychUI){
			scoreTxt.size = 20;
			scoreTxt.borderSize = 1.25;
		}

		//No more copy-paste of code above, fu
		if (PlayStateChangeables.botPlay || loadRep) {
			var autoText:String = (PlayStateChangeables.botPlay && !loadRep) ? "BOTPLAY" : "REPLAY";
			var autoPlay:FlxText = new FlxText(healthBar.x + healthBar.width / 2 - 75, healthBar.y + (PlayStateChangeables.useDownscroll ? 100 : -100), 0,
			autoText, 20);
			autoPlay.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			autoPlay.scrollFactor.set();
			autoPlay.borderSize = 4;
			autoPlay.borderQuality = 2;
			add(autoPlay);
			autoPlay.cameras = [camHUD];
		}

		iconP1 = new HealthIcon(boyfriend.data.iconAsset, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(dad.data.iconAsset, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		add(scoreTxt);

		currentTimingShown = new FlxText(0, 0, 0, "0ms");
		currentTimingShown.borderStyle = OUTLINE;
		currentTimingShown.borderSize = 1;
		currentTimingShown.borderColor = FlxColor.BLACK;
		currentTimingShown.alpha = 0;
		currentTimingShown.size = 20;
		currentTimingShown.visible = (!PlayStateChangeables.botPlay || loadRep);
		add(currentTimingShown);

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
		rgEngineWatermark.cameras = [camHUD];
		currentTimingShown.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		if (isStoryMode) {
			switch (StringTools.replace(curSong, " ", "-").toLowerCase()) {
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer) {
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer) {
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween) {
									startCountdown();
								}
							});
						});
					});
				case 'thorns':
					thornsIntro(doof);
				default:
					if (Assets.exists(Paths.songFile('Dialogue.txt', songLowercase)))
					dialogueIntro(doof);
					else
					startCountdown();
			}
		} else {
			switch (curSong.toLowerCase()) {
				default:
					startCountdown();
			}
		}

		if (!loadRep)
			rep = new Replay("na");

		super.create();
		scripts_call("createPost");
	}
	function dialogueIntro(?dialogueBox:DialogueBox):Void{
		if (dialogueBox != null)
			{
				inCutscene = true;
				add(dialogueBox);
			}
	}


	function thornsIntro(?dialogueBox:DialogueBox):Void {
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();
		add(red);

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('cutscene/week6/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		new FlxTimer().start(0.3, function(tmr:FlxTimer) {
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
			else {
				if (dialogueBox != null) {
					inCutscene = true;

						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer) {
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
								swagTimer.reset();
							else {
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('week6/Senpai_Dies'), 1, false, null, true, function() {
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function() {
										add(dialogueBox);
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer) {
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
						add(dialogueBox);
				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function startCountdown():Void {
		inCutscene = false;

		generateStaticArrows();

		scripts_call('countdownStart');

		startedCountdown = true;
		Conductor.songPosition = Conductor.crochet * -5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
			scripts_call("countdownTick", [swagCounter]);

			dad.dance();
			gf.dance();
			boyfriend.dance();

			switch (swagCounter) {
				case 0:
					FlxG.sound.play(preloadedAssets.get("countdownSound3"), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(preloadedAssets.get("countdownImage0"));
					ready.scrollFactor.set();
					ready.setGraphicSize(550);
					ready.updateHitbox();
					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(preloadedAssets.get("countdownSound2"), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(preloadedAssets.get("countdownImage1"));
					set.scrollFactor.set();
					set.setGraphicSize(550);
					set.updateHitbox();
					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(preloadedAssets.get("countdownSound1"), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(preloadedAssets.get("countdownImage2"));
					go.scrollFactor.set();
					go.setGraphicSize(550);
					go.updateHitbox();
					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(preloadedAssets.get("countdownSound0"), 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	var songStarted = false;

	function startSong():Void {
		scripts_call('songStart');

		startingSong = false;
		songStarted = true;
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			FlxG.sound.playMusic(preloadedAssets.get("inst"));

		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Song check real quick
		switch (curSong)
		{
			case 'Bopeebo' | 'Philly Nice' | 'Blammed' | 'Cocoa' | 'Eggnog':
				allowedToHeadbang = true;
			default:
				allowedToHeadbang = false;
		}

		if (useVideo)
			GlobalVideo.get().resume();

		#if windows
		// Updating Discord Rich Presence (with Time Left)
		var discordText:String = ' ${SONG.song} ($storyDifficultyText) ${Ratings.GenerateLetterRank(accuracy)}';
		var discordText2:String = '\nAcc: ${HelperFunctions.truncateFloat(accuracy, 2)}% | Score: $songScore | Misses: $misses';
		DiscordClient.changePresence(detailsText + discordText, discordText2, iconRPC);
		#end
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void {
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(preloadedAssets.get("vocals"));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		unspawnNotes = preloadedAssets.get("notes");

		generatedMusic = true;
	}

	//Not really "generateStaticArrows" anymore. It's more used to reposition the strum y and tween it.
	private function generateStaticArrows():Void {
		for (i in 0...4) {
			cpuStrums[i].y = strumLine.y;
			playerStrums[3 - i].y = strumLine.y;
			if (!isStoryMode) {
				var babyArrow = cpuStrums[i];
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
				var playArrow = playerStrums[3 - i];
				playArrow.y -= 10;
				playArrow.alpha = 0;
				FlxTween.tween(playArrow, {y: playArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
		}
	}

	function tweenCamIn():Void {
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState) {
		if (paused) {
			if (FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				vocals.pause();
			}

			#if windows
			var discordText:String = 'PAUSED on ${SONG.song} ($storyDifficultyText) ${Ratings.GenerateLetterRank(accuracy)}';
			var discordText2:String = 'Acc: ${HelperFunctions.truncateFloat(accuracy, 2)}% | Score: $songScore | Misses: $misses';
			DiscordClient.changePresence(discordText, discordText2, iconRPC);
			#end
			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState() {
		if (paused) {
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if windows
			if (startTimer.finished) {
				var discordText:String = ' ${SONG.song} ($storyDifficultyText) ${Ratings.GenerateLetterRank(accuracy)}';
				var discordText2:String = 'Acc: ${HelperFunctions.truncateFloat(accuracy, 2)}% | Score: $songScore | Misses: $misses';
				DiscordClient.changePresence(detailsText + discordText, discordText2, iconRPC, true, songLength - Conductor.songPosition);
			} else
				DiscordClient.changePresence(detailsText, '${SONG.song} ($storyDifficultyText) ${Ratings.GenerateLetterRank(accuracy)}', iconRPC);
			#end
		}

		super.closeSubState();
	}

	function resyncVocals():Void {
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();

		#if windows
		var discordText:String = ' ${SONG.song} ($storyDifficultyText) ${Ratings.GenerateLetterRank(accuracy)}';
		var discordText2:String = '\nAcc: ${HelperFunctions.truncateFloat(accuracy, 2)}% | Score: $songScore | Misses: $misses';
		DiscordClient.changePresence(detailsText + discordText, discordText2, iconRPC);
		#end
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var nps:Int = 0;
	var maxNPS:Int = 0;

	public static var songRate = 1.5;

	public var stopUpdate = false;
	public var removedVideo = false;

	override public function update(elapsed:Float)
	{
		scripts_call("update", [elapsed]);
		#if !debug
		perfectMode = false;
		#end

		if (PlayStateChangeables.botPlay && FlxG.keys.justPressed.ONE)
			camHUD.visible = !camHUD.visible;

		if (useVideo && GlobalVideo.get() != null && !stopUpdate)
		{
			if (GlobalVideo.get().ended && !removedVideo)
			{
				remove(videoSprite);
				FlxG.stage.window.onFocusOut.remove(focusOut);
				FlxG.stage.window.onFocusIn.remove(focusIn);
				removedVideo = true;
			}
		}

		// reverse iterate to remove oldest notes first and not invalidate the iteration
		// stop iteration as soon as a note is not removed
		// all notes should be kept in the correct order and this is optimal, safe to do every frame/update
		{
			var balls = notesHitArray.length - 1;
			while (balls >= 0)
			{
				var cock:Date = notesHitArray[balls];
				if (cock != null && cock.getTime() + 1000 < Date.now().getTime())
					notesHitArray.remove(cock);
				else
					balls = 0;
				balls--;
			}
			nps = notesHitArray.length;
			if (nps > maxNPS)
				maxNPS = nps;
		}

		if (FlxG.keys.justPressed.NINE)
		{
			if (iconP1.char == 'bf-old')
				iconP1.changeIcon(boyfriend.data.iconAsset);
			else
				iconP1.changeIcon('bf-old');
		}

		super.update(elapsed);

		if (PlayStateChangeables.PsychUI)
		{
			var daScale:Float = Math.max(scoreTxt.scale.x - elapsed * 0.075 * 5, 1);
			songName.text = FlxStringUtil.formatTime((FlxG.sound.music.length - Math.max(Conductor.songPosition, 0)) / 1000, false);
			scoreTxt.text = Ratings.PsychScoreTxt(songScore, misses, accuracy, nps, maxNPS);
			scoreTxt.scale.set(daScale, daScale);
		}
		else
			scoreTxt.text = Ratings.CalculateRanking(songScore, songScoreDef, nps, maxNPS, accuracy);

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1))
			{
				FlxG.switchState(new GitarooPause());
			}
			else
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			if (useVideo)
			{
				GlobalVideo.get().stop();
				remove(videoSprite);
				FlxG.stage.window.onFocusOut.remove(focusOut);
				FlxG.stage.window.onFocusIn.remove(focusIn);
				removedVideo = true;
			}
			#if windows
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
			FlxG.switchState(new debug.ChartingState());
		}

		if (FlxG.keys.justPressed.FIVE)
		{
			if (useVideo)
			{
				GlobalVideo.get().stop();
				remove(videoSprite);
				FlxG.stage.window.onFocusOut.remove(focusOut);
				FlxG.stage.window.onFocusIn.remove(focusIn);
				removedVideo = true;
			}
			#if windows
			DiscordClient.changePresence("Char Editor", SONG.player2, null, true);
			#end
			FlxG.switchState(new debug.AnimationDebug(SONG.player2));
		}
		if (FlxG.keys.justPressed.SIX)
		{
			if (useVideo)
			{
				GlobalVideo.get().stop();
				remove(videoSprite);
				FlxG.stage.window.onFocusOut.remove(focusOut);
				FlxG.stage.window.onFocusIn.remove(focusIn);
				removedVideo = true;
			}
			#if windows
			DiscordClient.changePresence("Char Editor", SONG.player1, null, true);
			#end
			FlxG.switchState(new debug.AnimationDebug(SONG.player1));
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		if (health > 2)
			health = 2;

		var daFloat = floatBeat % 1;
		if (floatBeat < 0)
			daFloat = 1 + daFloat;
		var iconScale = FlxMath.lerp(180, 150, daFloat);
		iconP1.setGraphicSize(Std.int(iconScale));
		iconP2.setGraphicSize(Std.int(iconScale));
		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		songPosBar.percent = Conductor.songPosition / songLength;
		healthBar.percent = health / 2;
		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent * 100, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent * 100, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);
		iconP1.y = iconP2.y = healthBar.y + healthBar.height / 2 - iconP2.height / 2;

		if (healthBar.percent < 0.2)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 0.8)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		if (FlxG.keys.justPressed.FIVE)
		{
			if (useVideo)
			{
				GlobalVideo.get().stop();
				remove(videoSprite);
				FlxG.stage.window.onFocusOut.remove(focusOut);
				FlxG.stage.window.onFocusIn.remove(focusIn);
				removedVideo = true;
			}

			FlxG.switchState(new debug.AnimationDebug(SONG.player2));
		}

		if (FlxG.keys.justPressed.SIX)
			FlxG.switchState(new debug.AnimationDebug(SONG.player1));

		if (startingSong) {
			if (startedCountdown && Conductor.songPosition >= 0)
					startSong();
		} else {
			if (!paused) {
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition) {
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			// Make sure Girlfriend cheers only for certain songs
			if (allowedToHeadbang)
			{
				// Don't animate GF if something else is already animating her (eg. train passing)
				if (gf.animation.curAnim.name == 'danceLeft'
					|| gf.animation.curAnim.name == 'danceRight'
					|| gf.animation.curAnim.name == 'idle')
				{
					// Per song treatment since some songs will only have the 'Hey' at certain times
					switch (curSong)
					{
						case 'Philly Nice':
							{
								// General duration of the song
								if (curBeat < 250)
								{
									// Beats to skip or to stop GF from cheering
									if (curBeat != 184 && curBeat != 216)
									{
										if (curBeat % 16 == 8)
										{
											// Just a garantee that it'll trigger just once
											if (!triggeredAlready)
											{
												gf.playAnim('cheer');
												triggeredAlready = true;
											}
										}
										else
											triggeredAlready = false;
									}
								}
							}
						case 'Bopeebo':
							{
								// Where it starts || where it ends
								if (curBeat > 5 && curBeat < 130)
								{
									if (curBeat % 8 == 7)
									{
										if (!triggeredAlready)
										{
											gf.playAnim('cheer');
											triggeredAlready = true;
										}
									}
									else
										triggeredAlready = false;
								}
							}
						case 'Blammed':
							{
								if (curBeat > 30 && curBeat < 190)
								{
									if (curBeat < 90 || curBeat > 128)
									{
										if (curBeat % 4 == 2)
										{
											if (!triggeredAlready)
											{
												gf.playAnim('cheer');
												triggeredAlready = true;
											}
										}
										else
											triggeredAlready = false;
									}
								}
							}
						case 'Cocoa':
							{
								if (curBeat < 170)
								{
									if (curBeat < 65 || curBeat > 130 && curBeat < 145)
									{
										if (curBeat % 16 == 15)
										{
											if (!triggeredAlready)
											{
												gf.playAnim('cheer');
												triggeredAlready = true;
											}
										}
										else
											triggeredAlready = false;
									}
								}
							}
						case 'Eggnog':
							{
								if (curBeat > 10 && curBeat != 111 && curBeat < 220)
								{
									if (curBeat % 8 == 7)
									{
										if (!triggeredAlready)
										{
											gf.playAnim('cheer');
											triggeredAlready = true;
										}
									}
									else
										triggeredAlready = false;
								}
							}
					}
				}
			}

			if (!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection) {
				var dadMidpoint = dad.getMidpoint();

				camFollow.setPosition(
					dadMidpoint.x + 150 + camOffsets.dadCamX + dad.data.offsets.camX,
					dadMidpoint.y - 100 + camOffsets.dadCamY + dad.data.offsets.camY
				);

				@:privateAccess if (vocals != null && vocals._transform != null)
					vocals.volume = 1;
				dadMidpoint.put();
			} else {
				var bfMidpoint = boyfriend.getMidpoint();

				camFollow.setPosition(
					bfMidpoint.x - 100 + camOffsets.bfCamX + boyfriend.data.offsets.camX,
					bfMidpoint.y - 100 + camOffsets.bfCamY + boyfriend.data.offsets.camY
				);

				bfMidpoint.put();
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					@:privateAccess if (vocals != null && vocals._transform != null)
						vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}

		if (health <= 0 || (FlxG.save.data.resetButton && controls.RESET))
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, deadChr, deadSFX, deadMus, deadEnd));

			#if windows
			// Game Over doesn't get his own variable because it's only used here
			var discordText:String = 'GAME OVER -- ${SONG.song} ($storyDifficulty) ${Ratings.GenerateLetterRank(accuracy)}';
			var discordText2:String = '\nAcc: ${HelperFunctions.truncateFloat(accuracy, 2)}% | Score: $songScore | Misses: $misses';
			DiscordClient.changePresence(discordText, discordText2, iconRPC);
			#end

			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 3500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				// instead of doing stupid y > FlxG.height
				// we be men and actually calculate the time :)

				//and i'll make it not have an if statement. :|
				daNote.active = daNote.visible = (!daNote.tooLate);

				var strum = (daNote.mustPress) ? playerStrums[Std.int(Math.abs(daNote.noteData))] : cpuStrums[Std.int(Math.abs(daNote.noteData))];
				var songSpeed = PlayStateChangeables.scrollSpeed == 1 ? SONG.speed : PlayStateChangeables.scrollSpeed;
				var distance = (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(songSpeed, 2));
				//Big if statements lol
				var opponentCanHit = daNote.strumTime > Conductor.songPosition - (Conductor.safeZoneOffset * 1.5) && daNote.strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.5);
				var wasHit = (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)) || (daNote.hitByBot || (daNote.prevNote.hitByBot && !opponentCanHit));
				var canClip = (daNote.isSustainNote
					&& daNote.y + daNote.offset.y <= strumLine.y + Note.swagWidth / 2
					&& wasHit);

				if (PlayStateChangeables.useDownscroll) {
					daNote.y = (strum.y + distance);

					if (daNote.isSustainNote) {
						distance = (Conductor.songPosition - (daNote.strumTime - Conductor.stepCrochet / 2)) * (0.45 * FlxMath.roundDecimal(songSpeed, 2));
						daNote.y = (strum.y + distance);

						if (daNote.animation.curAnim != null && daNote.animation.curAnim.name == "tail") {
							var normNoteScale = daNote.scale.x * Conductor.stepCrochet / 100 * 1.5 * songSpeed;
							daNote.y += daNote.frameHeight * normNoteScale - daNote.height;
						}

						if (canClip) {
							// Clip to strumline
							var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
							swagRect.height = (strum.y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
				} else {
					daNote.y = (strum.y - distance);
					if (daNote.isSustainNote) {
						distance = (Conductor.songPosition - (daNote.strumTime - Conductor.stepCrochet / 2)) * (0.45 * FlxMath.roundDecimal(songSpeed, 2));
						daNote.y = (strum.y - distance);

						if (canClip) {
							// Clip to strumline
							var swagRect = new FlxRect(0, strum.y + Note.swagWidth / 2 - daNote.y, daNote.width * 2, daNote.height * 2);
							swagRect.y /= daNote.scale.y;
							swagRect.height -= swagRect.y;
			
							daNote.clipRect = swagRect;
						}
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit) {
					scripts_call("enemySing", [daNote]);

					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";

					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					if (!daNote.hitByBot) {
						var singAnims = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
						dad.playAnim(singAnims[daNote.noteData] + altAnim, true);
						dad.holdTimer = 0;

						if (FlxG.save.data.cpuStrums) {
							var spr = cpuStrums[daNote.noteData];
							spr.animation.play('confirm', true);
							if (!curStage.startsWith("school")) {
								spr.centerOffsets();
								spr.offset.x -= 13;
								spr.offset.y -= 13;
							}
						}
					}
					daNote.hitByBot = true;

					@:privateAccess if (SONG.needsVoices && vocals != null && vocals._transform != null)
						vocals.volume = 1;

					daNote.active = false;

					if (!daNote.isSustainNote) {
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}

				daNote.visible = strum.visible;
				daNote.x = strum.x;
				if (!daNote.isSustainNote)
					daNote.angle = strum.angle;
				daNote.alpha = strum.alpha;

				if (daNote.isSustainNote)
					daNote.x += daNote.width / 2 + 17;

				// trace(daNote.y);
				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				if (daNote.isSustainNote && (!daNote.mustPress || PlayStateChangeables.botPlay) && daNote.strumTime < Conductor.songPosition - Conductor.safeZoneOffset * Conductor.timeScale) {
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				if (daNote.mustPress && daNote.tooLate) {
					if (daNote.isSustainNote && daNote.wasGoodHit) {
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					} else {
						if (loadRep && daNote.isSustainNote)
						{
							// im tired and lazy this sucks I know i'm dumb
							if (findByTime(daNote.strumTime) != null)
								totalNotesHit += 1;
							else
							{
								health -= 0.025;
								@:privateAccess if (vocals != null && vocals._transform != null)
									vocals.volume = 0;
								if (theFunne)
									noteMiss(daNote.noteData, daNote);
							}
						}
						else
						{
							health -= 0.025;
							@:privateAccess if (vocals != null && vocals._transform != null)
								vocals.volume = 0;
							if (theFunne)
								noteMiss(daNote.noteData, daNote);
						}
					}

					daNote.visible = false;
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				if (daNote.strumTime < Conductor.songPosition - Conductor.safeZoneOffset * Conductor.timeScale) { //Delete notes that have possibly gotten too far without deletion.
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		if (FlxG.save.data.cpuStrums) {
			for (spr in cpuStrums) {
				if (spr.animation.finished) {
					spr.animation.play('static');
					spr.centerOffsets();
				}
			}
		}

		currentTimingShown.alpha = Math.max(currentTimingShown.alpha - 0.02, 0);

		if (!inCutscene)
			keyShit();

		if (FlxG.keys.justPressed.ONE)
			endSong();

		if (FlxG.keys.justPressed.TWO)
			FlxG.resetState();
		if (FlxG.keys.justPressed.THREE)
			FlxG.updateFramerate = 10;

		scripts_call("updatePost", [elapsed]);
	}

	function endSong():Void
	{
		if (useVideo)
		{
			GlobalVideo.get().stop();
			FlxG.stage.window.onFocusOut.remove(focusOut);
			FlxG.stage.window.onFocusIn.remove(focusIn);
			PlayState.instance.remove(PlayState.instance.videoSprite);
		}

		if (isStoryMode)
			campaignMisses = misses;

		if (!loadRep)
			rep.SaveReplay(saveNotes);
		else
		{
			PlayStateChangeables.botPlay = false;
			PlayStateChangeables.scrollSpeed = 1;
			PlayStateChangeables.useDownscroll = false;
		}

		if (FlxG.save.data.fpsCap > 290)
			(cast(Lib.current.getChildAt(0), Main)).setFPSCap(290);

		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		FlxG.sound.music.pause();
		vocals.pause();
		if (SONG.validScore)
		{
			// adjusting the highscore song name to be compatible
			// would read original scores if we didn't change packages
			var songHighscore = StringTools.replace(PlayState.SONG.song, " ", "-");
			switch (songHighscore)
			{
				case 'Dad-Battle':
					songHighscore = 'Dadbattle';
				case 'Philly-Nice':
					songHighscore = 'Philly';
			}

			#if !switch
			Highscore.saveScore(songHighscore, Math.round(songScore), storyDifficulty);
			Highscore.saveCombo(songHighscore, Ratings.GenerateLetterRank(accuracy), storyDifficulty);
			#end
		}

		if (offsetTesting)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			offsetTesting = false;
			LoadingState.loadAndSwitchState(new OptionsMenu());
			FlxG.save.data.offset = offsetTest;
		}
		else
		{
			if (isStoryMode)
			{
				campaignScore += Math.round(songScore);

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					transIn = FlxTransitionableState.defaultTransIn;
					transOut = FlxTransitionableState.defaultTransOut;

					paused = true;

					FlxG.sound.music.stop();
					vocals.stop();
					if (FlxG.save.data.scoreScreen)
						openSubState(new ResultsScreen());
					else
					{
						FlxG.sound.playMusic(Paths.music('freakyMenu'));
						FlxG.switchState(new MainMenuState());
					}

					// StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

					if (SONG.validScore)
					{
						Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
					}

					// FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
					FlxG.save.flush();
				}
				else
				{
					// adjusting the song name to be compatible
					var songFormat = StringTools.replace(PlayState.storyPlaylist[0], " ", "-");
					switch (songFormat)
					{
						case 'Dad-Battle':
							songFormat = 'Dadbattle';
						case 'Philly-Nice':
							songFormat = 'Philly';
					}

					if (StringTools.replace(PlayState.storyPlaylist[0], " ", "-").toLowerCase() == 'eggnog')
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					PlayState.SONG = Song.loadFromJson(storyDifficultyText.toLowerCase(), PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					openSubState(new funkin.PreloadingSubState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');

				paused = true;

				FlxG.sound.music.stop();
				vocals.stop();

				if (FlxG.save.data.scoreScreen)
					openSubState(new ResultsScreen());
				else
					FlxG.switchState(new FreeplayState());
			}
		}
	}

	var endingSong:Bool = false;

	var hits:Array<Float> = [];
	var offsetTest:Float = 0;

	private function popUpScore(daNote:Note):Void
	{
		var noteDiff:Float = -(daNote.strumTime - Conductor.songPosition);
		var wife:Float = EtternaFunctions.wife3(-noteDiff, Conductor.timeScale);
		// boyfriend.playAnim('hey');
		@:privateAccess if (vocals != null && vocals._transform != null)
			vocals.volume = 1;
		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		coolText.y -= 350;
		coolText.cameras = [camHUD];
		//

		var score:Float = 350;

		if (FlxG.save.data.accuracyMod == 1)
			totalNotesHit += wife;

		var daRating = daNote.rating;
		var healthGain:Float = 0;
		var msColor = 0xFFFF0000;

		switch (daRating)
		{
			case 'shit':
				score = -300;
				combo = 0;
				shits++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.25;
			case 'bad':
				daRating = 'bad';
				score = 0;
				bads++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.50;
			case 'good':
				daRating = 'good';
				score = 200;
				goods++;
				healthGain = 0.04;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.75;
				msColor = 0xFF008000;
			case 'sick':
				healthGain = 0.1;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 1;
				sicks++;
				msColor = 0xFF00FFFF;
		}
		health = Math.min(health + healthGain, 2);

		// trace('Wife accuracy loss: ' + wife + ' | Rating: ' + daRating + ' | Score: ' + score + ' | Weight: ' + (1 - wife));

		songScore += Math.round(score);
		songScoreDef += Math.round(ConvertScore.convertScore(noteDiff));

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var ratingPrefix:String = "game-side/hitPopups/";
		var ratingSuffix:String = '';

		if (curStage.startsWith('school'))
		{
			ratingPrefix = 'game-side/pixelUI/';
			ratingSuffix = '-pixel';
		}

		var rating:FlxSprite = new FlxSprite(FlxG.save.data.ratingX, FlxG.save.data.ratingY, Paths.image(ratingPrefix + daRating + ratingSuffix));
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var msTiming = HelperFunctions.truncateFloat(noteDiff, 3);
		if (PlayStateChangeables.botPlay && !loadRep)
			msTiming = 0;

		if (loadRep)
			msTiming = HelperFunctions.truncateFloat(findByTime(daNote.strumTime)[3], 3);

		currentTimingShown.alpha = 1;
		currentTimingShown.color = msColor;
		currentTimingShown.text = msTiming + "ms";

		if (msTiming >= 0.03 && offsetTesting)
		{
			// Remove Outliers
			hits.shift();
			hits.shift();
			hits.shift();
			hits.pop();
			hits.pop();
			hits.pop();
			hits.push(msTiming);

			var total = 0.0;

			for (i in hits)
				total += i;

			offsetTest = HelperFunctions.truncateFloat(total / hits.length, 2);
		}

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ratingPrefix + 'combo' + ratingSuffix));
		comboSpr.screenCenter();
		comboSpr.x = rating.x;
		comboSpr.y = rating.y + 100;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		currentTimingShown.x = comboSpr.x + 100;
		currentTimingShown.y = rating.y + 100;
		currentTimingShown.acceleration.y = 600;
		currentTimingShown.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		currentTimingShown.velocity.x += comboSpr.velocity.x;
		if (!PlayStateChangeables.botPlay || loadRep)
			add(rating);

		if (!curStage.startsWith('school'))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		comboSpr.cameras = [camHUD];
		rating.cameras = [camHUD];

		var seperatedScore:Array<Int> = [];

		var comboSplit:Array<String> = (combo + "").split('');

		if (combo > highestCombo)
			highestCombo = combo;

		// make sure we have 3 digits to display (looks weird otherwise lol)
		if (comboSplit.length == 1)
		{
			seperatedScore.push(0);
			seperatedScore.push(0);
		}
		else if (comboSplit.length == 2)
			seperatedScore.push(0);

		for (i in 0...comboSplit.length)
		{
			var str:String = comboSplit[i];
			seperatedScore.push(Std.parseInt(str));
		}

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ratingPrefix + 'num' + Std.int(i) + ratingSuffix));
			numScore.screenCenter();
			numScore.x = rating.x + (43 * daLoop) - 50;
			numScore.y = rating.y + 100;
			numScore.cameras = [camHUD];

			if (!curStage.startsWith('school'))
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001,
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	public function NearlyEquals(value1:Float, value2:Float, unimportantDifference:Float = 10):Bool
	{
		return Math.abs(FlxMath.roundDecimal(value1, 1) - FlxMath.roundDecimal(value2, 1)) < unimportantDifference;
	}

	var upHold:Bool = false;
	var downHold:Bool = false;
	var rightHold:Bool = false;
	var leftHold:Bool = false;

	private function keyShit():Void // I've invested in emma stocks
	{
		// control arrays, order L D R U
		var holdArray:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		var pressArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
		var releaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];

		// Prevent player input if botplay is on
		if (PlayStateChangeables.botPlay)
		{
			holdArray = [false, false, false, false];
			pressArray = [false, false, false, false];
			releaseArray = [false, false, false, false];
		}
		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData])
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<Note> = []; // notes to kill later
			var directionsAccounted:Array<Bool> = [false, false, false, false]; // we don't want to do judgments for more than one presses

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (!directionsAccounted[daNote.noteData])
					{
						if (directionList.contains(daNote.noteData))
						{
							directionsAccounted[daNote.noteData] = true;
							for (coolNote in possibleNotes)
							{
								if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
								{ // if it's the same note twice at < 10ms distance, just delete it
									// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
									dumbNotes.push(daNote);
									break;
								}
								else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
								{ // if daNote is earlier than existing note (coolNote), replace
									possibleNotes.remove(coolNote);
									possibleNotes.push(daNote);
									break;
								}
							}
						}
						else
						{
							possibleNotes.push(daNote);
							directionList.push(daNote.noteData);
						}
					}
				}
			});

			for (note in dumbNotes)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}

			possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

			var dontCheck = false;

			for (i in 0...pressArray.length)
			{
				if (pressArray[i] && !directionList.contains(i))
					dontCheck = true;
			}

			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0 && !dontCheck)
			{
				if (!FlxG.save.data.ghost)
				{
					for (shit in 0...pressArray.length)
					{ // if a direction is hit that shouldn't be
						if (pressArray[shit] && !directionList.contains(shit))
							noteMiss(shit, null);
					}
				}
				for (coolNote in possibleNotes)
				{
					if (pressArray[coolNote.noteData])
					{
						if (mashViolations != 0)
							mashViolations--;
						scoreTxt.color = FlxColor.WHITE;
						goodNoteHit(coolNote);
					}
				}
			}
			else if (!FlxG.save.data.ghost)
			{
				for (shit in 0...pressArray.length)
					if (pressArray[shit])
						noteMiss(shit, null);
			}

			if (dontCheck && possibleNotes.length > 0 && FlxG.save.data.ghost && !PlayStateChangeables.botPlay)
			{
				if (mashViolations > 8)
				{
					trace('mash violations ' + mashViolations);
					scoreTxt.color = FlxColor.RED;
					noteMiss(0, null);
				}
				else
					mashViolations++;
			}
		}

		notes.forEachAlive(function(daNote:Note)
		{
			if (PlayStateChangeables.useDownscroll && daNote.y > strumLine.y || !PlayStateChangeables.useDownscroll && daNote.y < strumLine.y)
			{
				// Force good note hit regardless if it's too late to hit it or not as a fail safe
				if (PlayStateChangeables.botPlay && daNote.canBeHit && daNote.mustPress || PlayStateChangeables.botPlay && daNote.tooLate && daNote.mustPress)
				{
					if (loadRep)
					{
						// trace('ReplayNote ' + tmpRepNote.strumtime + ' | ' + tmpRepNote.direction);
						var n = findByTime(daNote.strumTime);
						if (n != null)
						{
							goodNoteHit(daNote);
							boyfriend.holdTimer = daNote.sustainLength;
						}
					}
					else
					{
						goodNoteHit(daNote);
						boyfriend.holdTimer = daNote.sustainLength;
					}
				}
			}
		});

		for (spr in playerStrums) {
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.animation.play('pressed');
			if (!holdArray[spr.ID])
				spr.animation.play('static');

			if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school'))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		}
	}

	public function findByTime(time:Float):Array<Dynamic>
	{
		for (i in rep.replay.songNotes)
		{
			// trace('checking ' + Math.round(i[0]) + ' against ' + Math.round(time));
			if (i[0] == time)
				return i;
		}
		return null;
	}

	public var fuckingVolume:Float = 1;
	public var useVideo = false;

	public static var webmHandler:WebmHandler;

	public var playingDathing = false;

	public var videoSprite:FlxSprite;

	public function focusOut()
	{
		if (paused)
			return;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
	}

	public function focusIn()
	{
		// nada
	}

	public function backgroundVideo(source:String) // for background videos
	{
		useVideo = true;

		FlxG.stage.window.onFocusOut.add(focusOut);
		FlxG.stage.window.onFocusIn.add(focusIn);

		var ourSource:String = "assets/videos/daWeirdVid/dontDelete.webm";
		WebmPlayer.SKIP_STEP_LIMIT = 90;
		var str1:String = "WEBM SHIT";
		webmHandler = new WebmHandler();
		webmHandler.source(ourSource);
		webmHandler.makePlayer();
		webmHandler.webm.name = str1;

		GlobalVideo.setWebm(webmHandler);

		GlobalVideo.get().source(source);
		GlobalVideo.get().clearPause();
		if (GlobalVideo.isWebm)
		{
			GlobalVideo.get().updatePlayer();
		}
		GlobalVideo.get().show();

		if (GlobalVideo.isWebm)
		{
			GlobalVideo.get().restart();
		}
		else
		{
			GlobalVideo.get().play();
		}

		var data = webmHandler.webm.bitmapData;

		videoSprite = new FlxSprite(-470, -30).loadGraphic(data);

		videoSprite.setGraphicSize(Std.int(videoSprite.width * 1.2));

		remove(gf);
		remove(boyfriend);
		remove(dad);
		add(videoSprite);
		add(gf);
		add(boyfriend);
		add(dad);

		if (!songStarted)
			webmHandler.pause();
		else
			webmHandler.resume();
	}

	function noteMiss(direction:Int = 1, daNote:Note):Void
	{
		if (boyfriend.stunned) return;

		if (daNote != null)
			scripts_call("playerNoteMiss", [daNote]);
		else
			scripts_call("ghostMiss", [direction]);
		scripts_call("playerMiss", [direction, daNote]);

		health -= 0.04;
		if (combo > 5 && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');

		combo = 0;
		misses++;

		if (!loadRep) {
			var missTime:Float = (daNote != null) ? daNote.strumTime : Conductor.songPosition;
			saveNotes.push([
				missTime,
				0,
				direction,
				166 * Math.floor((PlayState.rep.replay.sf / 60) * 1000) / 166
			]);
		}

		// var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition);
		// var wife:Float = EtternaFunctions.wife3(noteDiff, FlxG.save.data.etternaMode ? 1 : 1.7);

		if (FlxG.save.data.accuracyMod == 1)
			totalNotesHit -= 1;

		songScore -= 10;

		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
		// FlxG.log.add('played imss note');

		var missAnims = ["singLEFTmiss", "singDOWNmiss", "singUPmiss", "singRIGHTmiss"];
		boyfriend.playAnim(missAnims[direction], true);

		updateAccuracy();
	}

	function updateAccuracy()
	{
		totalPlayed += 1;
		accuracy = Math.max(0, totalNotesHit / totalPlayed * 100);
		accuracyDefault = Math.max(0, totalNotesHitDefault / totalPlayed * 100);
	}

	function getKeyPresses(note:Note):Int
	{
		var possibleNotes:Array<Note> = []; // copypasted but you already know that

		notes.forEachAlive(function(daNote:Note)
		{
			if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
			{
				possibleNotes.push(daNote);
				possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
			}
		});
		if (possibleNotes.length == 1)
			return possibleNotes.length + 1;
		return possibleNotes.length;
	}

	var mashing:Int = 0;
	var mashViolations:Int = 0;

	var etternaModeScore:Int = 0;

	function noteCheck(controlArray:Array<Bool>, note:Note):Void // sorry lol
	{
		var noteDiff:Float = -(note.strumTime - Conductor.songPosition);
		note.rating = Ratings.CalculateRating(noteDiff, Math.floor((PlayStateChangeables.safeFrames / 60) * 1000));
		if (controlArray[note.noteData])
			goodNoteHit(note, (mashing > getKeyPresses(note)));
	}

	function goodNoteHit(note:Note, resetMashViolation = true):Void
	{
		if (mashing != 0)
			mashing = 0;

		var noteDiff:Float = -(note.strumTime - Conductor.songPosition);

		if (loadRep)
			noteDiff = findByTime(note.strumTime)[3];

		note.rating = Ratings.CalculateRating(noteDiff);

		if (note.rating == "miss")
			return;

		// add newest note to front of notesHitArray
		// the oldest notes are at the end and are removed first
		if (!note.isSustainNote)
			notesHitArray.unshift(Date.now());

		if (!resetMashViolation && mashViolations >= 1)
			mashViolations--;

		if (mashViolations < 0)
			mashViolations = 0;

		if (!note.wasGoodHit) {
			scripts_call('playerSing', [note]);

			if (!note.isSustainNote)
			{
				popUpScore(note);
				combo += 1;
			}
			else
				totalNotesHit += 1;

			var singAnims = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
			boyfriend.playAnim(singAnims[note.noteData], true);

			if (!loadRep && note.mustPress)
			{
				var array = [note.strumTime, note.sustainLength, note.noteData, noteDiff];
				if (note.isSustainNote)
					array[1] = -1;
				saveNotes.push(array);
			}

			playerStrums[note.noteData].animation.play('confirm', true);

			note.wasGoodHit = true;
			@:privateAccess if (vocals != null && vocals._transform != null)
				vocals.volume = 1;

			if (!note.isSustainNote){
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}

			updateAccuracy();

			if (PlayStateChangeables.PsychUI && !note.isSustainNote)
				scoreTxt.scale.set(1.075, 1.075);
		}
	}

	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
			resyncVocals();

		// yes this updates every step.
		// yes this is bad
		// but i'm doing it to update misses and accuracy
		#if windows
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		//hello i am srt and i neatened discord text
		var discordText:String = ' ${SONG.song} ($storyDifficultyText) ${Ratings.GenerateLetterRank(accuracy)}';
		var discordText2:String = 'Acc: ${HelperFunctions.truncateFloat(accuracy, 2)}% | Score: $songScore | Misses: $misses';
		DiscordClient.changePresence(detailsText + discordText, discordText2, iconRPC, true, songLength - Conductor.songPosition);
		#end

		scripts_call("stepHit");
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
			notes.sort(FlxSort.byY, (PlayStateChangeables.useDownscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING));

		if (SONG.notes[Math.floor(curStep / 16)] != null && SONG.notes[Math.floor(curStep / 16)].changeBPM)	{
			Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
			FlxG.log.add('CHANGED BPM!');
		}

		if (FlxG.save.data.camzoom)
		{
			// HARDCODING FOR MILF ZOOMS!
			if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
			{
				FlxG.camera.zoom += 0.015;
				camHUD.zoom += 0.03;
			}
		}

		if (curBeat % gfSpeed == 0)
			gf.dance();
		dad.dance();
		boyfriend.dance();

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);
		}

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}

		scripts_call("beatHit");
	}

	var curLight:Int = 0;

	function scripts_call(name:String, ?params:Array<Dynamic>) {
		for (s in scripts)
			s.callFunc(name, params);
	}
}
