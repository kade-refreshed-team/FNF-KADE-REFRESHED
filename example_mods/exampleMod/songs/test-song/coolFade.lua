function beatHit()
	if curBeat == 128 then
		defaultCamZoom = 1.15;
		for i, v in pairs({"stageBack", "stageFront", "stageCurtains"}) do
			FlxTween:tween(stageSprites:get(v), {alpha = 0}, Conductor.crochet / 1000, {ease = FlxEase.circOut})
		end
	elseif curBeat == 159 then
		defaultCamZoom = 0.9;
		for i, v in pairs({"stageBack", "stageFront", "stageCurtains"}) do
			FlxTween:tween(stageSprites:get(v), {alpha = 1}, Conductor.crochet / 2000, {ease = FlxEase.circOut})
		end
	end
end