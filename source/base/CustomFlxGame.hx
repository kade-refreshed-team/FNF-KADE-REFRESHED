package base;

import flixel.FlxG;

/**
 * This class is used to change the `switchState` function a little bit.
 */
class CustomFlxGame extends flixel.FlxGame {
	public static function clearBitmapCache(?ignoreUseCount:Bool = false) {
		@:privateAccess if (FlxG.bitmap._cache == null) {
			FlxG.bitmap._cache = new Map();
			return;
		}

		@:privateAccess for (key in FlxG.bitmap._cache.keys()) {
			var obj = FlxG.bitmap.get(key);
			var isFileAsset = StringTools.startsWith(obj.key, "assets/");
			if (obj != null && (!obj.persist || isFileAsset) && (obj.useCount <= 0 || ignoreUseCount)) {
				FlxG.bitmap.removeKey(key);
				obj.destroy();
			}
		}
	}

    /**
     * Mainly the same as the regular `switchState`, but it accounts for `MusicBeatState`'s `tryCreate` function and the preloader for `PlayState`.
     */
    override function switchState():Void {
		// Basic reset stuff
		FlxG.cameras.reset();
		FlxG.inputs.onStateSwitch();
		FlxG.signals.preStateSwitch.dispatch();

		#if FLX_RECORD
		FlxRandom.updateStateSeed();
		#end

		// Destroy the old state (if there is an old state)
		if (_state != null)
			_state.destroy();

		// we need to clear bitmap cache only after previous state is destroyed, which will reset useCount for FlxGraphic objects
        // doesn't if the requested state is playstate, it's to avoid getting rid of the graphic cache by preloading state.
        // plz don't judge the way i did the if statement.
        if (!(_requestedState is funkin.PlayState)) {
		    clearBitmapCache(true);
			openfl.Assets.cache.clear();
			#if FLX_SOUND_SYSTEM
			FlxG.sound.destroy();
			#end
		}

		// Finally assign and create the new state
		_state = _requestedState;

		if (_gameJustStarted)
			FlxG.signals.preGameStart.dispatch();

		FlxG.signals.preStateCreate.dispatch(_state);

        if (_state is base.MusicBeatState)
		    cast(_state, base.MusicBeatState).tryCreate();
        else
		    _state.create();

		if (_gameJustStarted)
			gameStart();

		#if FLX_DEBUG
		debugger.console.registerObject("state", _state);
		#end

		FlxG.signals.postStateSwitch.dispatch();
	}
}