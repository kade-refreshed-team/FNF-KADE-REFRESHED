package base;

import scripts.BaseScript;
import base.Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState
{
	var script:BaseScript;
	@:unreflective var callCreatePost:Bool = false;

	public function new(?scriptName:String) {
		super();

		if (scriptName == null) {
			var classPath = Type.getClassName(Type.getClass(this));
			scriptName = classPath.substr(classPath.lastIndexOf(".") + 1, classPath.length);
		}

		script = BaseScript.makeScript('assets/data/substates/$scriptName');
		script.parent = this;
		script.setVar("parent", this);
		script.execute();
		script.callFunc("create");
		callCreatePost = true;
	}

	private var autoUpdateSongPos:Bool = false;
	private var floatStep:Float = 0;
	private var curStep:Int = 0;
	private var floatBeat:Float = 0;
	private var curBeat:Int = 0;

	private var controls(get, never):settings.Controls;

	inline function get_controls():settings.Controls
		return settings.PlayerSettings.player1.controls;

	override function tryUpdate(elapsed:Float) {
		if (callCreatePost) {
			script.callFunc("createPost");
			callCreatePost = false;
		}

		if (persistentUpdate || subState == null) {
			script.callFunc("update", [elapsed]);

			if (autoUpdateSongPos) {
				Conductor.lastSongPos = Conductor.songPosition;
				Conductor.songPosition += elapsed * 1000;

				var oldStep:Int = curStep;

				updateCurStep();
				floatBeat = floatStep / 4;
				curBeat = Math.floor(floatBeat);
		
				if (oldStep != curStep && curStep > 0)
					stepHit();
			}
			update(elapsed);

			script.callFunc("updatePost", [elapsed]);
		}

		if (_requestSubStateReset) {
			_requestSubStateReset = false;
			resetSubState();
		}
		if (subState != null)
			subState.tryUpdate(elapsed);
	}

	private function updateCurStep():Void {
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		floatStep = lastChange.stepTime + (Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet;
		curStep = Math.floor(floatStep);
	}

	public function stepHit():Void {
		if (curStep % 4 == 0)
			beatHit();

		script.callFunc("stepHit", [curStep]);
	}

	public function beatHit():Void {
		script.callFunc("beatHit", [curBeat]);
	}
}
