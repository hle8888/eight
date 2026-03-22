//haxe -lib heaps -lib hlsdl -D -O2 -hl ..\out\build.c -main Game -D hlgen.makefile=vs2022 -D analyzer-optimize -D analyzer-user-var-fusion -D analyzer-fusion -D hl-optimize -D hlcunsafe -D release && ..\out\x64\Release\build.exe
//haxe -lib heaps -lib hlsdl -D -O3 -D analyzer-optimize -D analyzer-fusion -hl ..\out\build.c -main Game -D hlgen.makefile=vs2022 && ..\out\x64\Release\build.exe
import Eight;

class Game extends Eight {
	public var bg:Eight.Object;
    public function new() {         
        super();

        bg = new Eight.Object(Engine.n*2, Engine.n2*2, null, 0xFF131413); 
    }

	public static var mx:Float = 100;
    public static var my:Float = 100;
    public static var zoom:Float = 0.8;
    public override function onEvent(event:Event):Bool {
        mx = event.mouseX * Engine.n / screenW;
        my = Engine.n2 - (event.mouseY * Engine.n2 / screenH);
        if (event.type == EventType.MouseDown) {
			//do something
        }
	}
	
	public override function update(dt:Float) {
	
    }
}