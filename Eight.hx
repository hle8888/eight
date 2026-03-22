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
                    if(tColor != 0x000000) Engine.drawVector(pos.x + rotatedX, pos.y + rotatedY, 0, tColor);
                } else {
                    Engine.drawVector(pos.x + rotatedX, pos.y + rotatedY, 0, color);
                }
            }
        }
    }

    public var outlineTexture:Texture; 
    public var standartTexture:Texture;
    public var selectable:Bool = false;
    public var selected:Bool = false;
    public function select(select:Bool) {
        selected = select;
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

class Eight {
    public static var objects:Array<Object> = []; //objects to draw

    public var window:sdl.Window;
    public var screenW = 1600; public var screenH = 900;

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

            var i:Int = -1; while(++i < objects.length) objects[i].draw(); 
            update(dt);
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
        //result = hl.Bytes.fromBytes(haxe.io.Bytes.alloc(count));
    }

    public static function initShaderEngine() {
        ssbo = GL.createBuffer();
        GL.bindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo);

        //shaderCompute = compileShader(GL.createShader(GL.COMPUTE_SHADER), shaderSource);
        shaderRender = compileShader(GL.createShader(GL.VERTEX_SHADER), vertexSrc, false);
        shaderRender = compileShader(GL.createShader(GL.FRAGMENT_SHADER), fragSrc, true, shaderRender);
    }

    static var shaderSource = "#version 430
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
    ";

    static var vertexSrc = "#version 430
        in vec3 inPos;
        in vec2 inColor;        
        uniform vec4 uTexelSize;
        out vec2 uv;

        //layout(std430, binding = 0) buffer ModelBuffer { vec4 positions[]; };
        //uniform samplerBuffer positions;   // буфер-текстура с твоими vec4
        uniform sampler2D uTexture;   // текстура
        uniform sampler2D uColorMap;  // TEXTURE1
        void main() {
            //gl_Position = texelFetch(uDataTex, ivec2(x,y),0);
            
            //const float PI = 3.14159265359;
            //const float xangle = 0.0;
            //vec2 pos = vec2(cos(xangle * PI / 180) * inPos.x, inPos.y); 

            gl_Position = vec4(inPos, 1.0);               
            uv = inColor;            
        }
    ";
    static var fragSrc = "#version 430
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

            /* //vec4 center = texture(uColorMap, uv);
            float sigmaColor = 0.2; // чувствительность по цвету
            float sigmaSpace = 1.0; // чувствительность по расстоянию
            vec4 sum = vec4(0.0);
            float wsum = 0.0;
            for (int y = -1; y <= 1; ++y) {
                for (int x = -1; x <= 1; ++x) {
                    vec2 offset = vec2(x, y) * vec2(uTexelSize.x, uTexelSize.y);
                    vec4 sampl = texture(uColorMap, uv + offset);

                    float dist2 = float(x*x + y*y);
                    float spaceWeight = exp(-dist2 / (2.0 * sigmaSpace * sigmaSpace));

                    float colorDiff = length(sampl.rgb - center.rgb);
                    float colorWeight = exp(-(colorDiff * colorDiff) / (2.0 * sigmaColor * sigmaColor));

                    float weight = spaceWeight * colorWeight;
                    sum += sampl * weight;
                    wsum += weight;
                }
            }
            color = sum / wsum; */




            /* vec4 sum = vec4(0.0); //color blur
            sum += texture(uColorMap, uv + vec2(-uTexelSize.x,  0.0));
            sum += texture(uColorMap, uv + vec2( uTexelSize.x,  0.0));
            sum += texture(uColorMap, uv + vec2( 0.0, -uTexelSize.y));
            sum += texture(uColorMap, uv + vec2( 0.0,  uTexelSize.y));
            color = (texture(uColorMap, uv) * 2.0 + sum) / 6.0; */

            /* vec4 sum = vec4(0.0);
            int radius = 1;
            int count = 0;
            for (int y = -radius; y <= radius; ++y)
                for (int x = -radius; x <= radius; ++x) {
                    sum += texture(uColorMap, uv + vec2(x, y) * vec2(uTexelSize.x, uTexelSize.y));
                    count++;
                }
            color = sum / float(count); */

            //float contrast = 3.0; 
            //color.rgb = (color.rgb - 0.5) * contrast + 0.5; 
            
            //color = vec4(_inPos * 0.5 + 0.5, 0.0, 1.0); // debuggin red - x, green - y
            //color = vec4(uv, 0.0, 1.0); // debuggin red - x, green - y
        }
    ";

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

    public static function createRenderTexture() {	
        //loading rgb texture in unit 1	
        /*
        final TEXTURE_WIDTH = 512; final TEXTURE_HEIGHT = 512;
		final rawPngData = File.getBytes('rgb.png');
		final pixelsData = haxe.io.Bytes.alloc(TEXTURE_WIDTH * TEXTURE_HEIGHT * 4);
		if (!Format.decodePNG(hl.Bytes.fromBytes(rawPngData), rawPngData.length, pixelsData, TEXTURE_WIDTH, TEXTURE_HEIGHT, 0, PixelFormat.RGBA, 0))
			throw 'Failed to decode PNG data'; 

        GL.activeTexture(GL.TEXTURE1);
        final texture = GL.createTexture(); 
		GL.bindTexture(GL.TEXTURE_2D, texture);
        //GL.bindImageTexture(0, texture, 0, false, 0, GL.READ_WRITE, GL.RGBA8);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, TEXTURE_WIDTH, TEXTURE_HEIGHT, 0, GL.RGBA, GL.UNSIGNED_BYTE, hl.Bytes.fromBytes(pixelsData));
        */

        GL.activeTexture(GL.TEXTURE0);
        final dataTexture = GL.createTexture(); 
		GL.bindTexture(GL.TEXTURE_2D, dataTexture);

        //GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);
        //GL.texParameterf(GL.TEXTURE_2D, GL.TEXTURE_MAX_ANISOTROPY_EXT, 8);
		
        //GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR); 
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);

        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

        //GL.enable(GL.BLEND);
		//GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
        //GL.blendFunc(GL.ONE, GL.ONE); 
        //GL.activeTexture(GL.TEXTURE0);

        final vertecies = Float32Array.fromArray([
            -1,  1, 0.0, 0.0, 1.0,   // pos(x,y,z), uv(u,v)
            -1, -1, 0.0, 0.0, 0.0,
            1,  1, 0.0, 1.0, 1.0,
            1, -1, 0.0, 1.0, 0.0
        ]).getData(); 

        /* final vertices = Float32Array.fromArray([
            // x,  y,  z,   r, g, b, a
            -1,  1, 0.0,   1.0, 0.0, 0.0, 1.0, // красный
            -1, -1, 0.0,   0.0, 1.0, 0.0, 1.0, // зелёный
            1,  1, 0.0,   0.0, 0.0, 1.0, 1.0, // синий
            1, -1, 0.0,   1.0, 1.0, 0.0, 1.0  // жёлтый
        ]).getData(); */

		final vbo = GL.createBuffer();
		GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
		GL.bufferData(GL.ARRAY_BUFFER, vertecies.byteLength, hl.Bytes.fromBytes(vertecies.bytes), GL.STATIC_DRAW);

		final vao = GL.createVertexArray();
		GL.bindVertexArray(vao);

        final posAttrib = GL.getAttribLocation(shaderRender, 'inPos');
		final texAttrib = GL.getAttribLocation(shaderRender, 'inColor');
		GL.enableVertexAttribArray(posAttrib);
		GL.enableVertexAttribArray(texAttrib);
        GL.vertexAttribPointer(posAttrib, 3, GL.FLOAT, false, 20, 0);   // x,y,z
        GL.vertexAttribPointer(texAttrib, 2, GL.FLOAT, false, 20, 12);  // uv

        /* GL.useProgram(shaderRender); //just for displaying texture
        GL.clear(GL.COLOR_BUFFER_BIT);
		GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4); */
    }

    private static inline function shaderUpdateTexelSize() {
        var texelSizeLoc = GL.getUniformLocation(shaderRender, "uTexelSize");
        var b = new hl.Bytes(4*4);
        b.setF32(0, 1 / n);
        b.setF32(4, 1 / n2);
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

        //reading data
        GL.activeTexture(GL.TEXTURE0);
        GL.getBufferSubData(GL.SHADER_STORAGE_BUFFER, 0, data, 0, count);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, n, n2, 0, GL.RGBA, GL.UNSIGNED_BYTE, data);

        GL.useProgram(shaderRender);
        shaderUpdateTexelSize();

        //final texLoc = GL.getUniformLocation(shaderRender, "uColorMap");
        //if (texLoc == null) Sys.println("Uniform uColorMap not found!!!");
        //GL.uniform1i(texLoc, 1); 

        GL.clear(GL.COLOR_BUFFER_BIT);
        GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4); //GL.drawArrays(GL.GL_POINTS, 0, count);
    }

    public static inline function drawVector(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0, color:Int = 0xFF79786B) {
        if (x < 1 || y < 1 || x > n - 1|| y > n2 - 1) return;

        var xi = cast x;
        var yi = cast y;
        data.setI32((yi * n + xi) << 2, color);

        /* data.setI32(((yi+1) * n + xi) << 2, color);
        data.setI32(((yi-1) * n + xi) << 2, color);
        data.setI32((yi * n + (xi+1)) << 2, color);
        data.setI32((yi * n + (xi-1)) << 2, color); */
    }

    public static inline function drawPixel(x:Float, y:Float) {
        drawVector(x, y);
    }

    private static function debug() {
        var s = '';
        for (i in 0...n*n2*l) {
            s = s + ' ' + data.getF32(i*4);
        }
        Sys.println(s + "\n");
    }
}
