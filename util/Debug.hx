package util;
import Game.GameObject;
import Eight.*;

class Debug extends GameObject {
    public var index:Int;
    public function new(_index:Int = 0) {
        index = _index;
        super();
    }

    public override function update() {
        FontManager.drawText(text, 0, Engine.n2, index-18*index);
    }
}