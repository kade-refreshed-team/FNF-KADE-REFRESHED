package utils;

import funkin.PlayState;
import flixel.FlxSprite;
import flixel.math.FlxMath;

using StringTools;

class HelperFunctions
{
    public static function truncateFloat( number : Float, precision : Int): Float {
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round( num ) / Math.pow(10, precision);
		return num;
	}

	public static function GCD(a, b) {
		return b == 0 ? FlxMath.absInt(a) : GCD(b, a % b);
	}

	public static function parseStage(path:String, ps:PlayState) {
		var stageSprites:Map<String, flixel.FlxSprite> = [];
		var curSprite:FlxSprite = null;
		for (line in utils.CoolUtil.coolTextFile(path)) {
			var split:Array<String> = line.split(" | ");
			var daVars:Array<String> = [for (v in split[1].split(",")) v.trim()];
			switch (split[0]) {
				case "newSprite":
					curSprite = new FlxSprite(Std.parseFloat(daVars[1]), Std.parseFloat(daVars[2]));
					curSprite.antialiasing = true;
					ps.add(curSprite);
					stageSprites.set(daVars[0], curSprite);

				//Graphic set functions
				case "setGraphic":
					curSprite.loadGraphic(Paths.image(daVars[0]));
				case "setGridFrames":
					curSprite.loadGraphic(Paths.image(daVars[0]), true, Std.parseInt(daVars[1]), Std.parseInt(daVars[2]));
				case "setFrames":
					curSprite.frames = Paths.getSparrowAtlas(daVars[0]);
				case "setPackerFrames":
					curSprite.frames = Paths.getPackerAtlas(daVars[0]);

				//Animation functions
				case "addAnim":
					var animType = daVars[3].toLowerCase();
					curSprite.animation.addByPrefix(daVars[0], daVars[1], Std.parseInt(daVars[2]), (animType == "loop"));
					if (animType == "loop" || animType == "first")
						curSprite.animation.play(daVars[0]);
				case "addIntAnim":
					var animType = daVars[3].toLowerCase();

					var daFrames:Array<Int> = [];
					daVars[1] = daVars[1].substr(1, daVars[1].length - 2); //Remove the brackets. The brackets just make the line neater.
					if (daVars[1].contains("-"))  {
						var daInts:Array<String> = daVars[1].split("-");
						daFrames = utils.CoolUtil.numberArray(
							Std.parseInt(daInts[1].trim()),
							Std.parseInt(daInts[0].trim())
						);
					} else
						daFrames = [for (string in daVars[1].split(":")) Std.parseInt(string.trim())];

					curSprite.animation.add(daVars[0], daFrames, Std.parseInt(daVars[2]), (animType == "loop"));
					if (animType == "loop" || animType == "first")
						curSprite.animation.play(daVars[0]);
				case "addIndiceAnim":
					var animType = daVars[4].toLowerCase();

					var daFrames:Array<Int> = [];
					daVars[2] = daVars[2].substr(1, daVars[1].length - 2); // Remove the brackets. The brackets just make the line neater.
					if (daVars[2].contains("-"))
					{
						var daInts:Array<String> = daVars[2].split("-");
						daFrames = utils.CoolUtil.numberArray(Std.parseInt(daInts[1].trim()), Std.parseInt(daInts[0].trim()));
					}
					else
						daFrames = [for (string in daVars[2].split(":")) Std.parseInt(string.trim())];

					curSprite.animation.addByIndices(daVars[0], daVars[1], daFrames, "", Std.parseInt(daVars[3]), (animType == "loop"));
					if (animType == "loop" || animType == "first")
						curSprite.animation.play(daVars[0]);

				//Sprite var functions
				case "setScale":
					curSprite.scale.set(Std.parseFloat(daVars[0]), Std.parseFloat(daVars[1]));
					if (daVars[2] == "true")
						curSprite.updateHitbox();
				case "setScroll":
					curSprite.scrollFactor.set(Std.parseFloat(daVars[0]), Std.parseFloat(daVars[1]));
				case "setAntialiasing":
					curSprite.antialiasing = (daVars[0] == "true");

				//Character and Camera functions
				case "setZoom":
					ps.defaultCamZoom = Std.parseFloat(daVars[0]);
				case "camOffsets":
					switch (daVars[0]) {
						case "bf" | "boyfriend" | "player":
							ps.camOffsets.bfCamX = Std.parseFloat(daVars[1]);
							ps.camOffsets.bfCamY = Std.parseFloat(daVars[2]);
						case "gf" | "girlfriend" | "specator":
							ps.camOffsets.gfCamX = Std.parseFloat(daVars[1]);
							ps.camOffsets.gfCamY = Std.parseFloat(daVars[2]);
						case "dad" | "opponent":
							ps.camOffsets.dadCamX = Std.parseFloat(daVars[1]);
							ps.camOffsets.dadCamY = Std.parseFloat(daVars[2]);
					}
				case "addChar":
					switch (daVars[0]) {
						case "bf" | "boyfriend" | "player":
							var daX:Float = 0;
							var daY:Float = 0;
							if (daVars[1] == "offsetPos") {
								daX = ps.boyfriend.regX;
								daY = ps.boyfriend.regY;
							}
							ps.boyfriend.regX = daX + Std.parseFloat(daVars[2]);
							ps.boyfriend.regY = daY + Std.parseFloat(daVars[3]);
							ps.add(ps.boyfriend);
						case "gf" | "girlfriend" | "specator":
							var daX:Float = 0;
							var daY:Float = 0;
							if (daVars[1] == "offsetPos") {
								daX = ps.gf.regX;
								daY = ps.gf.regY;
							}
							ps.gf.regX = daX + Std.parseFloat(daVars[2]);
							ps.gf.regY = daY + Std.parseFloat(daVars[3]);
							ps.add(ps.gf);
						case "dad" | "opponent":
							var daX:Float = 0;
							var daY:Float = 0;
							if (daVars[1] == "offsetPos") {
								daX = ps.dad.regX;
								daY = ps.dad.regY;
							}
							ps.dad.regX = daX + Std.parseFloat(daVars[2]);
							ps.dad.regY = daY + Std.parseFloat(daVars[3]);
							ps.add(ps.dad);
					}
			}
		}
		return stageSprites;
	}
}