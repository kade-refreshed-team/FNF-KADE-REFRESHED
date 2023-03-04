package scripts;

import hscript.Expr.Error;
import hscript.*;

class HaxeScript extends scripts.BaseScript {
    public static var parser:Parser;
    public var interp:Interp;
    public var expr:Expr;

    public function new(path:String) {
        super(path);

        interp = new Interp();
        if (flixel.FlxG.state is base.MusicBeatState)
            interp.publicVariables = cast (flixel.FlxG.state, base.MusicBeatState).publicVars;
        interp.staticVariables = scripts.BaseScript.staticVars;
        interp.allowStaticVariables = true;
        interp.allowPublicVariables = true;
        interp.errorHandler = traceError;
        try {
            parser.line = 1; //Reset the parser position.
            expr = parser.parseString(openfl.Assets.getText(path), path);
            interp.variables.set("trace", hscriptTrace);
        } catch (e) {
            lime.app.Application.current.window.alert('Hscript file "$path" could not be ran.\n${e.toString()}\nThe game will not utilize this script.', 'Hscript Running Fail');
        }
    }

    function hscriptTrace(v:Dynamic) {
        var posInfos = interp.posInfos();
        trace(posInfos.fileName + ":" + posInfos.lineNumber + ": " + Std.string(v));
    }

    function traceError(e:Error) {
        var errorString:String = e.toString();
        trace(errorString);
    }

    override private inline function get_parent()
        return interp.scriptObject;

    override private inline function set_parent(p:Dynamic)
        return interp.scriptObject = p;

    override inline public function execute() {
        interp.execute(expr);
    }

    override public function getVar(name:String) {
        if (interp == null) return null;
        return interp.variables.get(name);
    }

    override public function setVar(name:String, newValue:Dynamic) {
        if (interp != null)
            interp.variables.set(name, newValue);
    }

    override public function callFunc(name:String, ?params:Array<Dynamic>) {
        if (interp == null || parser == null) return null;

        var functionVar = interp.variables.get(name);
        var hasParams = (params != null && params.length > 0);
        if (functionVar == null || !Reflect.isFunction(functionVar)) return null;
        return hasParams ? Reflect.callMethod(null, functionVar, params) : functionVar();
    }

    public static function initParser() {
        parser = new hscript.Parser();
        parser.allowJSON = true;
        parser.allowMetadata = true;
        parser.allowTypes = true;
        parser.preprocesorValues = [
            "sys" => #if (sys) true #else false #end,
            "desktop" => #if (desktop) true #else false #end,
            "windows" => #if (windows) true #else false #end,
            "mac" => #if (mac) true #else false #end,
            "linux" => #if (linux) true #else false #end,
        ];
    }
}