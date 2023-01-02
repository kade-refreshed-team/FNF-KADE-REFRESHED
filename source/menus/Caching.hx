package menus;

import polymod.Polymod;
import sys.FileSystem;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;

using StringTools;

class Caching extends base.MusicBeatState
{
    var toBeDone = 0;
    var done = 0;
    var lines:Int = 1;

    var text:FlxText;
    var cacheList:FlxText;
    var kadeLogo:FlxSprite;

	override function create()
	{
        FlxG.mouse.visible = false;

        FlxG.worldBounds.set(0,0);

        #if polymod
        polymod.Polymod.init({
            modRoot: "./mods/",
           });

        polymod.Polymod.scan('./mods/');
        #end

        text = new FlxText(FlxG.width / 2, FlxG.height / 2 + 300,0,"Loading...");
        text.size = 34;
        text.alignment = FlxTextAlign.CENTER;
        text.alpha = 0;

        cacheList =  new FlxText(FlxG.width - 425, 5, 420, "Starting Cache...\n");
        cacheList.size = 12;
        cacheList.alignment = "right";

        kadeLogo = new FlxSprite(FlxG.width / 2, FlxG.height / 2).loadGraphic(Paths.image('menu-side/gameStart/KadeEngineLogo'));
        kadeLogo.x -= kadeLogo.width / 2;
        kadeLogo.y -= kadeLogo.height / 2 + 100;
        text.y -= kadeLogo.height / 2 - 125;
        text.x -= 170;
        kadeLogo.setGraphicSize(Std.int(kadeLogo.width * 0.6));

        kadeLogo.alpha = 0;

        add(kadeLogo);
        add(text);
        add(cacheList);
        
        sys.thread.Thread.create(cache);

        super.create();
    }

    var calledDone = false;

    override function update(elapsed) 
    {
        if (toBeDone != 0 && done != toBeDone)
        {
            var alpha = utils.HelperFunctions.truncateFloat(done / toBeDone * 100,2) / 100;
            kadeLogo.alpha = alpha;
            text.alpha = alpha;
            text.text = "Loading... (" + done + "/" + toBeDone + ")";
        }

        super.update(elapsed);
    }


    function cache()
    {

        var images = [];
        var music = [];

        images = [for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/images/game-side/characters")))
            if (i.endsWith(".png"))
                i
        ];
        music = FileSystem.readDirectory(FileSystem.absolutePath("assets/songs"));

        toBeDone = Lambda.count(images) + Lambda.count(music);

        for (i in images) {
            var replaced:String = i.substr(0, i.length - 4);
            FlxG.bitmap.add(Paths.image("game-side/characters/" + replaced));
            addLine(replaced);
            done++;
        }

        for (i in music) {
            FlxG.sound.cache(Paths.inst(i));
            FlxG.sound.cache(Paths.voices(i));
            addLine(i);
            done++;
        }

        cacheList.text = "Finished Caching. Enjoy!";

        FlxG.switchState(new TitleState());
    }

    function addLine(name:String) {
        cacheList.text += 'Cached File: $name\n';
        lines++;
        done++;
        if (lines > 30) {
            var splitList = cacheList.text.split("\n");
            var toSplice = lines - 30;
            splitList = splitList.splice(0, toSplice);
            cacheList.text = splitList.join("\n");
        }
    }

}