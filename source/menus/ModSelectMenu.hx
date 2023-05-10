package menus;

import flixel.graphics.FlxGraphic;
import openfl.Assets;
import sys.FileSystem;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;

using StringTools;

class ModSelectMenu extends base.MusicBeatSubstate {
    var modCard:FlxSprite;
    var descText:FlxText;
    var listText:FlxText;

    var curSelected:Int = 0;
    var mods:Array<String> = [];
    var modsEnabled:Map<String, Bool> = [];
    var ogIndexes:Map<String, Int> = [];

    var graphicCache:Map<String, FlxGraphic> = []; //Handling the mod card grapics differently because it would be kinda hard to do it the normal way.
    var defaultModCardGraphic:FlxGraphic;

    var exiting:Bool = false;

    public function new() {
        super();

        var defaultModCardPath:String = Paths.image("menu-side/unknownModCard");
        defaultModCardGraphic = FlxGraphic.fromAssetKey(defaultModCardPath, true, defaultModCardPath, false);

        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);
        FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

        modCard = new FlxSprite(FlxG.width / 2 + 12.5, 0);
        modCard.scrollFactor.set();
        modCard.antialiasing = true;
        add(modCard);

        descText = new FlxText(FlxG.width / 2, 0, FlxG.width / 2, "", 20);
        descText.setFormat("VCR OSD Mono", 20, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
        descText.scrollFactor.set();
        add(descText);

        var titleText = new FlxText(0, 5, FlxG.width, "SELECT MODS", 48);
        titleText.setFormat("VCR OSD Mono", 48, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
        titleText.scrollFactor.set();
        add(titleText);

        var infoText = new FlxText(0, titleText.y + titleText.height + 5, FlxG.width, "[UP/DOWN] - Move Up/Down || [ENTER] - Toggle Mod || [SHIFT] - Hold to reorder mods using [UP/DOWN]", 16);
        infoText.setFormat("VCR OSD Mono", 16, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
        infoText.scrollFactor.set();
        add(infoText);

        listText = new FlxText(0, FlxG.height / 2, FlxG.width / 2, "", 20);
        listText.setFormat("VCR OSD Mono", 20, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
        listText.scrollFactor.set();
        add(listText);

        var queuedMods:Array<String> = []; //The mods that weren't enabled will be added after the directory for loop. Allows for proper ordering.
        for (folder in FileSystem.readDirectory(FileSystem.absolutePath('mods'))) {
            if (!FileSystem.isDirectory(FileSystem.absolutePath('mods/$folder'))) continue;

            var modIndex:Int = Assets.foldersToCheck.indexOf('./mods/$folder');
            modsEnabled.set(folder, (modIndex > -1));

            if (modIndex > -1) {
                ogIndexes.set(folder, modIndex);
                mods.insert(modIndex, folder);
            } else
                queuedMods.push(folder);
        }
        for (queuedMod in queuedMods)
            mods.push(queuedMod);

        regenText();
        listText.y -= listText.height / 2;
    }

    function regenText() {
        listText.text = "";

        for (i => mod in mods) {
            var dynamicText:Array<String> = [
                (modsEnabled[mod]) ? "O" : " ",
                (i == curSelected) ? ">>> " : "",
                (i == curSelected) ? " <<<" : "",
                (i < mods.length - 1) ? "\n" : ""
            ];

            listText.text += '${dynamicText[1]}$mod [${dynamicText[0]}]${dynamicText[2]}${dynamicText[3]}';
        }

        var graphic:FlxGraphic = graphicCache.get(mods[curSelected]);
        if (graphic == null) {
            var modCardPath = FileSystem.absolutePath('mods/${mods[curSelected]}/modCard.png');
            if (FileSystem.exists(modCardPath)) {
                var bitmap = openfl.display.BitmapData.fromFile(modCardPath);
                graphic = FlxGraphic.fromBitmapData(bitmap, true, modCardPath, false);
                graphicCache.set(mods[curSelected], graphic);
            } else
                graphic = defaultModCardGraphic;

            graphicCache.set(mods[curSelected], graphic);
        }
        //Why not just use loadGraphic? Because I don't want to risk it going in flixel's bitmap cache.
        modCard.frames = graphic.imageFrame;
        modCard.setGraphicSize(615, 370);
        modCard.updateHitbox();

        var modDescPath = FileSystem.absolutePath('mods/${mods[curSelected]}/modDescription.txt');
        descText.text = (FileSystem.exists(modDescPath)) ? sys.io.File.getContent(modDescPath).trim() : "";

        var distance:Float = 10;
        var height:Float = modCard.height + distance + ((descText.text.trim() != "") ? descText.height : 0);
        modCard.y = FlxG.height / 2 - height / 2;
        descText.y = modCard.y + modCard.height + distance;
    }

    override public function draw() {
        if (!exiting) super.draw();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.BACK) {
            exiting = true;

            close();

            for (graphic in graphicCache.iterator()) {
                if (graphic != defaultModCardGraphic)
                    graphic.destroy();
            }
            defaultModCardGraphic.destroy();

            var modsChanged:Bool = false;
            var modListContent:String = "";

            for (mod in mods) {
                modsChanged = modsChanged || (
                    (!modsEnabled[mod] && ogIndexes.exists(mod)) ||
                    (modsEnabled[mod] && !ogIndexes.exists(mod)) ||
                    (modsEnabled[mod] && mods.indexOf(mod) != ogIndexes[mod])
                );

                if (modsEnabled[mod])
                    modListContent += mod + "\n";
            }

            if (modsChanged) {
                sys.io.File.saveContent(FileSystem.absolutePath('mods/modList.txt'), modListContent);
                Assets.foldersToCheck = [for (line in utils.CoolUtil.coolStringFile(modListContent)) './mods/$line'];
                Assets.foldersToCheck.push('./assets');

                FlxG.sound.play(Paths.sound('cancelMenu'));
                FlxG.sound.music.stop();
                FlxG.resetState();
            }
            
            return;
        }

        var ogCurSelected:Int = curSelected; //For order movement.

        if (controls.UP_P) {
            curSelected = (curSelected + mods.length - 1) % mods.length;
            
            if (FlxG.keys.pressed.SHIFT) {
                var mod = mods[ogCurSelected];
                mods.splice(ogCurSelected, 1);
                mods.insert(curSelected, mod);
            }
            regenText();

            FlxG.sound.play(Paths.sound('scrollMenu'));
        } else if (controls.DOWN_P) {
            curSelected = (curSelected + mods.length + 1) % mods.length;

            if (FlxG.keys.pressed.SHIFT) {
                var mod = mods[ogCurSelected];
                mods.splice(ogCurSelected, 1);
                mods.insert(curSelected, mod);
            }
            regenText();

            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        if (controls.ACCEPT) {
            modsEnabled[mods[curSelected]] = !modsEnabled[mods[curSelected]];

            regenText();
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }
    }
}