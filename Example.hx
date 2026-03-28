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
	
    var d1:Float = 100;
    var d2:Float = 100;
    var s1:Int = 1;
    var s2:Int = 1;
	public override function update(dt:Float) {
        bg.setPos(Engine.n/2, Engine.n2/2);

        s1 = Std.random(4) + 1;

        dot1.pos[0] += d1 * s1 * dt;
        dot2.pos[1] += d2 * dt;

        if (dot1.pos[0] <= c[0]-r) d1 = 100;
        if (dot2.pos[1] <= c[1]-r) d2 = 100;
        if (dot1.pos[0] >= c[0]+r) d1 = -100;
        if (dot2.pos[1] >= c[1]+r) d2 = -100;

        var trace = new Object(4, 4, null, 0xbece30);
        trace.pos = new Vec3(dot1.pos[0]+500, dot2.pos[1], 0);
    }

    public static function main() {
        var fractal = new Fractal();
        fractal.runMainLoop();
    }
}
