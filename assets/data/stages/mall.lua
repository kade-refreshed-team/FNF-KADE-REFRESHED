function beatHit()
	parent.stageSprites:get("upperBoppers").animation:play('bop', true);
	parent.stageSprites:get("bottomBoppers").animation:play('bop', true);
	parent.stageSprites:get("santa").animation:play('idle', true);
end