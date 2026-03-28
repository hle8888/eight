package util;

class Chain {
    var next:Void->Void;

    public function new() {}

    public static function start(fn:Void->Dynamic):Chain {
        var chain = new Chain();
        chain.step(fn);
        return chain;
    }

    inline function step(fn:Void->Dynamic):Dynamic {
        var res = fn();
        return res;
    }

    public inline function then(fn:Void->Dynamic):Chain {
        if (next != null) {
            next = () -> {
                if (fn() != false) next();
            };
        } else {
            if (fn() == false) next = null;
        }
        return this;
    }

    public inline function thenAsync(waiter:(Void->Void)->Void):Chain {
        if (next != null) {
            var cont = next;
            next = () -> waiter(() -> cont());
        } else {
            waiter(() -> {});
        }
        return this;
    }

    public inline function interval(fn:Void->Bool, ms:Int):Chain {
        var t = new haxe.Timer(ms);
        var start = haxe.Timer.stamp(); 

        t.run = function() {
            var cont = fn();
            var elapsed = haxe.Timer.stamp() - start;
            if (!cont || elapsed >= 60.0) {
                t.stop();
                if (next != null) next(); 
            }
        };
        return this;
    }

    public inline function run():Void {
        if (next != null) next();
    }
}
