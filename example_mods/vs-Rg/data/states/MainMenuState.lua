script:import("base.MusicBeatSubstate")

--We'll add a button for this. This is just so I can open the menu.
function update()
	if FlxG.keys.justPressed.L then
		parent.persistentUpdate = false;
		parent.persistentDraw = true;
		parent:openSubState(MusicBeatSubstate:new("CoolRgMenu"));
	end
end