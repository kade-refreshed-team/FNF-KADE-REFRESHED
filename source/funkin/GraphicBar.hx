package funkin;

import flixel.graphics.tile.FlxGraphicsShader;
import flixel.util.FlxColor;

class BarShader extends FlxGraphicsShader {
    @:glFragmentSource('
        #pragma header
        
        uniform sampler2D emptyBitmap;
        /*
            I dont think that people are gonna have seperated bitmaps so I only put one bitmap var in the class.
            If you want to do seperaetd bitmaps, do
            shader.data.emptyBitmap.input = Assets.getBitmapData(PATH); (replace `Assets.getBitmapData` with `Assets:getBitmapData` if on lua.)
            shader.data.fillBitmap.input = Assets.getBitmapData(PATH);
        */
        uniform sampler2D fillBitmap;
        uniform vec4 emptyColor;
        uniform vec4 fillColor;
        uniform float percent;
        uniform bool inverted;

        void main() {
            float daX = openfl_TextureCoordv.x;
            if (inverted)
                daX = 1 - openfl_TextureCoordv.x;

            if (daX <= percent) {
                gl_FragColor = texture2D(fillBitmap, openfl_TextureCoordv);
                gl_FragColor = gl_FragColor * fillColor;
            } else {
                gl_FragColor = texture2D(emptyBitmap, openfl_TextureCoordv);
                gl_FragColor = gl_FragColor * emptyColor;
            }
        }
    ')
    public function new() {
        super();
        data.percent.value = [0.5];
        data.inverted.value = [false];
    }
}

class GraphicBar extends flixel.FlxSprite {
    public var graphicPath(default, set):String;
    private function set_graphicPath(path:String):String {
        var barBitmap = openfl.Assets.getBitmapData(Paths.image(path));
        makeGraphic(barBitmap.width, barBitmap.height);
        updateHitbox();
        shader.data.fillBitmap.input = barBitmap;
        shader.data.emptyBitmap.input = barBitmap;

        return graphicPath = path;
    }

    public var emptyColor(default, set):FlxColor;
    private function set_emptyColor(color:FlxColor):FlxColor {
        shader.data.emptyColor.value = [color.redFloat, color.greenFloat, color.blueFloat, color.alphaFloat];
        return emptyColor = color;
    }

    public var fillColor(default, set):FlxColor;
    private function set_fillColor(color:FlxColor):FlxColor {
        shader.data.fillColor.value = [color.redFloat, color.greenFloat, color.blueFloat, color.alphaFloat];
        return emptyColor = color;
    }

    public var percent(default, set):Float = 0.5;
    private function set_percent(value:Float):Float {
        shader.data.percent.value = [value];
        return percent = value;
    }

    public var inverted(default, set):Bool = false;
    private function set_inverted(value:Bool):Bool {
        shader.data.inverted.value = [value];
        return inverted = value;
    }

    public var autoCenter:Bool = true;

    public function new(graphic:String, FillColor:FlxColor, EmptyColor:FlxColor, y:Float) {
        super(0, y);

        shader = new BarShader();

        graphicPath = graphic;
        fillColor = FillColor;
        emptyColor = EmptyColor;
    }

    override public function updateHitbox() {
        super.updateHitbox();
        if (autoCenter)
            screenCenter(X);
    }
}