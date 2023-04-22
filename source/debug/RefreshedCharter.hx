package debug;

import flixel.util.FlxStringUtil;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxG;
import openfl.Assets;
import lime.media.AudioBuffer;

import debug.WaveformSprite;
import base.Conductor;
import funkin.PlayState;
import funkin.Note;
import ui.HealthIcon;
import utils.CoolUtil;

class RefreshedCharter extends base.MusicBeatState {
    var gridBG:FlxSprite;
    var instWave:WaveformSprite;
    var vocalWave:WaveformSprite;
    var notes:FlxTypedGroup<Note>;
    var sustains:FlxTypedGroup<Note>;
    var hoverArrow:FlxSprite;
    var strumLine:FlxSprite;
    var plIcon:HealthIcon;
    var opIcon:HealthIcon;

    var songIcon:FlxSprite;
    var infoTxt:FlxText;

    var settingsBG:FlxUI9SliceSprite;
    var curSettingTween:FlxTween;
    var curTweenFor:String = "none";

    var selectedNote:Note;
    var curSnap:Float = 1;
    var selectedIndex:Int = 0;

    var vocals:FlxSound;
    var curSection:Int = 0;
    var sectionStart:Float = 0.0;
    var playPlHitsounds:Bool = true;
    var playOpHitsounds:Bool = true;

    override public function create() {
        autoUpdateSongPos = false;
        FlxG.mouse.visible = true;

        if (FlxG.sound.music != null)
            FlxG.sound.music.stop();
        FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.6);
    
        vocals = new FlxSound();
        if (PlayState.SONG.needsVoices)
            vocals.loadEmbedded(Paths.voices(PlayState.SONG.song));
        FlxG.sound.list.add(vocals);
    
        FlxG.sound.music.pause();
        vocals.pause();
    
        FlxG.sound.music.onComplete = function() {
            Conductor.songPosition = Conductor.crochet * (curSection * 4);
            vocals.pause();
            vocals.time = Conductor.songPosition;
            FlxG.sound.music.pause();
            FlxG.sound.music.time = Conductor.songPosition;
            updateCurStep();
            updateBeat();
        }

        var bg = new FlxSprite(0, 0, Paths.image("menu-side/menuDesat"));
        bg.antialiasing = true;
        bg.color = 0xFF186D86;
        add(bg);

        gridBG = FlxGridOverlay.create(40, 40, 320, 640, true, 0xB0FFFFFF, 0x80FFFFFF);
        gridBG.screenCenter(X);
        gridBG.y = 70;
        add(gridBG);

        opIcon = new HealthIcon(PlayState.SONG.player2);
        opIcon.x = 525;
        opIcon.setGraphicSize(75);
        opIcon.updateHitbox();
        add(opIcon);

        plIcon = new HealthIcon(PlayState.SONG.player1);
        plIcon.x = 675;
        plIcon.setGraphicSize(75);
        plIcon.updateHitbox();
        add(plIcon);

        instWave = new WaveformSprite(gridBG.x, gridBG.y, AudioBuffer.fromFile(Assets.getPath(Paths.inst(PlayState.SONG.song))), 320, 640);
        instWave.color = 0xFF26CCFF;
        instWave.visible = false;
        instWave.origin.set();
        add(instWave);

        if (PlayState.SONG.needsVoices) {
            vocalWave = new WaveformSprite(gridBG.x, gridBG.y, AudioBuffer.fromFile(Assets.getPath(Paths.voices(PlayState.SONG.song))), 320, 640);
            vocalWave.color = 0xFF0D648D;
            vocalWave.origin.set();
            add(vocalWave);
        }

        sustains = new FlxTypedGroup<Note>();
        add(sustains);
        notes = new FlxTypedGroup<Note>();
        add(notes);
        Note.reparseNoteTypes();
        Conductor.mapBPMChanges(PlayState.SONG);
        regenNotes();

        hoverArrow = new FlxSprite();
        hoverArrow.frames = Paths.getSparrowAtlas("game-side/NOTE_assets");
        hoverArrow.animation.addByPrefix("0", "purple0");
        hoverArrow.animation.addByPrefix("1", "blue0");
        hoverArrow.animation.addByPrefix("2", "green0");
        hoverArrow.animation.addByPrefix("3", "red0");
        hoverArrow.animation.play("0");
        hoverArrow.colorTransform.redOffset = 255;
        hoverArrow.colorTransform.greenOffset = 255;
        hoverArrow.colorTransform.blueOffset = 255;
        hoverArrow.visible = false;
        hoverArrow.alpha = 0.75;
        hoverArrow.setGraphicSize(40);
        hoverArrow.updateHitbox();
        add(hoverArrow);

        strumLine = new FlxSprite(gridBG.x, 70);
        strumLine.makeGraphic(Std.int(gridBG.width), 5);
        add(strumLine);

        songIcon = new FlxSprite(FlxG.width, 0, Paths.image("menu-side/debug/songSettings"));
        songIcon.scale.set(0.6, 0.6);
        songIcon.updateHitbox();
        songIcon.x -= songIcon.width;
        add(songIcon);
    
        infoTxt = new FlxText(0, 10, songIcon.x, "Test-Song - [HARD]\n\n0:00 / 0:00 | Section: 0\nBeat: 0 | Step: 0", 16);
        infoTxt.setFormat(Paths.font("vcr.ttf"), 16, 0xFFFFFFFF, "right");
        add(infoTxt);

        settingsBG = new FlxUI9SliceSprite(5, 5, Paths.image("menu-side/debug/uiBG"), new flash.geom.Rectangle(0, 0, 200, 200));
        settingsBG.alpha = 0;
	    add(settingsBG);

        Conductor.songPosition = 0;
        updateCurStep();
        updateBeat();
    }

    function regenNotes() {
        if (curTweenFor == "selectNote") {
            curSettingTween.cancel(); //No null check bc curTweenFor wouldn't be set if it was.
            curSettingTween = FlxTween.tween(settingsBG, {x: gridBG.x + gridBG.width - 20, alpha: 0}, 0.1);
            curTweenFor = "deleteNote";
            selectedNote = null;
        }

        curSection = Math.floor(curBeat / 4);

        for (note in notes.members) {
            sustains.remove(note.sustainArray[0], true);
            note.sustainArray[0].destroy();
            note.destroy();
        }
        notes.clear();

        var daBPM:Float = PlayState.SONG.bpm;
        sectionStart = 0.0;
        for (i in 0...curSection) {
            if (PlayState.SONG.notes[i] != null && PlayState.SONG.notes[i].changeBPM)
                daBPM = PlayState.SONG.notes[i].bpm;
            sectionStart += 60 / daBPM * 4000;
        }
        
        while (PlayState.SONG.notes.length < curSection + 1) //If you go too far, it will add sections to prevent a null object reference.
            PlayState.SONG.notes.push({
                sectionNotes: [],
                lengthInSteps: 16,
                typeOfSection: 0,
                mustHitSection: true,
                bpm: daBPM,
                changeBPM: false,
                altAnim: false,
            });

        if (PlayState.SONG.notes[curSection] == null) { //Some charts add null sections soo.....
            PlayState.SONG.notes[curSection] = {
                sectionNotes: [],
                lengthInSteps: 16,
                typeOfSection: 0,
                mustHitSection: true,
                bpm: daBPM,
                changeBPM: false,
                altAnim: false,
            };
        }

        var section = PlayState.SONG.notes[curSection];

        if (section.changeBPM)
            Conductor.changeBPM(section.bpm);
        else
            Conductor.changeBPM(daBPM);

        if (section.mustHitSection) {
            plIcon.x = 525;
            plIcon.flipX = false;
            opIcon.x = 675;
            opIcon.flipX = true;
        } else {
            opIcon.x = 525;
            opIcon.flipX = false;
            plIcon.x = 675;
            plIcon.flipX = true;
        }

        instWave.generateFlixel(sectionStart, sectionStart + Conductor.crochet * 4);
        if (PlayState.SONG.needsVoices)
            vocalWave.generateFlixel(sectionStart, sectionStart + Conductor.crochet * 4);

        for (data in section.sectionNotes) {
            var strumTime = Math.round(data[0] * 100) / 100;
            var noteType:String = (data[3] != null && Note.noteTypes.exists(data[3])) ? data[3] : "Default";

            var note = new Note(strumTime, Std.int(data[1] % 4), noteType);
            note.jsonData = data;
            note.sustainLength = data[2];
            note.setGraphicSize(40);
            note.updateHitbox();
            note.x = gridBG.x + data[1] * 40;
            note.y = gridBG.y + (strumTime - sectionStart) / (Conductor.stepCrochet) * 40;
            
			var holdNote = new Note(note.strumTime, note.noteData, note, true, note.noteType);
			holdNote.animation.play("hold");
            if (holdNote.visible = note.sustainLength > 0)
			    holdNote.setGraphicSize(15, Std.int(40 * (note.sustainLength / Conductor.stepCrochet)));
			holdNote.updateHitbox();
			holdNote.x = note.x + 20 - holdNote.width / 2;
			holdNote.y = note.y + note.height / 2;
			sustains.add(holdNote);
			note.sustainArray.push(holdNote);

            notes.add(note);
        }

        script.callFunc("regenNotes");
    }

    function overlaps(sprite:FlxSprite)
        return FlxG.mouse.screenX >= sprite.x && FlxG.mouse.screenX <= sprite.x + sprite.width && FlxG.mouse.screenY >= sprite.y && FlxG.mouse.screenY <= sprite.y + sprite.height;

    function findAndAction(strumTime:Float, laneID:Int) {
        var section = PlayState.SONG.notes[curSection];
    
        for (i=>data in section.sectionNotes) {
            var roundedStrumTime = Math.round(data[0] * 100) / 100;

            if (roundedStrumTime == strumTime && data[1] == laneID && !FlxG.keys.pressed.CONTROL) {
                var note = notes.members[i];
                var wasSelected = (note.color == 0xFF808080);
                notes.remove(note, true);
                sustains.remove(note.sustainArray[0], true);
                note.sustainArray[0].destroy();
                note.destroy();
                section.sectionNotes.splice(i, 1);
    
                if (curTweenFor == "selectNote" && wasSelected) {
                    curSettingTween.cancel(); //No null check bc curTweenFor wouldn't be set if it was.
                    curSettingTween = FlxTween.tween(settingsBG, {x: gridBG.x + gridBG.width - 20, alpha: 0}, 0.1);
                    curTweenFor = "deleteNote";
                    selectedNote = null;
                }

                return true;
            } else if (roundedStrumTime == strumTime && data[1] == laneID) {
                if (notes.members[i].color == 0xFF808080) {
                    curSettingTween.cancel();
                    curSettingTween = FlxTween.tween(settingsBG, {x: gridBG.x + gridBG.width - 20, alpha: 0}, 0.1);
                    curTweenFor = "deleteNote";
                    notes.members[i].color = 0xFFFFFFFF;
                    selectedNote = null;

                    return true;
                }

                selectNote(notes.members[i], i);
                return true;
            }
        }
    
        return false;
    }

    function selectNote(note:Note, index:Int) {
        for (note in notes.members)
            note.color = 0xFFFFFFFF;

        note.color = 0xFF808080;
        selectedNote = note;
        selectedIndex = index;

        script.callFunc("selectNote");
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        
        if (FlxG.keys.justPressed.ESCAPE) {
            FlxG.mouse.visible = false;
            persistentUpdate = false;
            openSubState(new funkin.PreloadingSubState());
            return;
        } else if (FlxG.keys.justPressed.F5) {
            FlxG.switchState(new RefreshedCharter());
            return;
        }

        if (FlxG.keys.justPressed.SPACE) {
            if (FlxG.sound.music.playing) {
                FlxG.sound.music.pause();
                vocals.pause();
            } else {
                for (note in notes.members)
                    note.hitByBot = (note.strumTime < Conductor.songPosition);

                FlxG.sound.music.play();
                vocals.play();

                FlxG.sound.music.time = Conductor.songPosition;
                vocals.time = Conductor.songPosition;
            }
        }

        var mult:Int = (FlxG.keys.pressed.SHIFT) ? 4 : 1;
        var checks:Array<Dynamic> = [
            [FlxG.sound.music.playing, FlxG.sound.music.time],
            [(FlxG.keys.pressed.W || FlxG.keys.pressed.UP), Conductor.songPosition - elapsed * (500 * mult)],
            [(FlxG.keys.pressed.S || FlxG.keys.pressed.DOWN), Conductor.songPosition + elapsed * (500 * mult)],
            [FlxG.mouse.wheel != 0, Conductor.songPosition - elapsed * (5000 * FlxG.mouse.wheel * mult)],
            [FlxG.keys.justPressed.A, sectionStart - Conductor.crochet * (4 * mult)],
            [FlxG.keys.justPressed.D, sectionStart + Conductor.crochet * (4 * mult) + 1]
        ];

        for (thing in checks) {
            if (thing[0]) {
                Conductor.songPosition = thing[1];
                break;
            }
        }

        if (FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E) {
            curSnap = curSnap * ((FlxG.keys.justPressed.E) ? 0.5 : 2);
            curSnap = Math.min(Math.max(curSnap, 0.125), 4);
        }

        Conductor.songPosition = Math.max(Math.min(Conductor.songPosition, FlxG.sound.music.length), 0);
        updateCurStep();
        updateBeat();

        if (Conductor.songPosition < sectionStart || Conductor.songPosition > sectionStart + Conductor.crochet * 4)
            regenNotes();

        strumLine.y = 70 + (Conductor.songPosition - sectionStart) / (Conductor.stepCrochet) * 40;
        infoTxt.text = '${PlayState.SONG.song} - [${CoolUtil.difficultyString()}]\n\n${FlxStringUtil.formatTime(Conductor.songPosition / 1000, true)} / ${FlxStringUtil.formatTime(FlxG.sound.music.length / 1000, true)} | Section: $curSection\nBeat: $curBeat | Step: $curStep | Snap: 1/${16 / curSnap}';

        if (FlxG.sound.music.playing) {
            for (note in notes.members) {
                var isForPlayer = ((note.jsonData[1] % 8 > 3) != PlayState.SONG.notes[curSection].mustHitSection);
                var playHitsound = (isForPlayer ? playPlHitsounds : playOpHitsounds);
                if (!note.hitByBot && note.strumTime < Conductor.songPosition && playHitsound) {
                    note.hitByBot = true;
                    FlxG.sound.play(Paths.sound(isForPlayer ? "hitsound1" : "hitsound2"));
                }
            }
        }

        if (hoverArrow.visible = overlaps(gridBG)) {
            var mouseSnapped = Math.floor((FlxG.mouse.screenY - 70) / 40 / curSnap);
            var strumTime = sectionStart + (Conductor.stepCrochet * (mouseSnapped * curSnap));
            strumTime = Math.round(strumTime * 100) / 100;
            var laneID = Math.floor((FlxG.mouse.screenX - gridBG.x) / 40);
            
            hoverArrow.x = gridBG.x + laneID * 40;
            hoverArrow.y = gridBG.y + (strumTime - sectionStart) / (Conductor.stepCrochet) * 40;
            hoverArrow.animation.play('${laneID % 4}');
            hoverArrow.setGraphicSize(40);
            hoverArrow.updateHitbox();
            if (FlxG.mouse.justPressed && !findAndAction(strumTime, laneID)) {
                var note = new Note(strumTime, Std.int(laneID % 4), "Default");
                note.setGraphicSize(40);
                note.updateHitbox();
                note.x = hoverArrow.x;
                note.y = hoverArrow.y;
                notes.add(note);
                PlayState.SONG.notes[curSection].sectionNotes.push(note.jsonData = [strumTime, laneID, 0, "Default"]);
                selectNote(note, notes.members.length - 1);

                var holdNote = new Note(note.strumTime, note.noteData, note, true, note.noteType);
                holdNote.animation.play("hold");
                if (holdNote.visible = note.sustainLength > 0)
                    holdNote.setGraphicSize(15, Std.int(40 * (note.sustainLength / Conductor.stepCrochet)));
                else
                    holdNote.setGraphicSize(15, 40);
                holdNote.updateHitbox();
                holdNote.x = note.x + 20 - holdNote.width / 2;
                holdNote.y = note.y + note.height / 2;
                sustains.add(holdNote);
                note.sustainArray.push(holdNote);
            }
        }
    }
}