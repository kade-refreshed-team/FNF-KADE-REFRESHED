package menus;

import settings.Controls.KeyboardScheme;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;

#if windows
import Discord.DiscordClient;
#end

using StringTools;

class MainMenuState extends base.MusicBeatState
{
	var curSelected:Int = 0;

	var modButton:FlxSprite;
	var menuItems:FlxTypedGroup<FlxSprite>;

	#if !switch
	var optionShit:Array<String> = ['story mode', 'freeplay', 'donate', 'options'];
	#else
	var optionShit:Array<String> = ['story mode', 'freeplay'];
	#end

	public static var firstStart:Bool = true;

	public static var lastUpdate:Int = 3; //I wanna do versions diffently.
	public static var updateName:String = "Tweaked Scripting Update (WIP)";
	public static var gameVer:String = "0.2.7.1";

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	public static var finishedFunnyMove:Bool = false;

	override function create() {
		#if windows
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('menu-side/menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.10;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menu-side/menuDesat'));
		magenta.scrollFactor.x = 0;
		magenta.scrollFactor.y = 0.10;
		magenta.setGraphicSize(Std.int(magenta.width * 1.1));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFfd719b;
		add(magenta);
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var tex = Paths.getSparrowAtlas('menu-side/FNF_main_menu_assets');

		for (i in 0...optionShit.length) {
			var menuItem:FlxSprite = new FlxSprite(0, FlxG.height * 1.6);
			menuItem.frames = tex;
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = true;
			if (firstStart)
				FlxTween.tween(menuItem,{y: 60 + (i * 160)},1 + (i * 0.25) ,{ease: FlxEase.expoInOut, onComplete: function(flxTween:FlxTween)  { 
						finishedFunnyMove = true; 
						changeItem();
					}});
			else
				menuItem.y = 60 + (i * 160);
		}

		modButton = new FlxSprite(FlxG.width - 10, FlxG.height - 10, Paths.image("menu-side/KadeRefreshedModSwitch"));
		modButton.scale.scale(0.4);
		modButton.scrollFactor.set();
		modButton.updateHitbox();
		modButton.x -= modButton.width;
		modButton.y -= modButton.height;
		modButton.antialiasing = true;
		add(modButton);

		firstStart = false;

		FlxG.camera.follow(camFollow, null, 0.60 * (60 / FlxG.save.data.fpsCap));

		var versionShit:FlxText = new FlxText(5, FlxG.height - 5, 0, '$gameVer FNF - 1.5.3 Kade Engine\nKade Refreshed - $updateName', 12);
		versionShit.y -= versionShit.height;
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		if (base.Main.watermarks)
			add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float) {
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (!selectedSomethin) {
			modButton.colorTransform.redOffset = 0;
			modButton.colorTransform.greenOffset = 0;
			modButton.colorTransform.blueOffset = 0;
			var overlapsButton = (
				FlxG.mouse.screenX >= modButton.x && FlxG.mouse.screenX <= modButton.x + modButton.width &&
				FlxG.mouse.screenY >= modButton.y && FlxG.mouse.screenY <= modButton.y + modButton.height
			);
			if (overlapsButton) {
				modButton.colorTransform.redOffset = modButton.colorTransform.greenOffset = modButton.colorTransform.blueOffset = (FlxG.mouse.pressed) ? -50 : 40;
				if (FlxG.mouse.justReleased) {
					persistentUpdate = false;
					openSubState(new menus.ModSelectMenu());
				}
			}

			if (controls.UP_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.DOWN_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
				FlxG.switchState(new menus.TitleState());

			if (controls.ACCEPT) {
				if (optionShit[curSelected] == 'donate') {
					fancyOpenURL("https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game");
				} else {
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));
					
					if (FlxG.save.data.flashing)
						FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite) {
						if (curSelected != spr.ID) {
							FlxTween.tween(spr, {alpha: 0}, 1.3, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween) {
									spr.kill();
								}
							});
						} else {
							if (FlxG.save.data.flashing) {
								FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
								{
									goToState();
								});
							} else {
								new FlxTimer().start(1, function(tmr:FlxTimer) {
									goToState();
								});
							}
						}
					});
				}
			}
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite) {
			spr.screenCenter(X);
		});
	}
	
	function goToState() {
		var daChoice:String = optionShit[curSelected];

		switch (daChoice) {
			case 'story mode':
				FlxG.switchState(new menus.StoryMenuState());
				trace("Story Menu Selected");
			case 'freeplay':
				FlxG.switchState(new menus.FreeplayState());

				trace("Freeplay Menu Selected");

			case 'options':
				FlxG.switchState(new menus.OptionsMenu());
		}
	}

	function changeItem(huh:Int = 0) {
		if (finishedFunnyMove)
			curSelected = (curSelected + menuItems.length + huh) % menuItems.length;

		menuItems.forEach(function(spr:FlxSprite) {
			spr.animation.play('idle');

			if (spr.ID == curSelected && finishedFunnyMove) {
				spr.animation.play('selected');
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
			}

			spr.updateHitbox();
		});
	}
}
