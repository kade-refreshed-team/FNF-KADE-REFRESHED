package menus;

import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxG;

import utils.HelperFunctions;
import base.Conductor;
import ui.Alphabet;

typedef RefreshedOption = {
    var name:String;
    var desc:String;

    var ?onLeft:Void->Void;
    var ?onRight:Void->Void;
    var ?onEnter:Void->Void;

    var getValue:Void->{text:String, color:flixel.util.FlxColor};
}

class OptionsMenu extends base.MusicBeatState {
    var catagories:Array<String> = [];
    var options:Array<Array<RefreshedOption>> = [];
    var optGroup:FlxTypedGroup<Alphabet>;
    var initialOptX:Array<Float> = [];
    var curCatagory:Int = 0;
    var curOption:Int = 0;

    var descBG:FlxSprite;
    var valueLabel:FlxText;
    var descTxt:FlxText;

    var selcCataOverlay:FlxSprite;
    var selcCataHover:FlxSprite;

    function regenOpts() {
        for (opt in optGroup.members)
            opt.destroy();
        optGroup.clear();

        for (i in 0...options[curCatagory].length) {
            var opt = new Alphabet(0, FlxG.height * 0.48, options[curCatagory][i].name, true, false, true);
            opt.spacing = 90;
            opt.alpha = 1 - 0.4 * Math.min(i, 1);
            initialOptX.push(opt.x = FlxG.width / 2 - opt.width / 2);
            opt.isMenuItem = opt.centerPos = true;
			opt.targetY = i;
			optGroup.add(opt);
        }

        updateLabel();
    }

    override public function create() {
        super.create();
        makeOptions();

        FlxG.mouse.visible = true;

        var bg = new FlxSprite(0, 0, Paths.image("menu-side/menuBGMagenta"));
        add(bg);

        optGroup = new FlxTypedGroup<Alphabet>();
        optGroup.active = false; //Updating this with tryUpdate so it can move in substates.
        add(optGroup);

        descBG = new FlxSprite(0, 480).makeGraphic(FlxG.width, 1, 0x80000000);
        add(descBG);

        valueLabel = new FlxText(0, 480, FlxG.width, "< Enabled >", 32);
        valueLabel.setFormat(Paths.font("vcr.ttf"), 32, 0xFFFFFFFF, CENTER, OUTLINE, 0xFF000000);
        add(valueLabel);

        descTxt = new FlxText(0, 480 + valueLabel.height, FlxG.width, "Description Text", 16);
        descTxt.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, CENTER);
        add(descTxt);

        var topBar = new FlxSprite().makeGraphic(FlxG.width, 40, 0x80000000);
        topBar.active = false;
        add(topBar);

        var cataWidth = Std.int(FlxG.width / catagories.length);
        selcCataOverlay = new FlxSprite().makeGraphic(cataWidth, 40, 0x90FFFFFF);
        selcCataOverlay.active = false;
        add(selcCataOverlay);

        selcCataHover = new FlxSprite().makeGraphic(cataWidth, 40, 0x9000FF80);
        selcCataHover.visible = selcCataOverlay.active = false;
        add(selcCataHover);

        for (i=>cata in catagories) {
            var txt = new FlxText(0 + cataWidth * i, 3, cataWidth, cata, 32);
            txt.setFormat(Paths.font("vcr.ttf"), 32, 0xFFFFFFFF, CENTER);
            txt.active = false;
            add(txt);
        }

        regenOpts();
    }

    function updateLabel() {
        var optValue = options[curCatagory][curOption].getValue();
        valueLabel.text = '< ${optValue.text} >';
        valueLabel.color = optValue.color;
        descTxt.y = 480 + valueLabel.height;
        descTxt.text = "[Clicking tabs or [TAB]] - Switch Catagories\n\n" + options[curCatagory][curOption].desc;
        descBG.scale.y = valueLabel.height + descTxt.height + 10;
        descBG.y = 480 + (valueLabel.height + descTxt.height) / 2;
    }

    override public function tryUpdate(elapsed:Float) {
        super.tryUpdate(elapsed);
        if (!overridden)
            optGroup.update(elapsed);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.BACK) {
            FlxG.switchState(new menus.MainMenuState());
            FlxG.mouse.visible = false;
            return;
        }

        if (controls.UP_P || controls.DOWN_P) {
            var inc = (controls.UP_P) ? -1 : 1;
            curOption = (curOption + options[curCatagory].length + inc) % options[curCatagory].length;

            updateLabel();

            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            for (bullShit => item in optGroup.members) {
                item.targetY = bullShit - curOption;
        
                // nah we dont got if statements
                item.alpha = 1 - 0.4 * Math.min(Math.abs(item.targetY), 1);
            }
        }

        if (((FlxG.keys.pressed.SHIFT && controls.LEFT) || controls.LEFT_P) && options[curCatagory][curOption].onLeft != null) {
            if (controls.LEFT_P)
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            options[curCatagory][curOption].onLeft();
            optGroup.members[curOption].x = (FlxG.keys.pressed.SHIFT) ? initialOptX[curOption] - 75 : initialOptX[curOption] - 50;

            updateLabel();
        } else if (((FlxG.keys.pressed.SHIFT && controls.RIGHT) || controls.RIGHT_P) && options[curCatagory][curOption].onRight != null) {
            if (controls.RIGHT_P)
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            options[curCatagory][curOption].onRight();
            optGroup.members[curOption].x = (FlxG.keys.pressed.SHIFT) ? initialOptX[curOption] + 75 : initialOptX[curOption] + 50;

            updateLabel();
        } else if (controls.ACCEPT && options[curCatagory][curOption].onEnter != null) {
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            options[curCatagory][curOption].onEnter();
            optGroup.members[curOption].y += 50;

            updateLabel();
        }

        selcCataHover.visible = (FlxG.mouse.screenY <= 40);
        selcCataHover.x = FlxG.mouse.screenX - (FlxG.mouse.screenX % (FlxG.width / catagories.length));
        var selctedCata = Std.int(selcCataHover.x / (FlxG.width / catagories.length));
        if (FlxG.mouse.justPressed && selcCataHover.visible && curCatagory != selctedCata) {
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            curOption = 0;
            curCatagory = selctedCata;
            selcCataOverlay.x = selcCataHover.x;
            regenOpts();
        } else if (FlxG.keys.justPressed.TAB) {
            curCatagory = (curCatagory + catagories.length + 1) % catagories.length;
            selcCataOverlay.x = FlxG.width / catagories.length * curCatagory;
            regenOpts();
        }
    }




    //Option Adding (Adds a lot of lines so at the bottom)
    function toggleValue(jsonField:String)
        Reflect.setField(FlxG.save.data, jsonField, !(Reflect.field(FlxG.save.data, jsonField)));

    function incrementValue(jsonField:String, increment:Float, ?min:Float = -9999, ?max:Float = 9999) {
        var value = Reflect.field(FlxG.save.data, jsonField);
        value = Math.round((value + increment) * 10) / 10;
        value = Math.max(Math.min(value, max), min);
        Reflect.setField(FlxG.save.data, jsonField, value);
    }

    function makeBoolOption(name:String, desc:String, jsonField:String):RefreshedOption {
        return {
            name: name,
            desc: desc,
            onLeft: () -> {toggleValue(jsonField);},
            onRight: () -> {toggleValue(jsonField);},
            onEnter: () -> {toggleValue(jsonField);},
            getValue: () -> {return (Reflect.field(FlxG.save.data, jsonField)) ? {text: "Enabled", color: 0xFF00FF80} : {text: "Disabled", color: 0xFFFF0040};}
        };
    }

    function makeOptions() {
        catagories = ["Gameplay", "Apperance", "Misc"];
        var regOptions:Array<Array<RefreshedOption>> = [
            [
                {
                    name: "Keybinds",
                    desc: "Modify the keybinds used for LEFT, DOWN, UP, and RIGHT.",
                    onEnter: function() {
                        FlxG.state.persistentUpdate = false;
                        FlxG.state.openSubState(new menus.KeyBindMenu());
                    },
                    getValue: () -> {return {text: "Modify Keybinds", color: 0xFFFFFFFF};}
                },
                {
                    name: "Note Offset",
                    desc: "Delay the notes position in the chart. (Higher = Later)",
                    onLeft: () -> {incrementValue("offset", -0.1, -999, 999);},
                    onRight: () -> {incrementValue("offset", 0.1, -999, 999);},
                    getValue: () -> {return {text: FlxG.save.data.offset, color: 0xFFFFFFFF};}
                },
                makeBoolOption("Downscroll", "Make the notes move down instead of up.", "downscroll"),
                makeBoolOption("Ghost Tapping", "Allow being able to press a key when a note is non-existent and not lose health.", "ghost"),
                {
                    name: "Safe Frames",
                    desc: "Change the variable used for hit windows.",
                    onLeft: () -> {incrementValue("frames", -1, 1, 20); base.Conductor.recalculateTimings();},
                    onRight: () -> {incrementValue("frames", 1, 1, 20); base.Conductor.recalculateTimings();},
                    getValue: () -> {
                        return {
                            text: 'Sick: ${HelperFunctions.truncateFloat(45 * Conductor.timeScale, 0)} || Good: ${HelperFunctions.truncateFloat(135 * Conductor.timeScale, 0)} || '
                                + 'Bad: ${HelperFunctions.truncateFloat(155 * Conductor.timeScale, 0)} || Shit: ${HelperFunctions.truncateFloat(Conductor.safeZoneOffset, 0)}', 
                            color: flixel.util.FlxColor.interpolate(0xFFFF0040, 0xFF00FF80, FlxG.save.data.frames / 20)
                        }
                    }
                },
                #if desktop
                {
                    name: "FPS Cap",
                    desc: "Increase the amount of frames you can have.",
                    onLeft: () -> {incrementValue("fpsCap", -10, 60, 500); (cast (openfl.Lib.current.getChildAt(0), base.Main)).setFPSCap(FlxG.save.data.fpsCap);},
                    onRight: () -> {incrementValue("fpsCap", 10, 60, 500); (cast (openfl.Lib.current.getChildAt(0), base.Main)).setFPSCap(FlxG.save.data.fpsCap);},
                    getValue: () -> {return {text: '${FlxG.save.data.fpsCap} FPS', color: 0xFFFFFFFF};}
                },
                #end
                {
                    name: "Custom Scroll Speed",
                    desc: "Change how fast the arrows move. (1 = Chart dependent)",
                    onLeft: () -> {incrementValue("scrollSpeed", -0.1, 1, 4);},
                    onRight: () -> {incrementValue("scrollSpeed", 0.1, 1, 4);},
                    getValue: () -> {return {text: FlxG.save.data.scrollSpeed, color: 0xFFFFFFFF};}
                },
                {
                    name: "Accuracy Calculation",
                    desc: "Change how the accuray is calcuated.",
                    onLeft: () -> {FlxG.save.data.accuracyMod = 1 - FlxG.save.data.accuracyMod;},
                    onRight: () -> {FlxG.save.data.accuracyMod = 1 - FlxG.save.data.accuracyMod;},
                    onEnter: () -> {FlxG.save.data.accuracyMod = 1 - FlxG.save.data.accuracyMod;},
                    getValue: () -> {return {text: (FlxG.save.data.accuracyMod == 0 ? "Rating Based" : "Milisecond Based"), color: 0xFFFFFFFF};}
                },
                makeBoolOption("Reset Key", "Allow being able to insta fail by pressing your kill bind. (Normally R)", "resetButton"),
                {
                    name: "Customize Gameplay",
                    desc: "Change the position the ratings pop up at.",
                    onEnter: () -> {
                        FlxG.state.persistentUpdate = false;
                        FlxG.state.openSubState(new menus.RatingPosMenu());
                    },
                    getValue: () -> {return {text: "Move Ratings", color: 0xFFFFFFFF};}
                }
            ],
            [
                makeBoolOption("Flashing Lights", "Toggles flashing lights **that can cause epileptic seizures and strain.**", "flashing"),
                makeBoolOption("Distractions", "Toggles stage distractions that can hinder your gameplay.", "distractions"),
                #if desktop
                {
                    name: "FPS Counter",
                    desc: "Shows the counter for how many frames per second you have.",
                    onLeft: () -> {FlxG.save.data.fps = !FlxG.save.data.fps; (cast (openfl.Lib.current.getChildAt(0), base.Main)).toggleFPS(FlxG.save.data.fps);},
                    onRight: () -> {FlxG.save.data.fps = !FlxG.save.data.fps;(cast (openfl.Lib.current.getChildAt(0), base.Main)).toggleFPS(FlxG.save.data.fps);},
                    onEnter: () -> {FlxG.save.data.fps = !FlxG.save.data.fps; (cast (openfl.Lib.current.getChildAt(0), base.Main)).toggleFPS(FlxG.save.data.fps);},
                    getValue: () -> {return (FlxG.save.data.fps) ? {text: "Enabled", color: 0xFF00FF80} : {text: "Disabled", color: 0xFFFF0040};}
                },
                {
                    name: "Rainbow FPS",
                    desc: "Makes the FPS counter constantly change color.",
                    onLeft: () -> {FlxG.save.data.fpsRain = !FlxG.save.data.fpsRain; (cast (openfl.Lib.current.getChildAt(0), base.Main)).changeFPSColor(0xFFFFFFFF);},
                    onRight: () -> {FlxG.save.data.fpsRain = !FlxG.save.data.fpsRain;(cast (openfl.Lib.current.getChildAt(0), base.Main)).changeFPSColor(0xFFFFFFFF);},
                    onEnter: () -> {FlxG.save.data.fpsRain = !FlxG.save.data.fpsRain; (cast (openfl.Lib.current.getChildAt(0), base.Main)).changeFPSColor(0xFFFFFFFF);},
                    getValue: () -> {return (FlxG.save.data.fpsRain) ? {text: "Enabled", color: 0xFF00FF80} : {text: "Disabled", color: 0xFFFF0040};}
                },
                #end
                makeBoolOption("Misses and Accuracy", "Toggles visibility of misses and accuracy on the score text.", "accuracyDisplay"),
                makeBoolOption("Song Position Bar", "Toggles visibility of the bar that shows your song progress on the top.", "songPosition"),
                makeBoolOption("NPS Counter", "Toggles visibility of notes hit per second on the score text.", "npsDisplay"),
                makeBoolOption("CPU Strum Glow", "Makes the opponent's arrows glow when they're hit.", "cpuStrums"),
                {
                    name: "Watermarks",
                    desc: "Toggles visiblity of watermarks that say that this is Kade Freshed.",
                    onLeft: () -> {base.Main.watermarks = !base.Main.watermarks; FlxG.save.data.watermark = base.Main.watermarks;},
                    onRight: () -> {base.Main.watermarks = !base.Main.watermarks; FlxG.save.data.watermark = base.Main.watermarks;},
                    onEnter: () -> {base.Main.watermarks = !base.Main.watermarks; FlxG.save.data.watermark = base.Main.watermarks;},
                    getValue: () -> {return (FlxG.save.data.watermark) ? {text: "Enabled", color: 0xFF00FF80} : {text: "Disabled", color: 0xFFFF0040};}
                },
                makeBoolOption("Camera Zooms", "Makes the camera zoom in a bit every measure.", "camzoom"),
                makeBoolOption("Psych UI", "Makes the UI similar to the ui of Psych Engine.", "psychui"),
            ],
            [
                #if sys
                {
                    name: "Replay Menu",
                    desc: "Go and select replays of previous plays. (Not fully working.)",
                    onEnter: () -> {FlxG.switchState(new menus.LoadReplayState());},
                    getValue: () -> {return {text: "View Replays", color: 0xFFFFFFFF};}
                },
                #end
                makeBoolOption("Botplay", "Have the songs be automatically played. Useful for showcases. (and skill issue)", "botplay"),
                makeBoolOption("Results Screen", "At the end of a freeplay song or story week, A overlay will appear with results of the gameplay.", "scoreScreen"),
                makeBoolOption("OG Freeplay", "Have the freeplay menu be the regular freeplay menu instead of the Refreshed one.", "ogfreeplay")
            ]
        ];
        script.callFunc("makeOptions", [regOptions]);
        options = regOptions;
    }
}