package menus;

import scripts.BaseScript;

class DoubleScriptTest extends base.MusicBeatState {
    var script1:BaseScript;
    var script2:BaseScript;

    override function create() {
        super.create();
        
        script1 = BaseScript.makeScript('assets/data/iconSPEWWWWWWWWWWWW');
        script1.setVar('parent', this);
        script1.parent = this;
        script1.execute();
        script1.callFunc("create", ["bf", -450]);
        
        script2 = BaseScript.makeScript('assets/data/iconSPEWWWWWWWWWWWW');
        script2.setVar('parent', this);
        script2.parent = this;
        script2.execute();
        script2.callFunc("create", ["gf", 450]);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        
        script1.callFunc("update", [elapsed]);
        script2.callFunc("update", [elapsed]);
    }
}