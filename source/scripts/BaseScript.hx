package scripts;

import openfl.Assets;
import haxe.io.Path;

/**
* Contains the variables used to find a langauge of a script.
*/
typedef ScriptType = {
    /**
    * The extensions for this script type.
    */
    var exts:Array<String>;
    /**
    * The class that will be the instance if the extension of the file is in `exts`.
    */
    var scriptClass:Class<BaseScript>;
    /**
    * Extra parameters used when making the class instance.
    */
    var extraParams:Array<Dynamic>;
}

/**
* Both the base of a script and a class utilized to make scripts.
* Static vars and functions are used for script making,
* and non-static vars are used as the base of a script.
*/
class BaseScript implements flixel.util.FlxDestroyUtil.IFlxDestroyable {
    //SCRIPT BASE HALF

    /**
    * Gets rid of the script to hopefully save memory.
    */
    public function destroy() {}


    public var filePath:String;
    /**
    * The base script contructor.
    * @param   path                 The path to the script.
    */
    public function new(path:String) {filePath = path;}

    /**
     * Initiates the script and it's variables.
     */
    public function execute() {}

    /**
    * Gets a variable from the script.
    * @param   name               The name of the variable.
    */
    public function getVar(name:String):Dynamic {return null;}

    /**
    * Sets a variable from the script.
    * @param   name               The name of the variable.
    * @param   newValue           The new value of the variable.
    */
    public function setVar(name:String, newValue:Dynamic) {}

    /**
    * Calls a function from the script.
    * @param   name               The name of the function.
    * @param   params             The parameters to include when the function is called.
    */
    public function callFunc(name:String, ?params:Array<Dynamic>):Dynamic {return null;}

    /**
     * The script parent of the object.
     * Allows for accessablilty without having to set a variable for the parent.
     * Ex: If the parent was `PlayState.instance` and you want to get `health` from `PlayState.instance`, you can just do `health` instead of `PlayState.instance.health`.
     * You may have to override `get_parent` and `set_parent` if you want to use this in a script.
     */
    public var parent:Dynamic;

    /**
     * The getter function of `parent`.
     * Override this to work with how your script uses the `parent` var.
     */
    private function get_parent():Dynamic {return parent;}

    /**
     * The setter function of `parent`.
     * Override this to work with how your script uses the `parent` var.
     */
    private function set_parent(p:Dynamic):Dynamic {return parent = p;}

    //SCRIPT MAKING HALF

    /**
    * A dynamic function that can be overridden if you're using a different file system.
    */
    public static dynamic function scriptExists(path:String)
        return Assets.exists(path);

    /**
    * A dynamic function that can be overridden if you're want to use or add different default variables.
    */
    public static dynamic function defaultVars():Map<String, Dynamic> {
        return [
            "Math" => Math,
            "Std" => Std,
    
            "FlxG" => flixel.FlxG,
            "FlxSprite" => flixel.FlxSprite,
            "FlxText" => flixel.text.FlxText,
            "FlxTrail" => flixel.addons.effects.FlxTrail,
            "FlxBackdrop" => flixel.addons.display.FlxBackdrop,
    
            "Paths" => utils.Paths,
            "Conductor" => base.Conductor,
            "PlayState" => funkin.PlayState,
    
            "Assets" => Assets
        ];
    }

    /**
    * All the types of scripts it can create.
    */
    public static var scriptTypes:Array<ScriptType> = [
        {exts: ["lua"], scriptClass: scripts.LuaScript, extraParams: [false]}
    ];

    /**
    * Creates a new script.
    * @param   path               The path the function will try to find a scrpt in.
    */
    public static function makeScript(path:String):BaseScript {
        for (type in scriptTypes) {
            for (ext in type.exts) {
                if (scriptExists('$path.$ext')) {
                    var params:Array<Dynamic> = ['$path.$ext'];
                    params = params.concat(type.extraParams);
                    var newScript = Type.createInstance(type.scriptClass, params);
                    var varsToAdd = defaultVars();
                    for (varToAdd in varsToAdd.keys())
                        newScript.setVar(varToAdd, varsToAdd[varToAdd]);
                    return newScript;
                }
            }
        }
        return new BlankScript(path);
    }
}

/**
 * This class is used when a script has failed to create.
 */
class BlankScript extends BaseScript {
    var vars:Map<String, Dynamic> = [];

    /**
    * The blank script contructor.
    * @param   path                 The path to the script. Extremely useless as this script is well, blank.
    */
    public function new(path:String) {
        super(path);
        trace('Script "$path" failed to create. Using a blank script instead.');
    }

    /**
    * Gets a variable from the script.
    * @param   name               The name of the variable.
    */
    override public function getVar(name:String):Dynamic {
        return vars[name];
    }

    /**
    * Sets a variable from the script.
    * @param   name               The name of the variable.
    * @param   newValue           The new value of the variable.
    */
    override public function setVar(name:String, newValue:Dynamic) {
        vars.set(name, newValue);
    }

    /**
    * Calls a function from the script.
    * @param   name               The name of the function.
    * @param   params             The parameters to include when the function is called.
    */
    override public function callFunc(name:String, ?params:Array<Dynamic>):Dynamic {
        super.callFunc(name, params);

        var functionVar = vars[name];
        if (functionVar != null && Reflect.isFunction(functionVar)) {
            var result = (params != null && params.length > 0) ? Reflect.callMethod(null, functionVar, params) : functionVar();
            return result;
        }

        return null;
    }

}