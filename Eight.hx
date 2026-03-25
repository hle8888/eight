//haxe -lib heaps -lib hlsdl -hl ../out/build.c -main EngineSDL -D hlgen.makefile=vs2022 && ../out/x64/Release/build.exe
//haxe -lib heaps -lib hlsdl -hl ..\out\build.c -main EngineSDL -D hlgen.makefile=vs2022 && ..\out\x64\Release\build.exe
import sdl.GL;
import sdl.Sdl;
import sdl.*;
import haxe.io.UInt8Array;
import haxe.io.Float32Array;
import linc.opengl.*;
import util.Math.Vec3;
import util.Math.FastTrig;
import util.Texture.Texture;
import util.Texture.TextureManager;
import util.Texture.FontManager;

class Object {
    public var pos:Vec3 = [0, 0, 0]; 
    public var angle:Float = 0.0;
    public var localAngle:Float = 0.0;

    public var sizeX:Int = 61; 
    public var sizeY:Int = 61;
    public var sizeZ:Int = 0;

    public var color:Int = 0x000000;
    public var texture:Texture;

    public function new(sizeX:Int=61, sizeY:Int=61, texturePath:String=null, _color:Int=0x000000) {
        setSize(sizeX, sizeY);
        color = _color;
        if (texturePath != null) loadTexture(texturePath);

        Eight.objects.push(this);
    }

    public function destroy():Void {
        var index:Int = Eight.objects.indexOf(this);
        if (index != -1) Eight.objects.splice(index, 1);
    }

    public function setVisible(visible:Bool) {
        var index:Int = Eight.objects.indexOf(this);
        if (visible && index == -1) {
            Eight.objects.push(this);
        } else if (!visible && index != -1) {
            Eight.objects.splice(index, 1);    
        }
    }

    public inline function setPos(x:Float, y:Float, z:Float=0.0) {
        pos = [x, y, z];
    }

    public inline function getCenterPos() {
        return pos.add(-new Vec3(sizeX / 2, sizeY / 2, sizeZ / 2));
    }

    public inline function rotate(degrees:Float) {
        angle += degrees * Math.PI / 180;
        angle = angle % (2*Math.PI);
    }

    public inline function rotateLocal(degrees:Float) {
        localAngle += degrees * Math.PI / 180;
        localAngle = localAngle % (2*Math.PI);
    }

    public inline function getAngle():Float {
        return (angle + localAngle) % (2*Math.PI);
    }

    public inline function setSize(_sizeX:Int, _sizeY:Int) {
        sizeX = _sizeX;
        sizeY = _sizeY;
    }

    public function draw() {
        var _cos:Float = FastTrig.fastcos(getAngle());
        var _sin:Float = FastTrig.fastsin(getAngle());
        var limitX:Int = Std.int(Math.min(sizeX, Engine.n));
        var limitY:Int = Std.int(Math.min(sizeY, Engine.n2));

        var cx:Float = limitX / 2.0;
        var cy:Float = limitY / 2.0;

        var x:Int = limitX; 
        while(x-- > 0) {
            var y:Int = limitY;
            while(y-- > 0) {
                var dx:Float = x - cx;
                var dy:Float = y - cy;

                var rotatedX:Float = dx * _cos - dy * _sin;
                var rotatedY:Float = dx * _sin + dy * _cos;

                if (texture != null) {
                    var tColor:Int = texture.tex[x][y];
                    if(tColor != 0x000000) Engine.drawDot(pos.x + rotatedX, pos.y + rotatedY, 0, tColor);
                } else {
                    Engine.drawDot(pos.x + rotatedX, pos.y + rotatedY, 0, color);
                }
            }
        }
    }

    public var outlineTexture:Texture; 
    public var standartTexture:Texture;
    public var selectable:Bool = false;
    public var selected:Bool = false;
    public function select(isSelected:Bool) {
        selected = isSelected;
        if (isSelected) { //!Std.isOfType(this, Button)
            Eight.currentSelected = this;
            
            setOutline(isSelected);
        }
    }

    public function checkSelect(mx:Float, my:Float):Bool {
        return mx > pos[0] - sizeX/2 && mx < pos[0] + sizeX/2 && my > pos[1] - sizeY/2 && my < pos[1] + sizeY/2;
    }

    public function setOutline(outline:Bool=true) {
        inline function areNeighborsColored(x:Int, y:Int, limitX:Int, limitY:Int):Bool {
            if (x == limitX - 1 || x == 0 || y == limitY - 1 || y == 0) return true;
            if (texture.tex[x][y] == 0) return true; 
            return false;
        }

        if (outline && outlineTexture == null && texture != null) {
            outlineTexture = new Texture(sizeX, sizeY);
            standartTexture = new Texture(sizeX, sizeY);
            
            var _cos:Float = FastTrig.cos(getAngle()); var _sin:Float = FastTrig.sin(getAngle());
            var limitX = Std.int(Math.min(sizeX, Engine.n)); var limitY = Std.int(Math.min(sizeY, Engine.n2));
            for(x in 0...limitX) {
                for(y in 0...limitY) {
                    outlineTexture.tex[x][y] = texture.tex[x][y];
                    standartTexture.tex[x][y] = texture.tex[x][y];
                    if (areNeighborsColored(x, y, limitX, limitY)) {
                        outlineTexture.tex[x][y] = 0x2CA52C;
                    }
                }
            }
        }

        if(outline) texture = outlineTexture;
        else if(standartTexture != null) texture = standartTexture;
    }

    public function loadTexture(path:String) {
        texture = TextureManager.loadTexture(path, sizeX, sizeY);
    }
}

class Line extends Object {
    public var pos1:Vec3;
    public var pos2:Vec3;

    public var show:Bool = true;

    public function new(_pos1:Vec3, _pos2:Vec3, texturePath:String=null, _color:Int=0xD6D3D3) {
        super();
        setSize(20, 20);
        color = _color;

        pos1 = _pos1;
        pos2 = _pos2;
    }

    public override function draw() {
        if (!show) return;

        var steps = 100; 
        for (i in 0...steps) {
            var t = i / steps;

            var x = pos1[0] + (pos2[0] - pos1[0]) * t;
            var y = pos1[1] + (pos2[1] - pos1[1]) * t;
            var z = pos1[2] + (pos2[2] - pos1[2]) * t;

            Engine.drawDot(x, y, z, color);
        }
    }
}

class Circle extends Object {
    public var r:Int;

    public function new(_pos:Vec3, _r:Int, texturePath:String=null, _color:Int=0xD6D3D3) {
        super();
        setSize(_r+4, _r+4);
        color = _color;

        pos = _pos;
        r = _r;
    }

    public override function draw() {
        var steps = 100;

        for (i in 0...steps) {
            var angle = (i / steps) * Math.PI * 2;

            var px = pos[0] + Math.cos(angle) * r;
            var py = pos[1] + Math.sin(angle) * r;
            var pz = 0;

            Engine.drawDot(px, py, pz, color);
        }
    }

    public override function setOutline(outline:Bool=true) {
        if (selected)
            color = 0x4A9E51;
        else 
            color = 0xD6D3D3;
    }
}

class Eight {
    public static var zoom:Float = 0.8;
    public static var cameraOffset = new Vec3(0, 0, 0);

    public static var objects:Array<Object> = []; //objects to draw
    public static var currentSelected:Object;

    public var window:sdl.Window;
    public static var screenW = 1600; public static var screenH = 900;

    public function new() {
        FastTrig.init();
        Sdl.init(); Sdl.setGLOptions(4, 6);

        var mode = Sdl.getCurrentDisplayMode(0);
        screenW = mode.width; screenH = mode.height; var x:Int = 0; var y:Int = 0;
        //screenW = 888; screenH = 500; x = 4; y = 250;
        window = new sdl.Window('', screenW, screenH, x, y, sdl.Window.SDL_WINDOW_OPENGL);
        window.title = 'VoidDwellers';

        GL.init(); if (!GL.init()) return trace('GL.init() failed');
        GL.viewport(0, 0, screenW, screenH);
        GL.clearColor(0.5, 0.5, 0.5, 1.0);

        Engine.allocBuffers(0.8);
        Engine.initShaderEngine();
        Engine.createRenderTexture();
        FontManager.initialize();
    }

    public static var lastTime = haxe.Timer.stamp();
    public static var run:Bool = true;
    public function runMainLoop() {
        while(Sdl.processEvents(onEvent) && run) {
            var now = haxe.Timer.stamp();
            var dt = now - lastTime;
            lastTime = now;

            Engine.vertices = [];
            var i:Int = -1; while(++i < objects.length) objects[i].draw(); 
            update(dt);

            //Engine.drawDot(0, 0, 0); // центр экрана
            //Engine.drawCube(0, 0, 0, 0.5);  // куб в центре экрана, размер 0.5

            Engine.computeShaders();
            window.present();

            var frameTime = (haxe.Timer.stamp() - now);
            var sleep = 1/60 - frameTime;
            //if (sleep > 0) sdl.Sdl.delay(Std.int(sleep * 1000));

            i = timerCallbacks.length; while(--i > -1) {
                var timer = timerCallbacks[i];
                if (timer.timeTrigger < lastTime) {
                    timer.callback();
                    timerCallbacks.splice(i, 1);

                    trace('Timer fired: ${timer.timeTrigger}, ${timer.callback}');
                }
            }
        }
    }

    public static inline function delay(ms:Int) sdl.Sdl.delay(ms);

    static var timerCallbacks:Array<{timeTrigger: Float, callback:Void->Void}> = [];
    public static function wait(timeTrigger:Float, callback:Void->Void) {
        timerCallbacks.push({timeTrigger: lastTime + timeTrigger, callback: callback});
        trace('Timer registered: ${timeTrigger}');
    }

    static var eventCallbacks:Array<sdl.Event->Void> = [];
    public static function registerEventCallback(callback:sdl.Event->Void) {
        wait(0.1, () -> {
            eventCallbacks.push(callback);
            trace('Event callbacks: ${eventCallbacks.length}');
        });
    }

    public static function unregisterEventCallback(callback:sdl.Event->Void) {
        for(i in 0...eventCallbacks.length) 
            if (eventCallbacks[i] == callback) return eventCallbacks.splice(i, 1);
        throw "Event callback not found!!!";
    }

    public function onEvent(event:sdl.Event):Bool {
        var i:Int = -1; while(++i < eventCallbacks.length) {
            eventCallbacks[i](event);
        }
        return true;
    }

    public function update(dt:Float) { }

    public static inline function distance(pos1:Vec3, pos2:Vec3):Float {
        var dx = pos1[0] - pos2[0];
        var dy = pos1[1] - pos2[1];
        return Math.sqrt(dx*dx + dy*dy);
    }
}

class Engine {
    static var fullscreenQuad = true;

    static var data:hl.Bytes; 
    static var result:hl.Bytes;
    
    public static var n:Int; 
    public static var n2:Int; 
    static var l = 4;
    
    static var stride:Int; 
    static var count:Int;
    public static function allocBuffers(zoom:Float = 1) {
        n = Std.int(888 / zoom); n2 = Std.int(500 / zoom);
        trace(n, n2);

        stride = Std.int(n*l); count = Std.int(n*n2*4);
        data = hl.Bytes.fromBytes(haxe.io.Bytes.alloc(count));
    }

    public static function initShaderEngine() {
        ssbo = GL.createBuffer();
        GL.bindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo);

        //shaderCompute = compileShader(GL.createShader(GL.COMPUTE_SHADER), shaderSource);
        shaderRender = compileShader(GL.createShader(GL.VERTEX_SHADER), fullscreenQuad ? vertexSrcQuad : vertexSrc, false);
        shaderRender = compileShader(GL.createShader(GL.FRAGMENT_SHADER), fullscreenQuad ? fragSrcQuad : fragSrc, true, shaderRender);
    }

    /* static var shaderSource = "#version 430
            layout(local_size_x = 1, local_size_y = 1) in; 
            struct XYZW { float x; float y; float z; float w; }; layout(std430, binding = 0) buffer Data { XYZW values[]; };
            //layout(rgba32f, binding = 1) uniform image2D outImage;
            void main() {
                uvec2 gid = gl_GlobalInvocationID.xy;
                ivec2 pixel = ivec2(gid);

                uint i = gl_GlobalInvocationID.x;
                float x = values[i].x; float y = values[i].y; float z = values[i].z; float w = values[i].w;
                values[i].x = x; //cos(x*x + y*y) * w;
                values[i].y = y; //sin(x*x + z*z) * w;
                values[i].z = z; // оставляем как есть или делаем вычисление
                values[i].w = w; // оставляем как есть или делаем вычисление

                //imageStore(outImage, pixel, vec4(1.0, 0.0, 0.0, 1.0)); 
            }
    "; */
    //FULLSCREEN QUAD
    static var vertexSrcQuad = "#version 430
        in vec3 inPos;
        in vec2 inColor;        
        uniform vec4 uTexelSize;
        out vec2 uv;

        uniform sampler2D uTexture;   // текстура
        uniform sampler2D uColorMap;  // TEXTURE1
        void main() {
            gl_Position = vec4(inPos, 1.0);               
            uv = inColor;            
        }
    ";
    static var fragSrcQuad = "#version 430
        in vec2 uv;                   // получаем UV
        uniform sampler2D uTexture;   // текстура
        uniform sampler2D uColorMap;  // TEXTURE1
        uniform vec4 uTexelSize;
        out vec4 color;               // выходной цвет
        void main() {
            vec4 center = texture(uColorMap, uv);
            vec4 up    = texture(uColorMap, uv + vec2(0.0, uTexelSize.y));
            vec4 down  = texture(uColorMap, uv + vec2(0.0, -uTexelSize.y));
            vec4 left  = texture(uColorMap, uv + vec2(-uTexelSize.x, 0.0));
            vec4 right = texture(uColorMap, uv + vec2( uTexelSize.x, 0.0));
            color = max(max(center, up), max(max(down, left), right)); 
        }
    "; 
    //STANDART PIPELINE
    static var vertexSrc = "#version 430
        in vec3 inPos;
        in vec3 inColor;

        uniform mat4 uProjection;
        uniform mat4 uView;

        out vec3 vColor;

        void main() {
            //gl_Position = uProjection * uView * vec4(inPos, 1.0);
            gl_Position = vec4(inPos, 1.0);
            vColor = inColor;
        }";

    static var fragSrc = "#version 430
        in vec3 vColor;
        out vec4 color;
        void main() {
            color = vec4(vColor, 1.0);
        }";

    static var shaderCompute:sdl.Program;
    static var shaderRender:sdl.Program;
    static var ssbo:sdl.Buffer;    
    public static function compileShader(shader, source, link = true, prog = null) {
        GL.shaderSource(shader, source);
        GL.compileShader(shader);
        if (GL.getShaderParameter(shader, GL.COMPILE_STATUS) == 0) 
            throw "Shader compilation failed:\n" + GL.getShaderInfoLog(shader);

        if (prog == null) prog = GL.createProgram();
        GL.attachShader(prog, shader);
        
        if (link == false) return prog;
        GL.linkProgram(prog);
        if (GL.getProgramParameter(prog, GL.LINK_STATUS) == 0) 
            throw "Program link failed:\n" + GL.getProgramInfoLog(prog);

        return prog;
    } 

    public static var vertices:Array<Float> = [];
    public static var vbo:sdl.Buffer;
    public static var vao:sdl.VertexArray;
    public static function createRenderTexture() {	
        GL.activeTexture(GL.TEXTURE0);
        final dataTexture = GL.createTexture(); 
		GL.bindTexture(GL.TEXTURE_2D, dataTexture);

        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);

        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

        final vertices = Float32Array.fromArray([
            -1,  1, 0.0, 0.0, 1.0,   // pos(x,y,z), uv(u,v)
            -1, -1, 0.0, 0.0, 0.0,
            1,  1, 0.0, 1.0, 1.0,
            1, -1, 0.0, 1.0, 0.0
        ]).getData(); 

		final vbo = GL.createBuffer();
		GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
		GL.bufferData(GL.ARRAY_BUFFER, vertices.byteLength, hl.Bytes.fromBytes(vertices.bytes), GL.STATIC_DRAW);

		final vao = GL.createVertexArray();
		GL.bindVertexArray(vao);

        final posAttrib = GL.getAttribLocation(shaderRender, 'inPos');
		final texAttrib = GL.getAttribLocation(shaderRender, 'inColor');
		GL.enableVertexAttribArray(posAttrib);
		GL.enableVertexAttribArray(texAttrib);
        GL.vertexAttribPointer(posAttrib, 3, GL.FLOAT, false, 20, 0);   // x,y,z
        GL.vertexAttribPointer(texAttrib, 2, GL.FLOAT, false, 20, 12);  // uv 


        /* vbo = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vbo);

        // пока пустой буфер
        GL.bufferData(GL.ARRAY_BUFFER, 0, null, GL.DYNAMIC_DRAW);

        vao = GL.createVertexArray();
        GL.bindVertexArray(vao);

        final posAttrib = GL.getAttribLocation(shaderRender, 'inPos');
        final colAttrib = GL.getAttribLocation(shaderRender, 'inColor');

        GL.enableVertexAttribArray(posAttrib);
        GL.vertexAttribPointer(posAttrib, 3, GL.FLOAT, false, 24, 0);

        GL.enableVertexAttribArray(colAttrib);
        GL.vertexAttribPointer(colAttrib, 3, GL.FLOAT, false, 24, 12); */
    }

    private static inline function shaderUpdateTexelSize() {
        var texelSizeLoc = GL.getUniformLocation(shaderRender, "uTexelSize");
        var b = new hl.Bytes(4*4);
        b.setF32(0, 1 / n / 2);
        b.setF32(4, 1 / n2 / 2);
        b.setF32(8, 0);
        b.setF32(12, 0);
        GL.uniform4fv(texelSizeLoc, b, 0, 1);
    }
    
    public static inline function computeShaders() {
        /* GL.bufferData(GL.SHADER_STORAGE_BUFFER, count * stride, data, GL.DYNAMIC_DRAW);
        GL.bindBufferBase(GL.SHADER_STORAGE_BUFFER, 0, ssbo);
        GL.useProgram(shaderCompute);
        GL.dispatchCompute(n, n, 1);
        GL.memoryBarrier(GL.SHADER_STORAGE_BARRIER_BIT); */

        
        
     
        GL.activeTexture(GL.TEXTURE0);
        GL.getBufferSubData(GL.SHADER_STORAGE_BUFFER, 0, data, 0, count);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, n, n2, 0, GL.RGBA, GL.UNSIGNED_BYTE, data);

        GL.useProgram(shaderRender);
        shaderUpdateTexelSize();
        GL.clear(GL.COLOR_BUFFER_BIT);
        GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4); //GL.drawArrays(GL.GL_POINTS, 0, count); 

        /* var b = new hl.Bytes(vertices.length * 4);
        for (i in 0...vertices.length)
            b.setF32(i * 4, vertices[i]);

        GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
        GL.bufferData(GL.ARRAY_BUFFER, vertices.length * 4, b, GL.DYNAMIC_DRAW);

        GL.useProgram(shaderRender);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);

        GL.bindVertexArray(vao);

        // количество вершин = vertices.length / 3
        GL.drawArrays(GL.TRIANGLES, 0, Std.int(vertices.length / 6)); */
    }

    public static inline function drawDot(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0, color:Int = 0xFF79786B) {
        if (x < 1 || y < 1 || x > n - 1|| y > n2 - 1) return;

        var xi = cast x;
        var yi = cast y;
        data.setI32((yi * n + xi) << 2, color); 
    } 

    public static inline function drawPixel(x:Float, y:Float) {
        drawDot(x, y);
    }

    private static function debug() {
        var s = '';
        for (i in 0...n*n2*l) {
            s = s + ' ' + data.getF32(i*4);
        }
        Sys.println(s + "\n");
    }

    public static inline function v(x:Float, y:Float, z:Float, r:Float, g:Float, b:Float) {
        vertices.push(x);
        vertices.push(y);
        vertices.push(z);
        vertices.push(r);
        vertices.push(g);
        vertices.push(b);
    }

    public static inline function unpackColor(color:Int) {
        var r = ((color >> 16) & 0xFF) / 255.0;
        var g = ((color >> 8) & 0xFF) / 255.0;
        var b = (color & 0xFF) / 255.0;
        return { r:r, g:g, b:b };
    }

    public static inline function drawDotV(x:Float = 0.0, y:Float = 0.0, z:Float = -2.0, color:Int = 0xFF79786B) {
        var nx = (x / n) * 2.0 - 1.0;
        //var ny = 1.0 - (y / n2) * 2.0;
        var ny = (y / n2) * 2.0 - 1.0;

        var sx = 2.0 / n;
        var sy = 2.0 / n2;

        var hx = sx * 0.5;
        var hy = sy * 0.5;

        var c = unpackColor(color);

        v(nx-hx, ny+hy, 0, c.r, c.g, c.b);
        v(nx-hx, ny-hy, 0, c.r, c.g, c.b);
        v(nx+hx, ny-hy, 0, c.r, c.g, c.b);
        v(nx-hx, ny+hy, 0, c.r, c.g, c.b);
        v(nx+hx, ny-hy, 0, c.r, c.g, c.b);
        v(nx+hx, ny+hy, 0, c.r, c.g, c.b);
    }
}
