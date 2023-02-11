script:import("flixel.system.FlxSound")

local trainMoving = false
local startedMoving = false
local trainFrameTiming = 0
local trainCars = 8
local trainFinishing = false
local trainCooldown = 0
local curLight = 0

local trainSound

function create()
	trainSound = FlxSound:new()
	trainSound:loadEmbedded(Paths:sound('stageSounds/philly-train_passes'))
	FlxG.sound.list:add(trainSound);

	local lightColors = {0x31A2FD, 0x31FD8C, 0xFB33F5, 0xFD4531, 0xFBA633};
	parent.stageSprites:get("light").color = lightColors[FlxG.random:int(1, 5, {curLight})];
end

function update(e)
	if trainMoving then
		trainFrameTiming = trainFrameTiming + e

		if trainFrameTiming >= 1 / 24 then
			if trainSound.time >= 4700 then
				startedMoving = true
				parent.gf:playAnim('hairBlow')
			end

			if startedMoving then
				local phillyTrain = parent.stageSprites:get("phillyTrain")
				phillyTrain.x = phillyTrain.x - 400

				if phillyTrain.x < -2000 and not trainFinishing then
					phillyTrain.x = -1150
					trainCars = trainCars - 1

					if trainCars <= 0 then
						trainFinishing = true
					end
				end

				if phillyTrain.x < -4000 and trainFinishing then
					parent.gf:playAnim('hairFall')
					phillyTrain.x = FlxG.width + 200
					trainMoving = false
					trainCars = 8
					trainFinishing = false
					startedMoving = false
				end
			end

			trainFrameTiming = 0
		end
	end

	local light = parent.stageSprites:get("light")
	light.alpha = light.alpha - e * Conductor.crochet / 500
end

function beatHit()
	if KadeEngineData:getOption("distractions") then
		if not trainMoving then
			trainCooldown = trainCooldown + 1
		end

		if parent.curBeat % 4 == 0 then
			local lightColors = {0x31A2FD, 0x31FD8C, 0xFB33F5, 0xFD4531, 0xFBA633};
			parent.stageSprites:get("light").color = lightColors[FlxG.random:int(1, 5, {curLight})];
			parent.stageSprites:get("light").alpha = 1
		end
	end

	if parent.curBeat % 8 == 4 and FlxG.random:bool(30) and not trainMoving and trainCooldown > 8 then
		trainCooldown = FlxG.random:int(-4, 0);
		trainMoving = true;
		if not trainSound.playing then
			trainSound:play(true)
		end
	end
end