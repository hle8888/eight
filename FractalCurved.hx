//haxe -lib heaps -lib hlsdl -D -O2 -hl ..\out\build.c -main Fractal -D hlgen.makefile=vs2022 -D analyzer-optimize -D analyzer-user-var-fusion -D analyzer-fusion -D hl-optimize -D hlcunsafe -D release && ..\out\x64\Release\build.exe
//haxe -lib heaps -lib hlsdl -D -O3 -D analyzer-optimize -D analyzer-fusion -hl ..\out\build.c -main Fractal -D hlgen.makefile=vs2022 && ..\out\x64\Release\build.exe
import Eight;
import sdl.Event;
import util.Math.Vec3;

class Fractal extends Eight {
	public var bg:Eight.Object;
    public var circle:Circle;
    public var dot1:Object;
    public var dot2:Object;

    public var c:Vec3 = new Vec3(200, 300, 0);
    public var r:Int = 150;
    public function new() {         
        super();

        bg = new Eight.Object(Engine.n*2, Engine.n2*2, null, 0xFF131413); 

        circle = new Circle(c, r);
        new Line(new Vec3(c[0]-r, c[1], 0), new Vec3(c[0]+r, c[1], 0));
        new Line(new Vec3(c[0], c[1]-r, 0), new Vec3(c[0], c[1]+r, 0));

        dot1 = new Object(8, 8, null, 0xee4341);
        dot1.pos = new Vec3(c[0]-r, c[1], 0);
        dot2 = new Object(8, 8, null, 0xee4341);
        dot2.pos = new Vec3(c[0], c[1]-r, 0);
    }

	public static var mx:Float = 100;
    public static var my:Float = 100;
    public static var zoom:Float = 0.8;
    public override function onEvent(event:Event):Bool {
        mx = event.mouseX * Engine.n / Eight.screenW;
        my = Engine.n2 - (event.mouseY * Engine.n2 / Eight.screenH);
        if (event.type == EventType.MouseDown) {
			//do something
        }

        return super.onEvent(event);
	}

    var t:Float = 0;
    var colors:Array<Int> = [
        0xbece30,
        0x30ce6d,
        0x3b30ce,
        0xce3058,
        0xa130ce,
        0x4e2831
    ];
	
    var dots:Array<Dot> = [];
    var d1:Float = 100;
    var d2:Float = 100;
    var s1:Float = 1.1; var s1d = 0.001;
    var s2:Float = 1.3; var s2d = 0.001;
    var a1:Float = 1;
    var a2:Float = 1;
    var i:Int = 1550;
	public override function update(dt:Float) {
        dt *= 2;

        bg.setPos(Engine.n/2, Engine.n2/2);

        i++;

        //s1 = 8*Math.PI * Math.sin(t)*2 * i/10000;
        //s2 = 2*Math.PI * Math.sin(t/2*Std.random(7));

        s1 += s1d;
        if (s1 >= 2) s1d = -0.01 * 1;
        if (s1 <= 1) s1d = 0.01 * 1;
        s2 += s2d;
        if (s2 >= 4) s2d = -0.01 * 1;
        if (s2 <= 1) s2d = 0.01 * 1;        

        dot1.pos[0] += d1 * Math.sqrt(s1) * dt;
        dot2.pos[1] += d2 * Math.sqrt(s2) * dt;

        var r2 = 50*Math.sin(t)+100;
        var r3 = 50*Math.cos(t)+100;

        if (dot1.pos[0] <= c[0]-r2) d1 = 100;
        if (dot2.pos[1] <= c[1]-r3) d2 = 100;
        if (dot1.pos[0] >= c[0]+r2) d1 = -100;
        if (dot2.pos[1] >= c[1]+r3) d2 = -100;

        var d = new Dot(4, 4, null, colors[Std.int(t / 10) % 6]);
        d.pos = new Vec3(dot1.pos[0]+500, dot2.pos[1], 0);
        dots.push(d);

        t += dt;

        if(Std.int(t) > 15) {
            var d2 = dots.shift();
            d2.destroy();
        }
    }

    public static function main() {
        var fractal = new Fractal();
        fractal.runMainLoop();
    }
}


class Dot extends Object {
    public var r:Int;

    public function new(sizeX:Int=61, sizeY:Int=61, texturePath:String=null, _color:Int=0x000000) {
        super(sizeX, sizeY, texturePath, _color);
    }

}
