package util;

class SeedRandom {
    var seed:Int;

    public function new(seed:Int) {
        if (seed == 0) seed = 1; // нельзя 0
        this.seed = seed;
    }

    inline function next():Int {
        var x = seed;
        x ^= (x << 13);
        x ^= (x >>> 17);
        x ^= (x << 5);
        seed = x;
        return x;
    }

    public inline function randomFloat():Float {
        // 0.0 <= x < 1.0
        var n = next() & 0x7FFFFFFF; // убрать знак
        return n / 2147483648.0;
    }

    public inline function randomInt(max:Int):Int {
        return Std.int(randomFloat() * max);
    }

    public inline function rangeInt(min:Int, max:Int):Int {
        return min + randomInt(max - min + 1);
    }

    public inline function rangeFloat(min:Float, max:Float):Float {
        return min + randomFloat() * (max - min);
    }
}
