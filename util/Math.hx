package util;

class FastTrig {
    static inline var TABLE_SIZE = 1024;
    static var sinTable:Array<Float> = [];
    static var cosTable:Array<Float> = [];

    public static function init() {
        sinTable = [];
        cosTable = [];
        for (i in 0...TABLE_SIZE) {
            var angle = (i / TABLE_SIZE) * Math.PI * 2;
            sinTable[i] = Math.sin(angle);
            cosTable[i] = Math.cos(angle);
        }
    }

    public static inline function sin(angle:Float):Float {
        var idx = Std.int((angle / (Math.PI * 2)) * TABLE_SIZE) & (TABLE_SIZE - 1);
        return sinTable[idx];
    }

    public static inline function cos(angle:Float):Float {
        var idx = Std.int((angle / (Math.PI * 2)) * TABLE_SIZE) & (TABLE_SIZE - 1);
        return cosTable[idx];
    }

    public static inline function fastsin(x:Float):Float {
        // Ограничим x диапазоном [-π, π] для стабильности
        var xx = x % (2 * Math.PI);
        if (xx > Math.PI) xx -= 2 * Math.PI;
        else if (xx < -Math.PI) xx += 2 * Math.PI;

        // Для маленьких углов используем аппроксимацию Тейлора
        if (Math.abs(xx) < 0.5) {
            return xx - (xx*xx*xx)/6;
        }

        // Для больших углов стандартная функция
        return Math.sin(xx);
    }

    public static inline function fastcos(x:Float):Float {
        var xx = x % (2 * Math.PI);
        if (xx > Math.PI) xx -= 2 * Math.PI;
        else if (xx < -Math.PI) xx += 2 * Math.PI;

        if (Math.abs(xx) < 0.5) {
            return 1 - (xx*xx)/2;
        }

        return Math.cos(xx);
    }

    //public static inline function fastsin(x:Float):Float return x - (x*x*x)/6;
    //public static inline function fastcos(x:Float):Float return 1 - (x*x)/2;

    /* public static inline function fastsin(x:Float):Float {
        var xx = x % (2 * Math.PI); // нормализация в [0, 2π)
        if (xx < 0) xx += 2 * Math.PI;

        var sign = 1.0;

        // Используем симметрию по четвертям
        if (xx <= Math.PI/2) {
            // 1-я четверть: [0, π/2] — прямое вычисление
        } else if (xx <= Math.PI) {
            // 2-я четверть: [π/2, π]
            xx = Math.PI - xx;
        } else if (xx <= 3*Math.PI/2) {
            // 3-я четверть: [π, 3π/2]
            xx = xx - Math.PI;
            sign = -1;
        } else {
            // 4-я четверть: [3π/2, 2π]
            xx = 2*Math.PI - xx;
            sign = -1;
        }

        // аппроксимация для первой четверти
        var result = xx - (xx*xx*xx)/6;

        return result * sign;
    }

    public static inline function fastcos(x:Float):Float {
        // cos(x) = sin(x + π/2)
        return fastsin(x + Math.PI/2);
    } */
}

@:structInit
abstract Vec3(Array<Float>) {
    @:arrayAccess public inline function get(i:Int):Float return this[i];
    @:arrayAccess public inline function set(i:Int, v:Float):Float return this[i] = v;

    @:from public static inline function fromArray(a:Array<Float>):Vec3 return cast a;
    @:to public inline function toArray():Array<Float> return this;

    public inline function new(x:Float, y:Float, z:Float) {
        this = [x, y, z];
    }

    public var x(get, set):Float;
    public var y(get, set):Float;
    public var z(get, set):Float;

    inline function get_x() return this[0];
    inline function set_x(v:Float):Float return this[0] = v;

    inline function get_y() return this[1];
    inline function set_y(v:Float):Float return this[1] = v;

    inline function get_z() return this[2];
    inline function set_z(v:Float):Float return this[2] = v;

    public inline function add(b:Vec3):Vec3
        return new Vec3(this[0] + b[0], this[1] + b[1], this[2] + b[2]);

    /* public inline function add(b:Vec3):Vec3 {
        this[0] += b[0];
        this[1] += b[1];
        this[2] += b[2];
        return this;
    } */

    public inline function dot(b:Vec3):Float {
        return this[0] * b[0] + this[1] * b[1] + this[2] * b[2];
    }

    public inline function scale(s:Float):Vec3 {
        this[0] *= s;
        this[1] *= s;
        this[2] *= s;
        return this;
    }

    public inline function length():Float {
        return Math.sqrt(this[0] * this[0] + this[1] * this[1] + this[2] * this[2]);
    }

    public inline function normalize():Vec3 {
        var len = length();
        if (len != 0) {
            var inv = 1.0 / len;
            this[0] *= inv;
            this[1] *= inv;
            this[2] *= inv;
        }
        return this;
    }

    @:op(-A)
    public inline function negate():Vec3 {
        return new Vec3(-this[0], -this[1], -this[2]);
    }

    public static inline function rotate(pos:Vec3, degrees:Float):Vec3 {
        var angle:Float = degrees * Math.PI / 180;

        var _cos:Float = FastTrig.fastcos(angle); var _sin:Float = FastTrig.fastsin(angle);
        var posX = pos[0] * _cos - pos[1] * _sin;
        var posY = pos[0] * _sin + pos[1] * _cos;

        return new Vec3(posX, posY, 0);
    }

    public inline function applyRotation(degrees:Float):Void {
        var angle:Float = degrees * Math.PI / 180;

        var _cos:Float = FastTrig.fastcos(angle); var _sin:Float = FastTrig.fastsin(angle);
        var posX = this[0] * _cos - this[1] * _sin;
        var posY = this[0] * _sin + this[1] * _cos;

        this[0] = posX;
        this[1] = posY;
    }
}