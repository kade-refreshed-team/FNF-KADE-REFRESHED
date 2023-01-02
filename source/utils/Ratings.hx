package utils;

import funkin.PlayStateChangeables;
import funkin.PlayState;
import base.Conductor;

import flixel.FlxG;

class Ratings
{
    public static function GenerateLetterRank(accuracy:Float) // generate a letter ranking
    {
        if (accuracy == 0)
            return "N/A";
		else if(FlxG.save.data.botplay && !PlayState.loadRep)
			return "BotPlay";

        var ranking:String = "N/A";

        var fcIndex:Int = [
            (PlayState.misses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods == 0),
            (PlayState.misses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods >= 1),
            (PlayState.misses == 0),
            (PlayState.misses < 10),
            true
        ].indexOf(true);
        var fcNames:Array<String> = [
            "(MFC)",
            "(GFC)",
            "(FC)",
            "(SDCB)",
            "(Clear)"
        ];
        ranking = fcNames[fcIndex];

        // WIFE TIME :)))) (based on Wife3)

        var wifeConditionIndex:Int = [
            accuracy >= 99.9935, // AAAAA
            accuracy >= 99.980, // AAAA:
            accuracy >= 99.970, // AAAA.
            accuracy >= 99.955, // AAAA
            accuracy >= 99.90, // AAA:
            accuracy >= 99.80, // AAA.
            accuracy >= 99.70, // AAA
            accuracy >= 99, // AA:
            accuracy >= 96.50, // AA.
            accuracy >= 93, // AA
            accuracy >= 90, // A:
            accuracy >= 85, // A.
            accuracy >= 80, // A
            accuracy >= 70, // B
            accuracy >= 60, // C
            accuracy < 60, // D
            accuracy == 0 // N/A
        ].indexOf(true);
        var rankingNames:Array<String> = [
            " AAAAA",
            " AAAA:",
            " AAAA.",
            " AAAA",
            " AAA:",
            " AAA.",
            " AAA",
            " AA:",
            " AA.",
            " AA",
            " A:",
            " A.",
            " A",
            " B",
            " C",
            " D",
            ""
        ];
        ranking += rankingNames[wifeConditionIndex];

        return ranking;
    }
    
    public static function CalculateRating(noteDiff:Float, ?customSafeZone:Float):String // Generate a judgement through some timing shit
    {
        if (FlxG.save.data.botplay && !PlayState.loadRep)
            return "sick"; // FUNNY

        var customTimeScale = Conductor.timeScale;

        if (customSafeZone != null)
            customTimeScale = customSafeZone / 166;

        // trace(customTimeScale + ' vs ' + Conductor.timeScale);

        // I HATE THIS IF CONDITION
        // IF LEMON SEES THIS I'M SORRY :(

        // trace('Hit Info\nDifference: ' + noteDiff + '\nZone: ' + Conductor.safeZoneOffset * 1.5 + "\nTS: " + customTimeScale + "\nLate: " + 155 * customTimeScale);

        var rating = checkRating(noteDiff,customTimeScale);


        return rating;
    }

    public static function checkRating(ms:Float, ts:Float)
    {
        var ratingIndex = [
            (ms < 45 * ts && ms > -45 * ts),
            ((ms < 90 * ts && ms > 45 * ts) || (ms > -90 * ts && ms < -45 * ts)),
            ((ms < 135 * ts && ms > 90 * ts) || (ms > -135 * ts && ms < -90 * ts)),
            ((ms < 166 * ts && ms > 135 * ts) || (ms > -166 * ts && ms < -135 * ts)),
            true,
        ].indexOf(true);
        var ratingNames = [
            "sick",
            "good",
            "bad",
            "shit",
            "miss"
        ];
        return ratingNames[ratingIndex];
    }

    public static function CalculateRanking(score:Int,scoreDef:Int,nps:Int,maxNPS:Int,accuracy:Float):String
    {
        return
         (FlxG.save.data.npsDisplay ?																							// NPS Toggle
         "NPS: " + nps + " (Max " + maxNPS + ")" + (!PlayStateChangeables.botPlay || PlayState.loadRep ? " | " : "") : "") +								// 	NPS
         (!PlayStateChangeables.botPlay || PlayState.loadRep ? "Score:" + (Conductor.safeFrames != 10 ? score + " (" + scoreDef + ")" : "" + score) + 		// Score
         (FlxG.save.data.accuracyDisplay ?																						// Accuracy Toggle
         " | Combo Breaks:" + PlayState.misses + 																				// 	Misses/Combo Breaks
         " | Accuracy:" + (PlayStateChangeables.botPlay && !PlayState.loadRep ? "N/A" : HelperFunctions.truncateFloat(accuracy, 2) + " %") +  				// 	Accuracy
         " | " + GenerateLetterRank(accuracy) : "") : ""); 																		// 	Letter Rank
    }
}
