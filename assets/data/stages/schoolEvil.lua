function create()
	parent.deadChr = "bf-pixel-dead"
	parent.deadSFX = "week6/fnf_loss_sfx-pixel"
	parent.deadMus = "wee6/gameOver-pixel"
	parent.deadEnd = "week6/gameOverEnd-pixel"

	if KadeEngineData:getOption("distractions") then
		parent:add(FlxTrail:new(parent.dad, nil, 4, 24, 0.3, 0.069));
	end
end