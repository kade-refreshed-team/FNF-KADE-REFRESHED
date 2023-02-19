local weeks = {
	{"Warmup", "Reality", "Limitless"},
	{} --This is empty bc i dont have the songs for the second week.
}

local portraitCoords = {
	{0, -15},
	{173, -15},
	{338, -15},
	{505, -15},
	{0, 216},
	{173, 216},
	{338, 216},
	{505, 216}
}
local portraits = {}
local static
local qMarks
local lines

function create()
	FlxG.mouse.visible = true

	static = FlxSprite:new(0, 0, Paths:image("menu-side/storymenu/staticBGOverlap"))
	static:setGraphicSize(1280)
	static.scrollFactor:set()
	static:updateHitbox()
	static:screenCenter()
	parent:add(static)

	qMarks = FlxSprite:new()
	qMarks:loadGraphic(Paths:image("menu-side/storymenu/coolThundahAnim"), true, 657, 401)
	qMarks.animation:add("idle", {3, 2, 1, 0}, 1, false)
	qMarks.animation:play("idle")
	qMarks:setGraphicSize(1280)
	qMarks.scrollFactor:set()
	qMarks:updateHitbox()
	qMarks:screenCenter()
	parent:add(qMarks)

	for i = 1, #weeks, 1 do
		local portrait = FlxSprite:new(math.floor(portraitCoords[i][1] * 1.95), math.floor(portraitCoords[i][2] * 1.95), Paths:image("menu-side/storymenu/portrait"..i))
		portrait.scale:set(1.95, 1.95)
		portrait.scrollFactor:set()
		portrait:updateHitbox()
		parent:add(portrait)
		portrait.antialiasing = true
		table.insert(portraits, portrait)
	end

	lines = FlxSprite:new(0, 0, Paths:image("menu-side/storymenu/lines"))
	lines:setGraphicSize(1280)
	lines.scrollFactor:set()
	lines:updateHitbox()
	lines:screenCenter()
	parent:add(lines)
	lines.antialiasing = true;
end

function overlaps(sprite)
	return FlxG.mouse.screenX >= sprite.x and FlxG.mouse.screenX <= sprite.x + sprite.width and FlxG.mouse.screenY >= sprite.y and FlxG.mouse.screenY <= sprite.y + sprite.height
end

local elap = 0
local aelap = 0
local flipFrames = 0
local openinWeek = false;

function update(e)
	elap = elap + e
	if elap >= 0.05 then
		flipFrames = (flipFrames + 1) % 4
		elap = 0;
	end
	static.flipX = flipFrames % 2 == 0
	static.flipY = flipFrames == 3 or flipFrames == 0

	if openinWeek then return; end

	if parent.controls.BACK then
		FlxG.mouse.visible = false
		parent:close()
		return
	end

	aelap = aelap + e
	if aelap >= 1 / 12 then
		qMarks.animation.curAnim.curFrame = FlxG.random:int(0, 3, {qMarks.animation.curAnim.curFrame})
		aelap = 0
	end

	for i, port in pairs(portraits) do
		if overlaps(port) then
			port.color = 0xFFFFFF
			if FlxG.mouse.pressed then
				port.color = 0x808080
			elseif FlxG.mouse.justReleased then
				openWeek(i)
			end
		else
			port.color = 0xB0B0B0
		end
	end
end

script:import("funkin.PreloadingSubState")
script:import("utils.Highscore")
script:import("funkin.Song")

script:import("utils.CoolUtil")

function openWeek(week)
	openinWeek = true;
	if KadeEngineData:getOption("flashing") then
		FlxG.camera:flash(0xFFFFFF, 0.5)
	end

	qMarks.visible = false;
	lines.visible = false;
	for i, p in pairs(portraits) do
		p.visible = false
	end

	local tween = FlxTween:color(static, 2, Std:parseInt("0xFFFFFFFF"), Std:parseInt("0xFF000000"), {startDelay = 1})
	tween.onComplete = function()
		FlxG.state:add(static)
		FlxG.bitmap:clearCache()
		CoolUtil:loadWeek(weeks[week], {"hard"}, 0, 6 + week)
	end
end