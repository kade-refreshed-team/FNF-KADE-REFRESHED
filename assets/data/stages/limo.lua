local fastCarCanDrive = true
local danceLeft = true
local dancers = {}

function create()
	if KadeEngineData:getOption("distractions") then
		print(parent:memberIndex(parent.gf))
		resetFastCar()

		local limoY = parent.stageSprites:get("bgLimo").y - 400
		for i = 0, 4, 1 do
			local dancer = FlxSprite:new((370 * i) + 130, limoY)
			dancer.scrollFactor:set(0.4, 0.4)
			dancer.frames = Paths:getSparrowAtlas("stages/limo/limoDancer")
			dancer.animation:addByIndices("danceLeft", "bg dancer sketch PINK", {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}, "", 24, false)
			dancer.animation:addByIndices("danceRight", "bg dancer sketch PINK", {15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29}, "", 24, false)
			dancer.animation:play("danceLeft")
			dancer.antialiasing = true
			parent:insert(parent:memberIndex(parent.gf), dancer)
			table.insert(dancers, dancer)
		end
	end
end

function resetFastCar()
	local fastCar = parent.stageSprites:get("fastCar");
	fastCar.x = -12600;
	fastCar.y = FlxG.random.int(140, 250);
	fastCar.velocity.x = 0;
	fastCarCanDrive = true;
end

function beatHit()
	danceLeft = not danceLeft
	local danceAnim = "danceLeft"
	if not danceLeft then
		danceAnim = "danceRight"
	end

	for i, dancer in pairs(dancers) do
		dancer.animation:play(danceAnim)
	end

	if FlxG.random:bool(10) and fastCarCanDrive and KadeEngineData:getOption("distractions") then
		FlxG.sound:play(Paths:soundRandom('stageSounds/limo-carPass', 0, 1), 0.7);

		parent.stageSprites:get("fastCar").velocity.x = (FlxG.random:int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		FlxTimer:new():start(2, resetFastCar);
	end
end