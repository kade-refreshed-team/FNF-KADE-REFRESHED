script:import("haxe.io.Path")
script:import("haxe.ds.StringMap")
script:import("sys.FileSystem")
script:import("sys.io.File")
script:import("Type")

script:import("DiscordClient")
script:import("utils.Highscore")
script:import("scripts.BaseScript")
script:import("scripts.HaxeScript")
script:import("menus.StoryMenuState")
script:import("menus.FreeplayState")
script:import("funkin.PreloadingSubState")
script:import("funkin.PlayStateChangeables")

local ShaderFilter = Type:resolveClass("openfl.fliters.ShaderFliter")
if ShaderFilter == nil then
    ShaderFilter = Type:resolveClass("flash.fliters.ShaderFliter")
end
script:import("flixel.FlxCamera")
script:import("flixel.text.FlxTextBorderStyle")
script:import("flixel.group.FlxTypedGroup")
script:import("hscript.Interp")

script:import("StringTools")

local Function_StopLua = "##PSYCHLUA_FUNCTIONSTOPLUA"
local Function_Stop =  "##PSYCHLUA_FUNCTIONSTOP"
local Function_Continue = "##PSYCHLUA_FUNCTIONCONTINUE"

local bpm = Conductor.bpm
local curBPM = PlayState.SONG.bpm
local scrollSpeed = PlayState.SONG.speed
local crochet = Conductor.crochet
local stepCrochet = Conductor.stepCrochet
local songLength = FlxG.sound.music.length
local songName = PlayState.SONG.song
local songPath = parent.songLowercase
local startedCountdown = false
local curStage = PlayState.SONG.stage

local isStoryMode = PlayState.isStoryMode
local difficulty = PlayState.storyDifficulty

local difficultyName = Highscore.diffArray[difficulty]
local difficultyPath = difficultyName;
local weekRaw = PlayState.storyWeek
local week = "week"..weekRaw
local seenCutscene = true

local cameraX = 0
local cameraY = 0

local screenWidth = FlxG.width
local screenHeight = FlxG.height

local curDecBeat = 0
local curDecStep = 0

local score = 0
local misses = 0
local hits = 0

local rating = 0
local ratingName = ""
local ratingFC = ""
local version = "0.6.3" --This is based off 0.6.3 psych lua.

local inGameOver = false
local mustHitSection = false
local altAnim = false
local gfSection = false

local healthGainMult = 1
local healthLossMult = 1
local playbackRate = 1
local instakillOnMiss = false
local botPlay = PlayStateChangeables.botPlay
local practice = false

local _plrStrums = parent.preloadedAssets:get("playerStrums")
local _cpuStrums = parent.preloadedAssets:get("cpuStrums")
for number = 0, 3, 1 do
    _G["defaultPlayerStrumX"..number] = _plrStrums[number].x
    _G["defaultPlayerStrumY"..number] = _plrStrums[number].y
    _G["defaultOpponentStrumX"..number] = _cpuStrums[number].x
    _G["defaultOpponentStrumY"..number] = _cpuStrums[number].y
end

local defaultBoyfriendX = parent.boyfriend.x
local defaultBoyfriendY = parent.boyfriend.y
local defaultOpponentX = parent.dad.x
local defaultOpponentY = parent.dad.y
local defaultGirlfriendX = parent.gf.x
local defaultGirlfriendY = parent.gf.y

local boyfriendName = PlayState.SONG.player1
local dadName = PlayState.SONG.player2
local gfName = PlayState.SONG.gfVersion

local downscroll = PlayStateChangeables.useDownscroll
local middlescroll = false
local framerate = FlxG.save.data.fpsCap
local ghostTapping = FlxG.save.data.ghost
local hideHud = false
local timeBarType = "Disabled"
local scoreZoom = PlayStateChangeables.PsychUI
local cameraZoomOnBeat = FlxG.save.data.camzoom
local flashingLights = FlxG.save.data.flashing
local noteOffset = FlxG.save.data.offset
local healthBarAlpha = 1
local noResetButton = not FlxG.save.data.resetButton
local lowQuality = false
local shadersEnabled = false
local scriptName = script.filePath
local currentModDirectory = Assets.foldersToCheck[0]

local buildTarget = 'unknown'

local unsupportedFunctions = {
    "openCustomSubstate",
    "closeCustomSubstate",
    "initLuaShader",
    "setSpriteShader",
    "removeSpriteShader",
    "getShaderBool",
    "getShaderBoolArray",
    "getShaderInt",
    "getShaderIntArray",
    "getShaderFloat",
    "getShaderFloatArray",
    "setShaderBool",
    "setShaderBoolArray",
    "setShaderInt",
    "setShaderIntArray",
    "setShaderFloat",
    "setShaderFloatArray",
    "setShaderSampler2D"
}

for i, v in pairs(unsupportedFunctions) do
    _G[v] = function()
        print("This function is currently not supported in Kade Refreshed!: "..v)
    end
end

function getRunningScripts()
    local runningScripts = {}
    for i = 0, scripts.length - 1, 1 do
        runningScripts:insert(scripts[i].filePath)
    end
    return runningScripts
end

function tableContains(table, val)
    for i, value in ipairs(table) do
        if value == val then
            return true
        end
    end

    return false
end

function callOnLuas(name, args, ignoreStops, ignoreSelf, exclusions)
    local toReturn = nil
    local runningScripts = {}

    exclusions = exclusions or {}
    if ignoreSelf == nil or ignoreSelf then
        exclusions:insert(scriptName)
    end
    for i, v in pairs(exclusions) do
        exclusions[i] = Path:withoutExtension(v)
    end

    for i = 0, scripts.length - 1, 1 do
        if not tableContains(exclusions, Path:withoutExtension(scripts[i].filePath)) then
            local scriptReturn = scripts[i]:callFunc(name, args)

            if scriptReturn == Function_StopLua and (ignoreStops == nil or not ignoreStops) then
                break
            end

            if scriptReturn ~= nil and scriptReturn ~= Function_Continue then
                toReturn = scriptReturn
            end
        end
    end

    return toReturn
end

function callScript(file, name, args)
    file = Path:withoutExtension(file)

    for i = 0, scripts.length - 1, 1 do
        if Path:withoutExtension(scripts[i].filePath) == file then
            return scripts[i]:call(name, args)
        end
    end
end

function getGlobalFromScript(file, name)
    file = Path:withoutExtension(file)

    for i = 0, scripts.length - 1, 1 do
        if Path:withoutExtension(scripts[i].filePath) == file then
            return scripts[i]:getVar(name)
        end
    end
end

function setGlobalFromScript(file, name, value)
    file = Path:withoutExtension(file)

    for i = 0, scripts.length - 1, 1 do
        if Path:withoutExtension(scripts[i].filePath) == file then
            scripts[i]:setVar(name, value)
            break
        end
    end
end

function isRunning(file)
    file = Path:withoutExtension(file)

    for i = 0, scripts.length - 1, 1 do
        if Path:withoutExtension(scripts[i].filePath) == file then
            return true
        end
    end

    return false
end

function addLuaScript(file, ignoreAlreadyRunning)
    file = Path:withoutExtension(file)

    for i = 0, scripts.length - 1, 1 do
        if (ignoreAlreadyRunning == nil or not ignoreAlreadyRunning) and Path:withoutExtension(scripts[i].filePath) == file then
            print("Script "..file.." is already running.")
            return
        end
    end

    scripts:push(BaseScript:makeScript(file))
end

function removeLuaScript(file, ignoreAlreadyRunning)
    file = Path:withoutExtension(file)

    for i = 0, scripts.length - 1, 1 do
        if Path:withoutExtension(scripts[i].filePath) == file then
            local script = scripts[i]
            scripts:splice(i, 1)
            script:destroy()
        end
    end
    print("Script "..file.." is not avaliable.")
end

local hscriptInterp = Interp:new()

hscriptInterp.errorHandler = function(error)
    print(error:toString())
end

hscriptInterp.variables:set("FlxG", FlxG);
hscriptInterp.variables:set("FlxSprite", FlxSprite);
hscriptInterp.variables:set("FlxCamera", FlxCamera);
hscriptInterp.variables:set("FlxTimer", FlxTimer);
hscriptInterp.variables:set("FlxTween", FlxTween);
hscriptInterp.variables:set("FlxEase", FlxEase);
hscriptInterp.variables:set("PlayState", PlayState);
hscriptInterp.variables:set("game", FlxG.state);
hscriptInterp.variables:set("Paths", Paths);
hscriptInterp.variables:set("Conductor", Conductor);
hscriptInterp.variables:set("ClientPrefs", {});
hscriptInterp.variables:set("Character", Character);
hscriptInterp.variables:set("Alphabet", Alphabet);
--hscriptInterp.variables:set("CustomSubstate", CustomSubstate);
--#if (!flash && sys)
--hscriptInterp.variables:set("FlxRuntimeShader", FlxRuntimeShader);
--#end
hscriptInterp.variables:set("ShaderFilter", ShaderFilter);
hscriptInterp.variables:set("StringTools", StringTools);

hscriptInterp.variables:set("setVar", function(name, value)
    FlxG.state.publicVars:set(name, value);
end);
hscriptInterp.variables:set("getVar", function(name)
    local result = nil;
    if FlxG.state.publicVars:exists(name) then
        result = FlxG.state.publicVars:get(name)
    end
    return result;
end);
hscriptInterp.variables:set("removeVar", function(name)
    if FlxG.state.publicVars:exists(name) then
        FlxG.state.publicVars:remove(name);
        return true;
    end
    return false;
end)

function runHaxeCode(codeToRun)
    HaxeScript.parser.line = 1;
    return hscriptInterp.execute(HaxeScript.parser.parseString(codeToRun, "LUA-HSCRIPT ("..script.filePath..")"))
end

function addHaxeLibrary(libName, package)
    local classPath = libName
    if StringTools:trim(package) ~= "" then
        classPath = package.."."..libName
    end

    hscriptInterp.variables:set(libName, Type:resolveClass(classPath))
end

function loadSong(name, diff)
    if diff ~= nil and diff >= 0 then
        PlayState.storyDifficulty = diff
    end

    PlayState.SONG = funkin.SongClasses.Song.loadFromJson(Highscore.diffArray[PlayState.storyDifficulty], name or PlayState.SONG.song)
    FlxG.state.persistentUpdate = false
    FlxG.state:openSubState(PreloadingSubState:new())
end

function loadGraphic(tag, image, gridX, gridY)
    local spr = getProperty(tag)
    if image ~= nil and string.len(image) > 0 and spr ~= nil and Std:isOfType(spr, FlxSprite) then
        gridX = gridX or 0
        gridY = gridY or 0

        local animated = (gridX ~= 0 or gridY ~= 0)
        spr:loadGraphic(Paths:image(image), animated, gridX, gridY)
    end
end

function _loadFrames(image, spritesheetType)
    spritesheetType = string.lower(spritesheetType or "sparrow")

    if spritesheetType == "packer" or spritesheetType == "packeratlas" or spritesheetType == "pac" then
        return Paths:getPackerAtlas(image)
    else
        return Paths:getSparrowAtlas(image)
    end
end

function loadFrames(tag, image, spritesheetType)
    local spr = getProperty(tag)
    if image ~= nil and string.len(image) > 0 and spr ~= nil and Std:isOfType(spr, FlxSprite) then
        spr.frames = _loadFrames(image, spritesheetType)
    end
end

function stringStartsWith(inputstr, start)
    return StringTools:startsWith(inputstr, start)
end

function stringEndsWith(inputstr, daEnd)
    return StringTools:endsWith(inputstr, daEnd)
end

function stringSplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function stringTrim(inputstr)
    return StringTools:trim(inputstr)
end

function getProperty(prop)
    local toReturn = nil
    local properties = stringSplit(prop, ".")

    if parent.publicVars:exists("PSYCH_SPR_"..properties[1]) then
        toReturn = parent.publicVars:get("PSYCH_SPR_"..properties[1])
    elseif parent.publicVars:exists("PSYCH_TXT_"..properties[1]) then
        toReturn = parent.publicVars:get("PSYCH_TXT_"..properties[1])
    elseif parent.publicVars:exists("PSYCH_SOUND_"..properties[1]) then
        toReturn = parent.publicVars:get("PSYCH_SOUND_"..properties[1])
    else
        toReturn = parent[properties[1]]
    end

    for i = 2, #properties, 1 do
        toReturn = toReturn[properties[i]]
    end

    return toReturn;
end

function setProperty(prop, value)
    local toSet = nil
    local properties = stringSplit(prop, ".")
    if parent.publicVars:exists("PSYCH_SPR_"..properties[1]) then
        toSet = parent.publicVars:get("PSYCH_SPR_"..properties[1])
    elseif parent.publicVars:exists("PSYCH_TXT_"..properties[1]) then
        toSet = parent.publicVars:get("PSYCH_TXT_"..properties[1])
    elseif parent.publicVars:exists("PSYCH_SOUND_"..properties[1]) then
        toSet = parent.publicVars:get("PSYCH_SOUND_"..properties[1])
    else
        toSet = parent[properties[1]]
        if #properties == 1 then
            parent[properties[1]] = value
            return
        end
    end

    for i = 2, #properties - 1, 1 do
        toSet = toSet[properties[i]]
    end

    toSet[properties[#properties]] = value
end

function getPropertyInGroup(group, index, prop)
    local daGroup = getProperty(group)
    local groupObj = {};

    if Std:isOfType(daGroup, FlxTypedGroup) then
        groupObj = daGroup.members[index]
    else
        groupObj = daGroup[index]
    end

    local toReturn = groupObj[properties[1]]

    for i = 2, #properties, 1 do
        toReturn = toReturn[properties[i]]
    end

    return toReturn;
end

function setPropertyInGroup(group, index, prop, value)
    local daGroup = getProperty(group)
    local groupObj = {};
    
    if Std:isOfType(daGroup, FlxTypedGroup) then
        groupObj = daGroup.members[index]
    else
        groupObj = daGroup[index]
    end

    local toSet = groupObj[properties[1]]

    for i = 2, #properties - 1, 1 do
        toSet = toSet[properties[i]]
    end

    toSet[properties[#properties]] = value
end

function removeFromGroup(group, index, dontDestroy)
    local daGroup = getProperty(group)
    local groupObj = {};

    if Std:isOfType(daGroup, FlxTypedGroup) then
        groupObj = daGroup.members[index]
        daGroup:remove(groupObj, true)
    else
        groupObj = daGroup[index]
        daGroup:remove(groupObj)
    end

    if dontDestroy == nil or not dontDestroy then
        groupObj:destroy()
    end
end

function getPropertyInClass(class, prop)
    local daClass = Type:resolveClass(class)

    local toReturn = daClass[properties[1]]

    for i = 2, #properties, 1 do
        toReturn = toReturn[properties[i]]
    end

    return toReturn;
end

function setPropertyInClass(class, prop, value)
    local daClass = Type:resolveClass(class)

    local toSet = daClass[properties[1]]

    for i = 2, #properties - 1, 1 do
        toSet = toSet[properties[i]]
    end

    toSet[properties[#properties]] = value
end

function getObjectOrder(obj)
    local daObject = getProperty(obj)

    return script.parent:indexOf(daObject)
end

function setObjectOrder(obj, zIndex)
    local daObject = getProperty(obj)

    script.parent:remove(daObject, true)
    script.parent:insert(zIndex, daObject)
end

local _psychEases = StringMap:new()
_psychEases:set("backin", FlxEase.backIn);
_psychEases:set("backinout", FlxEase.backInOut);
_psychEases:set("backout", FlxEase.backOut);
_psychEases:set("bouncein", FlxEase.bounceIn);
_psychEases:set("bounceinout", FlxEase.bounceInOut);
_psychEases:set("bounceout", FlxEase.bounceOut);
_psychEases:set("circin", FlxEase.circIn);
_psychEases:set("circinout", FlxEase.circInOut);
_psychEases:set("circout", FlxEase.circOut);
_psychEases:set("cubein", FlxEase.cubeIn);
_psychEases:set("cubeinout", FlxEase.cubeInOut);
_psychEases:set("cubeout", FlxEase.cubeOut);
_psychEases:set("elasticin", FlxEase.elasticIn);
_psychEases:set("elasticinout", FlxEase.elasticInOut);
_psychEases:set("elasticout", FlxEase.elasticOut);
_psychEases:set("expoin", FlxEase.expoIn);
_psychEases:set("expoinout", FlxEase.expoInOut);
_psychEases:set("expoout", FlxEase.expoOut);
_psychEases:set("quadin", FlxEase.quadIn);
_psychEases:set("quadinout", FlxEase.quadInOut);
_psychEases:set("quadout", FlxEase.quadOut);
_psychEases:set("quartin", FlxEase.quartIn);
_psychEases:set("quartinout", FlxEase.quartInOut);
_psychEases:set("quartout", FlxEase.quartOut);
_psychEases:set("quintin", FlxEase.quintIn);
_psychEases:set("quintinout", FlxEase.quintInOut);
_psychEases:set("quintout", FlxEase.quintOut);
_psychEases:set("sinein", FlxEase.sineIn);
_psychEases:set("sineinout", FlxEase.sineInOut);
_psychEases:set("sineout", FlxEase.sineOut);
_psychEases:set("smoothstepin", FlxEase.smoothStepIn);
_psychEases:set("smoothstepinout", FlxEase.smoothStepInOut);
_psychEases:set("smoothstepout", FlxEase.smoothStepInOut);
_psychEases:set("smootherstepin", FlxEase.smootherStepIn);
_psychEases:set("smootherstepinout", FlxEase.smootherStepInOut);
_psychEases:set("smootherstepout", FlxEase.smootherStepOut);

function doTweenX(tag, obj, value, duration, ease)
    if parent.publicVars:exists("PSYCH_TWEEN_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TWEEN_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    local daEase = FlxEase.linear
    if _psychEases:exists(string.lower(ease or "nada")) then
        daEase = _psychEases:get(string.lower(ease))
    end

    local daTween = FlxTween:tween(getProperty(obj), {x = value}, duration, {ease = daEase})
    daTween.onComplete = function(twn)
        callOnLuas("onTweenCompleted", {tag}, false, false)
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    parent.publicVars:set("PSYCH_TWEEN_"..tag, daTween)
end

function doTweenY(tag, obj, value, duration, ease)
    if parent.publicVars:exists("PSYCH_TWEEN_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TWEEN_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    local daEase = FlxEase.linear
    if _psychEases:exists(string.lower(ease or "nada")) then
        daEase = _psychEases:get(string.lower(ease))
    end

    local daTween = FlxTween:tween(getProperty(obj), {y = value}, duration, {ease = daEase})
    daTween.onComplete = function(twn)
        callOnLuas("onTweenCompleted", {tag}, false, false)
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    parent.publicVars:set("PSYCH_TWEEN_"..tag, daTween)
end

function doTweenAngle(tag, obj, value, duration, ease)
    if parent.publicVars:exists("PSYCH_TWEEN_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TWEEN_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    local daEase = FlxEase.linear
    if _psychEases:exists(string.lower(ease or "nada")) then
        daEase = _psychEases:get(string.lower(ease))
    end

    local daTween = FlxTween:tween(getProperty(obj), {angle = value}, duration, {ease = daEase})
    daTween.onComplete = function(twn)
        callOnLuas("onTweenCompleted", {tag}, false, false)
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    parent.publicVars:set("PSYCH_TWEEN_"..tag, daTween)
end

function doTweenAlpha(tag, obj, value, duration, ease)
    if parent.publicVars:exists("PSYCH_TWEEN_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TWEEN_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    local daEase = FlxEase.linear
    if _psychEases:exists(string.lower(ease or "nada")) then
        daEase = _psychEases:get(string.lower(ease))
    end

    local daTween = FlxTween:tween(getProperty(obj), {alpha = value}, duration, {ease = daEase})
    daTween.onComplete = function(twn)
        callOnLuas("onTweenCompleted", {tag}, false, false)
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    parent.publicVars:set("PSYCH_TWEEN_"..tag, daTween)
end

function doTweenZoom(tag, obj, value, duration, ease)
    if parent.publicVars:exists("PSYCH_TWEEN_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TWEEN_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    local daEase = FlxEase.linear
    if _psychEases:exists(string.lower(ease or "nada")) then
        daEase = _psychEases:get(string.lower(ease))
    end

    local daTween = FlxTween:tween(getProperty(obj), {zoom = value}, duration, {ease = daEase})
    daTween.onComplete = function(twn)
        callOnLuas("onTweenCompleted", {tag}, false, false)
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    parent.publicVars:set("PSYCH_TWEEN_"..tag, daTween)
end

function doTweenColor(tag, obj, value, duration, ease)
    if parent.publicVars:exists("PSYCH_TWEEN_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TWEEN_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    local daEase = FlxEase.linear
    if _psychEases:exists(string.lower(ease or "nada")) then
        daEase = _psychEases:get(string.lower(ease))
    end

    local daObject = getProperty(obj)
    local curColor = daObject.color

    local daTween = FlxTween:color(daObject, duration, curColor, CoolUtil:stringColor(value), {ease = daEase})
    daTween.onComplete = function(twn)
        callOnLuas("onTweenCompleted", {tag}, false, false)
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    parent.publicVars:set("PSYCH_TWEEN_"..tag, daTween)
end

function noteTweenX(tag, index, value, duration, ease)
    if parent.publicVars:exists("PSYCH_TWEEN_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TWEEN_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    local daEase = FlxEase.linear
    if _psychEases:exists(string.lower(ease or "nada")) then
        daEase = _psychEases:get(string.lower(ease))
    end

    local daTween = FlxTween:tween(parent.strumLineNotes.members[index % parent.strumLineNotes.length], {x = value}, duration, {ease = daEase})
    daTween.onComplete = function(twn)
        callOnLuas("onTweenCompleted", {tag}, false, false)
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    parent.publicVars:set("PSYCH_TWEEN_"..tag, daTween)
end

function noteTweenY(tag, index, value, duration, ease)
    if parent.publicVars:exists("PSYCH_TWEEN_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TWEEN_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    local daEase = FlxEase.linear
    if _psychEases:exists(string.lower(ease or "nada")) then
        daEase = _psychEases:get(string.lower(ease))
    end

    local daTween = FlxTween:tween(parent.strumLineNotes.members[index % parent.strumLineNotes.length], {y = value}, duration, {ease = daEase})
    daTween.onComplete = function(twn)
        callOnLuas("onTweenCompleted", {tag}, false, false)
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    parent.publicVars:set("PSYCH_TWEEN_"..tag, daTween)
end

function noteTweenAngle(tag, index, value, duration, ease)
    if parent.publicVars:exists("PSYCH_TWEEN_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TWEEN_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    local daEase = FlxEase.linear
    if _psychEases:exists(string.lower(ease or "nada")) then
        daEase = _psychEases:get(string.lower(ease))
    end

    local daTween = FlxTween:tween(parent.strumLineNotes.members[index % parent.strumLineNotes.length], {angle = value}, duration, {ease = daEase})
    daTween.onComplete = function(twn)
        callOnLuas("onTweenCompleted", {tag}, false, false)
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    parent.publicVars:set("PSYCH_TWEEN_"..tag, daTween)
end

function noteTweenAlpha(tag, index, value, duration, ease)
    if parent.publicVars:exists("PSYCH_TWEEN_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TWEEN_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    local daEase = FlxEase.linear
    if _psychEases:exists(string.lower(ease or "nada")) then
        daEase = _psychEases:get(string.lower(ease))
    end

    local daTween = FlxTween:tween(parent.strumLineNotes.members[index % parent.strumLineNotes.length], {alpha = value}, duration, {ease = daEase})
    daTween.onComplete = function(twn)
        callOnLuas("onTweenCompleted", {tag}, false, false)
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end

    parent.publicVars:set("PSYCH_TWEEN_"..tag, daTween)
end

function noteTweenDirection(tag, index, value, duration, ease)
    print("Note directions are currently unsupported in Kade Refreshed!")
end

function mouseClicked(button)
    if button == "right" then
        return FlxG.mouse.justPressedRight
    elseif button == "middle" then
        return FlxG.mouse.justPressedMiddle
    end

    return FlxG.mouse.justPressed
end

function mousePressed(button)
    if button == "right" then
        return FlxG.mouse.pressedRight
    elseif button == "middle" then
        return FlxG.mouse.pressedMiddle
    end

    return FlxG.mouse.pressed
end

function mouseReleased(button)
    if button == "right" then
        return FlxG.mouse.justReleasedRight
    elseif button == "middle" then
        return FlxG.mouse.justReleasedMiddle
    end

    return FlxG.mouse.justReleased
end

function cancelTween(tag)
    if parent.publicVars:exists("PSYCH_TWEEN_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TWEEN_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TWEEN_"..tag)
    end
end

function runTimer(tag, duration, loops)
    if parent.publicVars:exists("PSYCH_TIMER_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TIMER_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TIMER_"..tag)
    end

    local daTimer = FlxTimer:new():start(duration, function(tmr)
        callOnLuas("onTimerCompleted", {tag}, false, false)
        parent.publicVars:remove("PSYCH_TIMER_"..tag)
    end, loops)
end

function cancelTimer(tag)
    if parent.publicVars:exists("PSYCH_TIMER_"..tag) then
        local tween = parent.publicVars:get("PSYCH_TIMER_"..tag)
        tween:cancel()
        tween:destroy()
        parent.publicVars:remove("PSYCH_TIMER_"..tag)
    end
end

function addScore(inc)
    parent.songScore = parent.songScore + inc
end

function addMisses(inc)
    parent.misses = parent.misses + inc
end

function addHits(inc)
    parent.totalNotesHit = parent.totalNotesHit + inc
end

function setScore(daScore)
    parent.songScore = daScore
end

function setMisses(daMisses)
    parent.misses = daMisses
end

function setHits(hits)
    parent.totalNotesHit = hits
end

function getScore()
    return parent.songScore
end

function getMisses()
    return parent.misses
end

function getHits()
    return parent.totalNotesHit
end

function setHealth(hp)
    parent.health = hp
end

function addHealth(inc)
    parent.health = parent.health + inc
end

function getHealth()
    return parent.health
end

function getColorFromHex(hex)
    return CoolUtil:stringColor(hex) --Funny thing is that this can also support rgb colors.
end

function keyboardJustPressed(name)
    return FlxG.keys.justPressed[name]
end

function keyboardPressed(name)
    return FlxG.keys.pressed[name]
end

function keyboardReleased(name)
    return FlxG.keys.justReleased[name]
end

function anyGamepadJustPressed(name)
    return FlxG.gamepads:anyJustPressed(name)
end

function anyGamepadPressed(name)
    return FlxG.gamepads:anyPressed(name)
end

function anyGamepadReleased(name)
    return FlxG.gamepads:anyJustReleased(name)
end

function gamepadAnalogX(id, leftStick)
    local controller = FlxG.gamepads:getByID(id)
    if controller == nil then
        return
    end

    local stick = 19 --19 is for left, 20 is for right.
    if leftStick ~= nil and not leftStick then
        stick = 20
    end

    return controller:getXAxis(stick)
end

function gamepadAnalogY(id, leftStick)
    local controller = FlxG.gamepads:getByID(id)
    if controller == nil then
        return
    end

    local stick = 19 --19 is for left, 20 is for right.
    if leftStick ~= nil and not leftStick then
        stick = 20
    end

    return controller:getYAxis(stick)
end

function gamepadJustPressed(id, name)
    local controller = FlxG.gamepads:getByID(id)
    if controller == nil then
        return
    end

    return controller.justPressed[name]
end

function gamepadPressed(id, name)
    local controller = FlxG.gamepads:getByID(id)
    if controller == nil then
        return
    end

    return controller.pressed[name]
end

function gamepadReleased(id, name)
    local controller = FlxG.gamepads:getByID(id)
    if controller == nil then
        return
    end

    return controller.justReleased[name]
end

function keyJustPressed(name)
    name = string.lower(name)

    if name == "space" then
        return FlxG.keys.justPressed.SPACE
    end

    local keyNames = {"left", "down", "up", "right", "accept", "back", "pause", "reset"}
    local propNames = {"LEFT_P", "DOWN_P", "UP_P", "RIGHT_P", "ACCEPT", "BACK", "PAUSE", "RESET"}

    for i, key in pairs(keyNames) do
        if name == key then
            return parent.controls[propNames[i]]
        end
    end

    return false
end

function keyPressed(name)
    name = string.lower(name)

    if name == "space" then
        return FlxG.keys.pressed.SPACE
    end

    local keyNames = {"left", "down", "up", "right"}
    local propNames = {"LEFT", "DOWN", "UP", "RIGHT"}

    for i, key in pairs(keyNames) do
        if name == key then
            return parent.controls[propNames[i]]
        end
    end

    return false
end

function keyReleased(name)
    name = string.lower(name)

    if name == "space" then
        return FlxG.keys.justReleased.SPACE
    end

    local keyNames = {"left", "down", "up", "right"}
    local propNames = {"LEFT_R", "DOWN_R", "UP_R", "RIGHT_R"}

    for i, key in pairs(keyNames) do
        if name == key then
            return parent.controls[propNames[i]]
        end
    end

    return false
end

function addCharacterToList(name, uselessParam)
    Character:preloadCharBitmap(name)
end

function precacheImage(name)
    FlxG.bitmap:add(Paths:image(name))
end

function precacheSound(name)
    FlxG.bitmap:add(Paths:sound(name))
end

function precacheMusic(name)
    FlxG.bitmap:add(Paths:music(name))
end

function triggerEvent(name, arg1, arg2)
    print("Events are currently unsupported in Kade Refreshed!")
end

function startCountdown()
    parent:startCountdown()
    return true
end

function endSong()
    while parent.notes.length > 0 do
        local note = parent.notes.members[0]
        parent.notes:remove(note)
        note:destroy()
    end
    parent:endSong()
    return true
end

function restartSong(skipTransition)
    parent.persistentUpdate = false
    parent:openSubState(PreloadingSubState:new());
    return true
end

function exitSong(skipTransition)
    while parent.notes.length > 0 do
        local note = parent.notes.members[0]
        parent.notes:remove(note)
        note:destroy()
    end

    if PlayState.isStoryMode then
        FlxG:switchState(StoryMenuState:new())
    else
        FlxG:switchState(FreeplayState:new())
    end

    return true
end

function getSongPosition()
    return Conductor.songPosition
end

function getCharacterX(char)
    if char == "dad" or char == "opponent" then
        return parent.dad.x
    elseif char == "gf" or char == "girlfriend" then
        return parent.gf.x
    else
        return parent.boyfriend.x
    end
end

function setCharacterX(char, newX)
    if char == "dad" or char == "opponent" then
        parent.dad.x = newX
    elseif char == "gf" or char == "girlfriend" then
        parent.gf.x = newX
    else
        parent.boyfriend.x = newX
    end
end

function getCharacterX(char)
    if char == "dad" or char == "opponent" then
        return parent.dad.y
    elseif char == "gf" or char == "girlfriend" then
        return parent.gf.y
    else
        return parent.boyfriend.y
    end
end

function setCharacterX(char, newY)
    if char == "dad" or char == "opponent" then
        parent.dad.y = newY
    elseif char == "gf" or char == "girlfriend" then
        parent.gf.y = newY
    else
        parent.boyfriend.y = newY
    end
end

function cameraSetTarget(target)
    if target == "dad" then
        local dadMidpoint = parent.dad:getMidpoint()

        parent.camFollow:setPosition(dadMidpoint.x + 150 + parent.camOffsets.dadCamX + parent.dad.data.offsets.camX, dadMidpoint.y - 100 + parent.camOffsets.dadCamY + parent.dad.data.offsets.camY)

        if vocals ~= nil and vocals._transform ~= nil then
            vocals.volume = 1
        end
        dadMidpoint:put();

        return true
    else
        local bfMidpoint = parent.boyfriend:getMidpoint();

        parent.camFollow:setPosition(bfMidpoint.x - 100 + parent.camOffsets.bfCamX + parent.boyfriend.data.offsets.camX, bfMidpoint.y - 100 + parent.camOffsets.bfCamY + parent.boyfriend.data.offsets.camY);

        bfMidpoint:put();

        return false
    end
end

function _camFromString(cam)
    cam = string.lower(cam or "game")
    if cam == "camhud" or cam == "hud" or cam == "camother" or cam == "other" then
        return parent.camHUD
    end

    return FlxG.camera
end

function cameraShake(cam, intensity, duration)
    _camFromString(cam):shake(intensity, duration)
end

function cameraFlash(cam, color, duration, forced)
    _camFromString(cam):flash(CoolUtil:stringColor(color), duration, nil, forced)
end

function cameraFade(cam, color, duration, forced)
    _camFromString(cam):fade(CoolUtil:stringColor(color), duration, false, nil, forced)
end

function setRatingPercent(newAcc)
    parent.accuracy = newAcc
end

function setRatingName(name)
end -- I would put something here, but because of they way Kade Refreshed does rating names, it might not work well.

function setRatingFC(newFc)
end -- Same thing.

function getMouseX(cam)
    return FlxG.mouse.getScreenPosition(_camFromString(cam)).x
end

function getMouseY(cam)
    return FlxG.mouse.getScreenPosition(_camFromString(cam)).y
end

function getMidpointX(object)
    local obj = getProperty(object)
    if obj == null then
        return 0
    end

    return obj:getMidpoint().x
end

function getMidpointY(object)
    local obj = getProperty(object)
    if obj == null then
        return 0
    end

    return obj:getMidpoint().y
end

function getGraphicMidpointX(object)
    local obj = getProperty(object)
    if obj == null then
        return 0
    end

    return obj:getGraphicMidpoint().x
end

function getGraphicMidpointY(object)
    local obj = getProperty(object)
    if obj == null then
        return 0
    end

    return obj:getGraphicMidpoint().y
end

function getScreenPositionX(object)
    local obj = getProperty(object)
    if obj == null then
        return 0
    end

    return obj:getScreenPosition().x
end

function getScreenPositionY(object)
    local obj = getProperty(object)
    if obj == null then
        return 0
    end

    return obj:getScreenPosition().y
end

function characterDance(char)
    if char == "dad" or char == "opponent" then
        parent.dad:dance()
    elseif char == "gf" or char == "girlfriend" then
        parent.gf:dance()
    else
        parent.boyfriend:dance()
    end
end

function _murderThatGoddamnLuaSprite(tag)
    if parent.publicVars:exists("PSYCH_SPR_"..tag) then
        local spr = parent.publicVars:get("PSYCH_SPR_"..tag)
        parent:remove(spr, true)
        spr:destroy()
    end
end

function makeLuaSprite(tag, image, x, y)
    _murderThatGoddamnLuaSprite(tag)

    local spr = FlxSprite:new(x, y, Paths:image(image))
    spr.antialiasing = true
    parent.publicVars:set("PSYCH_SPR_"..tag, spr)
end

function makeAnimatedLuaSprite(tag, image, x, y, spritesheetType)
    _murderThatGoddamnLuaSprite(tag)

    local spr = FlxSprite:new(x, y)
    spr.antialiasing = true
    spr.frames = _loadFrames(image, spritesheetType)
    parent.publicVars:set("PSYCH_SPR_"..tag, spr)
end

function makeGraphic(tag, width, height, color)
    if parent.publicVars:exists("PSYCH_SPR_"..tag) then
        parent.publicVars:get("PSYCH_SPR_"..tag):makeGraphic(width, height, CoolUtil:stringColor(color))
    end
end

function addAnimationByPrefix(tag, name, prefix, fps, loop)
    local spr = getProperty(tag)

    spr.animation:addByPrefix(name, prefix, fps or 24, (loop == nil or loop))

    if spr.animation.curAnim == nil then
        spr.animation:play(name, true)
    end
end

function addAnimation(tag, name, frames, fps, loop)
    local spr = getProperty(tag)

    spr.animation:add(name, frames, fps or 24, (loop == nil or loop))

    if spr.animation.curAnim == nil then
        spr.animation:play(name, true)
    end
end

function addAnimationByIndices(tag, name, prefix, indices, fps, loop)
    local daIndices = {}
    for i, v in pairs(stringSplit(indices, ",")) do
        table.insert(daIndices, Std:parseInt(StringTools:trim(v)))
    end

    local spr = getProperty(tag)

    spr.animation:addByIndices(name, prefix, daIndices, "", fps or 24, (loop ~= nil and loop))

    if spr.animation.curAnim == nil then
        spr.animation:play(name, true)
    end
end

function addAnimationByIndicesLoop(tag, name, prefix, indices, fps)
    addAnimationByIndices(tag, name, prefix, indices, fps, true)
end

function playAnim(tag, anim, force, reverse, startFrame)
    local spr = getProperty(tag)

    if spr == nil then
        return false
    end

    if Std:isOfType(spr, Character) then
        spr:playAnim(anim, force, reverse, startFrame)
    else
        spr.animation:play(anim, force, reverse, startFrame)
    end
    return true
end

function addOffset(tag, anim, x, y)
    local spr = getProperty(tag)

    if Std:isOfType(spr, Character) then
        spr.animOffsets:set(anim, {x / spr.data.scale, y / spr.data.scale})
    end
end

function setScrollFactor(tag, x, y)
    getProperty(tag).scrollFactor:set(x, y)
end

function addLuaSprite(tag, front)
    if front then
        parent:add(getProperty(tag))
    else
        local index = 0

        local gfPos = parent.members:indexOf(parent.gf)
        if gfPos > 0 then
            index = gfPos
        end

        local bfPos = parent.members:indexOf(parent.boyfriend)
        if bfPos > 0 and bfPos < index then
            index = bfPos
        end

        local dadPos = parent.members:indexOf(parent.dad)
        if dadPos > 0 and dadPos < index then
            index = dadPos
        end

        parent:insert(index, getProperty(tag))
    end
end

function setGraphicSize(tag, width, height, updateHitbox)
    local spr = getProperty(tag)
    spr:setGraphicSize(width, height)

    if updateHitbox == nil or updateHitbox then
        spr:updateHitbox()
    end
end

function scaleObject(tag, x, y, updateHitbox)
    local spr = getProperty(tag)
    spr.scale:set(x, y)

    if updateHitbox == nil or updateHitbox then
        spr:updateHitbox()
    end
end

function updateHitbox(tag)
    getProperty(tag):updateHitbox()
end

function updateHitboxFromGroup(group, index)
    local daGroup = getProperty(group)
    local groupObj = {};

    if Std:isOfType(daGroup, FlxTypedGroup) then
        groupObj = daGroup.members[index]
    else
        groupObj = daGroup[index]
    end

    groupObj:updateHitbox()
end

function removeLuaSprite(tag, destroy) -- we are once again _murderThatGoddamnLuaSprite
    if parent.publicVars:exists("PSYCH_SPR_"..tag) then
        local spr = parent.publicVars:get("PSYCH_SPR_"..tag)
        parent:remove(spr, true)
        if destroy == nil or destroy then
            spr:destroy()
        end
    end
end

function luaSpriteExists(tag)
    return parent.publicVars:exists("PSYCH_SPR_"..tag)
end

function luaTextExists(tag)
    return parent.publicVars:exists("PSYCH_TXT_"..tag)
end

function luaSoundExists(tag)
    return parent.publicVars:exists("PSYCH_SOUND_"..tag)
end

function setHealthBarColors(left, right)
    parent.healthBar.emptyColor = CoolUtil:stringColor(left)
    parent.healthBar.fillColor = CoolUtil:stringColor(right)
end

function setTimeBarColors(left, right)
    parent.songPosBar.emptyColor = CoolUtil:stringColor(right)
    parent.songPosBar.fillColor = CoolUtil:stringColor(left)
end

function setObjectCamera(tag, cam)
    getProperty(tag).cameras = {_camFromString(cam)}
end

local _psychBlends = StringMap:new()
_psychBlends:set("add", BlendMode.ADD);
_psychBlends:set("alpha", BlendMode.ALPHA);
_psychBlends:set("darken", BlendMode.DARKEN);
_psychBlends:set("difference", BlendMode.DIFFERENCE);
_psychBlends:set("erase", BlendMode.ERASE);
_psychBlends:set("hardlight", BlendMode.HARDLIGHT);
_psychBlends:set("invert", BlendMode.INVERT);
_psychBlends:set("layer", BlendMode.LAYER);
_psychBlends:set("lighten", BlendMode.LIGHTEN);
_psychBlends:set("multiply", BlendMode.MULTIPLY);
_psychBlends:set("overlay", BlendMode.OVERLAY);
_psychBlends:set("screen", BlendMode.SCREEN);
_psychBlends:set("shader", BlendMode.SHADER);
_psychBlends:set("subtract", BlendMode.SUBTRACT);

function setBlendMode(tag, blend)
    local daBlend = BlendMode.NORMAL
    if _psychBlends:exists(string.lower(blend or "nada")) then
        daBlend = _psychBlends:get(string.lower(blend))
    end

    getProperty(tag).blend = daBlend
end

function screenCenter(tag, axes)
    local daAxes = 0x11 --XY
    if axes == "x" then
        daAxes = 0x01
    elseif axes == "y" then
        daAxes = 0x10
    end

    getProperty(tag):screenCenter(daAxes)
end

function objectsOverlap(obj1, obj2)
    local daObj1 = getProperty(obj1)
    local daObj2 = getProperty(obj2)

    if daObj1 ~= nil and daObj2 ~= nil then
        return FlxG:overlap(daObj1, daObj2)
    else
        print("One of these two objects are null.: "..obj1.." | "..obj2.." | "..daObj1.." | "..daObj2)
    end
    return false
end

function getPixelColor(tag, x, y)
    local spr = getProperty(tag)
    
    if spr.framePixels ~= nil then
        return spr.framePixels:getPixel32(x, y)
    else
        return spr.pixels:getPixel32(x, y)
    end
end

function getRandomInt(min, max, exclusions)
    local daExclusions = stringSplit(exclusions, ",")
    local toExclude = {}
    for i, v in pairs(daExclusions) do
        table.insert(toExclude, Std:parseInt(StringTools:trim(v)))
    end

    return FlxG.random:int(min, max, toExclude)
end

function getRandomFloat(min, max, exclusions)
    local daExclusions = stringSplit(exclusions, ",")
    local toExclude = {}
    for i, v in pairs(daExclusions) do
        table.insert(toExclude, Std:parseFloat(StringTools:trim(v)))
    end

    return FlxG.random:float(min, max, toExclude)
end

function getRandomBool(chance)
    return FlxG.random:bool(chance or 50)
end

function startDialogue(file, music)
    print('startDialogue is currently unsupported in Kade Refreshed!')
end

function startVideo(video)
    print('Videos are currently unsupported in Kade Refreshed!')
end

function playMusic(music, vol, loop)
    FlxG.sound:playMusic(Paths:music(music), vol or 1, loop or true)
end

function playSound(sound, vol, tag)
    if tag ~= nil and string.len(tag) > 0 then
        if parent.publicVars:exists("PSYCH_SOUND_"..tag) then
            parent.publicVars:get("PSYCH_SOUND_"..tag):stop()
        end

        local daSound = FlxG.sound:play(Paths:sound(sound), vol or 1, false)
        daSound.onComplete = function()
            parent.publicVars:remove("PSYCH_SOUND_"..tag)
            callOnLuas("onSoundCompleted", {tag}, false, false)
        end

        parent.publicVars:set("PSYCH_SOUND_"..tag, daSound)
    end

    FlxG.sound:play(Paths:sound(sound), vol or 1)
end

function stopSound(tag)
    if parent.publicVars:exists("PSYCH_SOUND_"..tag) then
        parent.publicVars:get("PSYCH_SOUND_"..tag):stop()
        parent.publicVars:remove("PSYCH_SOUND_"..tag)
    end
end

function pauseSound(tag)
    if parent.publicVars:exists("PSYCH_SOUND_"..tag) then
        parent.publicVars:get("PSYCH_SOUND_"..tag):pause()
    end
end

function resumeSound(tag)
    if parent.publicVars:exists("PSYCH_SOUND_"..tag) then
        parent.publicVars:get("PSYCH_SOUND_"..tag):play()
    end
end

function soundFadeIn(tag, duration, from, to)
    if tag == nil or string.len(tag) < 1 and FlxG.sound.music ~= nil then
        FlxG.sound.music:fadeIn(duration, from or 0, to or 1)
    elseif parent.publicVars:exists("PSYCH_SOUND_"..tag) then
        parent.publicVars:get("PSYCH_SOUND_"..tag):fadeIn(duration, from or 0, to or 1)
    end
end

function soundFadeOut(tag, duration, to)
    if tag == nil or string.len(tag) < 1 and FlxG.sound.music ~= nil then
        FlxG.sound.music:fadeOut(duration, to or 0)
    elseif parent.publicVars:exists("PSYCH_SOUND_"..tag) then
        parent.publicVars:get("PSYCH_SOUND_"..tag):fadeOut(duration, to or 0)
    end
end

function soundFadeCancel(tag)
    if tag == nil or string.len(tag) < 1 and FlxG.sound.music ~= nil and FlxG.sound.music.fadeTween ~= nil then
        FlxG.sound.music.fadeTween:cancel()
    elseif parent.publicVars:exists("PSYCH_SOUND_"..tag) then
        local daSound =  parent.publicVars:get("PSYCH_SOUND_"..tag)
        if daSound.fadeTween ~= nil then
            daSound.fadeTween:cancel()
            parent.publicVars:remove("PSYCH_SOUND_"..tag)
        end
    end
end

function getSoundVolume(tag)
    if tag == nil or string.len(tag) < 1 and FlxG.sound.music ~= nil then
        return FlxG.sound.music.volume
    elseif parent.publicVars:exists("PSYCH_SOUND_"..tag) then
        return parent.publicVars:get("PSYCH_SOUND_"..tag).volume
    end
    return 0
end

function setSoundVolume(tag, vol)
    if tag == nil or string.len(tag) < 1 and FlxG.sound.music ~= nil then
        FlxG.sound.music.volume = vol
    elseif parent.publicVars:exists("PSYCH_SOUND_"..tag) then
        parent.publicVars:get("PSYCH_SOUND_"..tag).volume = vol
    end
end

function getSoundTime(tag)
    if tag == nil or string.len(tag) < 1 and FlxG.sound.music ~= nil then
        return FlxG.sound.music.time
    elseif parent.publicVars:exists("PSYCH_SOUND_"..tag) then
        return parent.publicVars:get("PSYCH_SOUND_"..tag).time
    end
    return 0
end

function setSoundTime(tag, time)
    local daSound = FlxG.sound.music
    if tag ~= nil and string.len(tag) < 1 and parent.publicVars:exists("PSYCH_SOUND_"..tag) then
        daSound = parent.publicVars:get("PSYCH_SOUND_"..tag)
    end

    local wasPlaying = daSound.playing
    daSound:pause()
    daSound.time = time
    if wasPlaying then
        daSound:play()
    end
end

function debugPrint(...)
    local daString = ""
    for i, v in pairs({...}) do
        daString = daString..v
    end

    print(daString)
end

function close()
    removeLuaScript(script.filePath)
    return true
end

function changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp)
    DiscordClient:changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
end

function makeLuaText(tag, text, width, x, y)
    if parent.publicVars:exists("PSYCH_TXT_"..tag) then
        local txt = parent.publicVars:get("PSYCH_TXT_"..tag)
        parent:remove(txt, true)
        spr:destroy()
    end

    local txt = FlxText:new(x, y, width, text, 16)
    txt:setFormat(Paths:font("vcr.ttf"), 16, -1, "center", FlxTextBorderStyle.OUTLINE, -16777216)
    txt.cameras = {parent.camHUD}
    txt.scrollFactor:set(0, 0)
    parent.publicVars:set("PSYCH_TXT_"..tag, txt)
end

function setTextString(tag, text)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        txt.text = text
        return true
    end
    return false
end

function setTextSize(tag, size)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        txt.size = size
        return true
    end
    return false
end

function setTextWidth(tag, width)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        txt.fieldWidth = width
        return true
    end
    return false
end

function setTextBorder(tag, size, color)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        txt.borderSize = size
        txt.color = CoolUtil:stringColor(color)
        return true
    end
    return false
end

function setTextFont(tag, font)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        txt.font = Paths:font(font)
        return true
    end
    return false
end

function setTextItalic(tag, italic)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        txt.italic = italic
        return true
    end
    return false
end

function setTextAlignment(tag, alignment)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        txt.alignment = string.lower(alignment or "left")
        return true
    end
    return false
end

function getTextString(tag)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        return txt.text
    end
    return nil
end

function getTextSize(tag)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        return txt.size
    end
    return -1
end

function getTextFont(tag)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        return txt.font
    end
    return nil
end

function getTextWidth(tag)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        return txt.fieldWidth
    end
    return 0
end

function addLuaText(tag)
    local txt = getProperty(tag)
    if txt ~= nil and Std:isOfType(txt, FlxText) then
        parent:add(txt)
    end
end

function removeLuaText(tag, destroy)
    if parent.publicVars:exists("PSYCH_TXT_"..tag) then
        local txt = parent.publicVars:get("PSYCH_TXT_"..tag)
        parent:remove(txt, true)
        if destroy == nil or destroy then
            txt:destroy()
        end
    end
end

for i, v in pairs({"initSaveData", "flushSaveData", "getDataFromSave", "setDataFromSave"}) do
    _G[v] = function()
        print("Saves are currently not supported in Kade Refreshed!")
    end
end

function checkFileExists(file, absolute)
    local prefix = "assets/"
    if absolute ~= nil and absolute then
        prefix = ""
    end
    return Assets:exists(prefix..file)
end

function saveFile(file, content, absolute)
    local prefix = "assets/"
    if absolute ~= nil and absolute then
        prefix = ""
    end
    local filePath = Assets:getPath(prefix..file)
    if filePath ~= nil then
        File:saveContent(filePath, content)
        return true
    end
    return false
end

function deleteFile(file, ignoreModFolders)
    local ogFoldersToCheck = Assets.foldersToCheck
    if ignoreModFolders ~= nil and ignoreModFolders then
        Assets.foldersToCheck = {"./assets"}
    end
    
    local filePath = Assets:getPath("assets/"..file)
    if filePath ~= nil then
        FileSystem:deleteFile(filePath)
        Assets.foldersToCheck = ogFoldersToCheck
        return true
    end
    Assets.foldersToCheck = ogFoldersToCheck
    return false
end

function getTextFromFile(file, ignoreModFolders)
    local ogFoldersToCheck = Assets.foldersToCheck
    if ignoreModFolders ~= nil and ignoreModFolders then
        Assets.foldersToCheck = {"./assets"}
    end
    
    local daText = Assets:getText("assets/"..file)

    Assets.foldersToCheck = ogFoldersToCheck
    return daText
end

function objectPlayAnimation(obj, name, force, startFrame)
    return playAnim(obj, name, force, false, startFrame)
end

function characterPlayAnim(char, name, force)
    if char == "dad" or char == "opponent" then
        parent.dad:playAnim(name, force)
    elseif char == "gf" or char == "girlfriend" then
        parent.gf:playAnim(name, force)
    else
        parent.boyfriend:playAnim(name, force)
    end
end

function luaSpriteMakeGraphic(tag, width, height, color)
    makeGraphic(tag, width, height, color)
end

function luaSpriteAddAnimationByPrefix(tag, name, prefix, fps, loop)
    addAnimationByPrefix(tag, name, prefix, fps, loop)
end

function luaSpriteAddAnimationByIndices(tag, name, prefix, indices, fps)
    addAnimationByIndices(tag, name, prefix, indices, fps, false)
end

function luaSpritePlayAnimation(tag, name, force)
    playAnim(tag, name, force, false, 0)
end

function setLuaSpriteCamera(tag, cam)
    setObjectCamera(tag, cam)
    return true
end

function setLuaSpriteScrollFactor(tag, x, y)
    setScrollFactor(tag, x, y)
    return true
end

function scaleLuaSprite(tag, x, y)
    scaleObject(tag, x, y, true)
    return true
end

function getPropertyLuaSprite(tag, prop)
    return getProperty(tag.."."..prop)
end

function setPropertyLuaSprite(tag, prop, value)
    return setProperty(tag.."."..prop, value)
end

function musicFadeIn(duration, from, to)
    FlxG.sound.music:fadeIn(duration, from or 0, to or 1)
end

function musicFadeOut(duration, to)
    FlxG.sound.music:fadeOut(duration, to or 0)
end

function directoryFileList(folder)
    return FileSystem:readDirectory(folder)
end

local convertFuncs = {
    {ogFunc = "create",             funcToCall = "onCreate"},
    {ogFunc = "createPost",         funcToCall = "onCreatePost"},
    {ogFunc = "countdownTick",      funcToCall = "onCountdownTick"},
    {ogFunc = "songStart",          funcToCall = "onSongStart"},
    {ogFunc = "update",             funcToCall = "onUpdate"},
    {ogFunc = "updatePost",         funcToCall = "onUpdatePost"},
    {ogFunc = "beatHit",            funcToCall = "onBeatHit"},
    {ogFunc = "stepHit",            funcToCall = "onStepHit"}
}

for i, func in pairs(convertFuncs) do
    _G[func.ogFunc] = function(...)
        if rawget(_G, func.funcToCall) ~= nil then
            rawget(_G, func.funcToCall)(...)
        end
    end
end

function countdownStart()
    if rawget(_G, "onCountdownStart") ~= nil then
        return rawget(_G, "onCountdownStart")() ~= Function_Stop
    end
    return true
end

function enemySing(note) -- This is not in the table bc of how it works.
    if rawget(_G, "opponentNoteHit") ~= nil then
        rawget(_G, "opponentNoteHit")(parent.notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote)
    end
end

function playerSing(note)
    if rawget(_G, "goodNoteHit") ~= nil then
        rawget(_G, "goodNoteHit")(parent.notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote)
    end
end

function playerMiss(direction, note)
    if note == nil and rawget(_G, "noteMissPress") ~= nil then
        rawget(_G, "noteMissPress")(direction)
    elseif rawget(_G, "noteMiss") ~= nil then
        rawget(_G, "noteMiss")(parent.notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote)
    end
end
