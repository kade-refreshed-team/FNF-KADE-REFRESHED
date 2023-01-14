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
        var npsTxt:String = (FlxG.save.data.npsDisplay) ? ('NPS: $nps (Max: $maxNPS)' + (!PlayStateChangeables.botPlay || PlayState.loadRep ? " | " : "")) : "";

        var scoreTxt:String = (Conductor.safeFrames != 10) ? 'Score: $score ($scoreDef)' : 'Score: $score';

        var accTxt:String = "| Accuracy: " + ((PlayStateChangeables.botPlay && !PlayState.loadRep) ? "N/A" : '${HelperFunctions.truncateFloat(accuracy, 2)}%');

        var missNAccTxt:String = (FlxG.save.data.accuracyDisplay) ? ' | Combo Breaks: ${PlayState.misses} $accTxt | ${GenerateLetterRank(accuracy)}' : "";

        return '$npsTxt' + ((!PlayStateChangeables.botPlay || PlayState.loadRep) ? '$scoreTxt$missNAccTxt' : "");
        /*return
         (FlxG.save.data.npsDisplay ?																							// NPS Toggle
         "NPS: " + nps + " (Max " + maxNPS + ")" + (!PlayStateChangeables.botPlay || PlayState.loadRep ? " | " : "") : "") +								// 	NPS
         (!PlayStateChangeables.botPlay || PlayState.loadRep ? "Score:" + (Conductor.safeFrames != 10 ? score + " (" + scoreDef + ")" : "" + score) + 		// Score
         (FlxG.save.data.accuracyDisplay ?																						// Accuracy Toggle
         " | Combo Breaks:" + PlayState.misses + 																				// 	Misses/Combo Breaks
         " | Accuracy:" + (PlayStateChangeables.botPlay && !PlayState.loadRep ? "N/A" : HelperFunctions.truncateFloat(accuracy, 2) + " %") +  				// 	Accuracy
         " | " + GenerateLetterRank(accuracy) : "") : "");*/ 																		// 	Letter Rank
    }
    
    //Goddammit Brandon.
    public static function PsychScoreTxt(songScore:Int, misses:Int, accuracy:Float, nps:Int, maxNPS:Int) {
        var ratingStuff:Array<Dynamic> = [
            ["?", (accuracy <= 0)],
            ['You Suck!', (accuracy < 20)],
            ['Shit', (accuracy < 40)],
            ['Bad', (accuracy < 50)],
            ['Bruh', (accuracy < 60)],
            ['Meh', (accuracy < 69)],
            ['Nice', (accuracy < 70)],
            ['Good', (accuracy < 80)],
            ['Great', (accuracy < 90)],
            ['Sick!', (accuracy < 100)],
            ['Perfect!!', (accuracy >= 100)]
        ];
        var daRating:String = "?";
        for (thing in ratingStuff) {
            if (thing[1]) {
                daRating = thing[0];
                break;
            }
        }
        //I dont think this should be here cuz psych ui but ok
        var prefix = (FlxG.save.data.npsDisplay) ? "NPS: " + nps + " (Max " + maxNPS + ") | " : "";
        var daResult = '${prefix}Score: $songScore | Misses: $misses | Rating: $daRating';
        if (daRating != "?") {
            var fcIndex:Int = [
                (PlayState.misses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods == 0),
                (PlayState.misses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods >= 1),
                (PlayState.misses == 0),
                (PlayState.misses < 10),
                true
            ].indexOf(true);
            var fcNames:Array<String> = [
                "PFC",
                "GFC",
                "FC",
                "SDCB",
                "Clear"
            ];
            daResult += ' (${HelperFunctions.truncateFloat(accuracy, 2)}%) - ${fcNames[fcIndex]}';
        }
        return daResult;
    }
}
