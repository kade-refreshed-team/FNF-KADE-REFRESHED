package debug;

import openfl.geom.Rectangle;
import openfl.media.Sound;
import flixel.system.FlxSound;
import lime.media.AudioBuffer;
import flixel.FlxSprite;

/**
 * I DID NOT MAKE THIS CLASS.
 * THIS WAS TAKEN FROM YOSHI CRAFTER ENGINE. (https://github.com/YoshiCrafter29/YoshiCrafterEngine/blob/main/source/WaveformSprite.hx)
 * THE ONLY THING MODIFIED WAS A VAR REMOVAL AND THE CONSTRUCTOR FUNCTION.
 */
class WaveformSprite extends FlxSprite {
    var buffer:AudioBuffer = null;
    var peak:Float = 0;
    var valid:Bool = true;

    public override function destroy() {
        super.destroy();
        if (buffer != null) {
            buffer.data.buffer = null;
            buffer.dispose();
        }
    }
    public function new(x:Float, y:Float, buffer:Dynamic, w:Int, h:Int) {
        super(x, y);
        var bufferType = Type.typeof(buffer);
        @:privateAccess switch (bufferType) {
            case TClass(FlxSound):
                this.buffer = cast(buffer, FlxSound)._sound.__buffer;
            case TClass(Sound):
                this.buffer = cast(buffer, Sound).__buffer;
            case TClass(AudioBuffer):
                this.buffer = cast(buffer, AudioBuffer);
            default:
                trace('Buffer Type $bufferType is not supported for WaveformSprite.');
                valid = false;
                return;
        }

        peak = Math.pow(2, buffer.bitsPerSample-1)-1; // max positive value of a bitsPerSample bits integer
        makeGraphic(w, h, 0x00000000, true); // transparent
    }

    public function generate(startPos:Int, endPos:Int) {
        if (!valid) return;
        startPos -= startPos % buffer.bitsPerSample;
        endPos -= endPos % buffer.bitsPerSample;
        pixels.lock();
        pixels.fillRect(new Rectangle(0, 0, pixels.width, pixels.height), 0); 
        var diff = endPos - startPos;
        var diffRange = Math.floor(diff / pixels.height);
        for(y in 0...pixels.height) {
            var d = Math.floor(diff * (y / pixels.height));
            d -= d % buffer.bitsPerSample;
            var pos = startPos + d;
            var max:Int = 0;
            for(i in 0...Math.floor(diffRange / buffer.bitsPerSample)) {
                var thing = buffer.data.buffer.get(pos + (i * buffer.bitsPerSample)) | (buffer.data.buffer.get(pos + (i * buffer.bitsPerSample) + 1) << 8);
                if (thing > 256 * 128)
                    thing -= 256 * 256;
                if (max < thing) max = thing;
            }
            var thing = max;
            var w = (thing) / peak * pixels.width;
            pixels.fillRect(new Rectangle((pixels.width / 2) - (w / 2), y, w, 1), 0xFFFFFFFF);
        }
        pixels.unlock();
    }

    public function generateFlixel(startPos:Float, endPos:Float) {
        if (!valid) return;
        var rateFrequency = (1 / buffer.sampleRate);
        var multiplicator = 1 / rateFrequency; // 1 hz/s
        multiplicator *= buffer.bitsPerSample;
        multiplicator -= multiplicator % buffer.bitsPerSample;

        generate(Math.floor(startPos * multiplicator / 4000 / buffer.bitsPerSample) * buffer.bitsPerSample, Math.floor(endPos * multiplicator / 4000 / buffer.bitsPerSample) * buffer.bitsPerSample);
    }

    public function getNumberFromBuffer(pos:Int, bytes:Int):Int {
        var am = 0;
        for(i in 0...bytes) {
            var val = buffer.data.buffer.get(pos + i);
            if (val < 0) val += 256;
            for(i2 in 0...(bytes-i)) val *= 256;
            am += val;
        }
        return am;
    }
}