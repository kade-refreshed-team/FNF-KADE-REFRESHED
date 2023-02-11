local lightningStrikeBeat = 0
local lightningOffset = 8

function beatHit()
	if KadeEngineData:getOption("distractions") and FlxG.random:bool(10) and parent.curBeat > lightningStrikeBeat + lightningOffset then
		FlxG.sound:play(Paths:soundRandom('stageSounds/spooky-thunder_', 1, 2))
		parent.stageSprites:get("halloweenBG").animation:play('lightning');

		lightningStrikeBeat = parent.curBeat;
		lightningOffset = FlxG.random:int(8, 24);

		parent.boyfriend:playAnim('scared', true);
		parent.gf:playAnim('scared', true);
	end
end