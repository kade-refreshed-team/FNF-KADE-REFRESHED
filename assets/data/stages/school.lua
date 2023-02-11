local danceLeft = true

function create()
	parent.deadChr = "bf-pixel-dead"
	parent.deadSFX = "week6/fnf_loss_sfx-pixel"
	parent.deadMus = "wee6/gameOver-pixel"
	parent.deadEnd = "week6/gameOverEnd-pixel"

	local mults = {1, 1, 1.4, 0.8, 1}
	local names = {"bgSchool", "bgStreet", "bgTrees", "fgTrees", "treeLeaves"}
	local widShit = parent.stageSprites:get("bgSky").width

	for i, name in pairs(names) do
		local sprite = parent.stageSprites:get(name)
		sprite:setGraphicSize(math.floor(widShit * mults[i]))
		sprite:updateHitbox()
	end

	local bgGirls = parent.stageSprites:get("bgGirls")
	if PlayState.songLowercase == "roses" then
		bgGirls.animation:addByIndices('danceLeft', "BG fangirls dissuaded", {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14}, "", 24, false)
		bgGirls.animation:addByIndices('danceRight', "BG fangirls dissuaded", {15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29}, "", 24, false)
	end
	bgGirls.animation:play("danceLeft")
end

function beatHit()
	danceLeft = not danceLeft
	local danceAnim = "danceLeft"
	if not danceLeft then
		danceAnim = "danceRight"
	end

	parent.stageSprites:get("bgGirls").animation:play(danceAnim)
end