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

    public var show:Bool = true;
    public var isUI:Bool = false;

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
        show = visible;
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
        if(!show) return;

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
                    if(tColor != 0x000000) Engine.drawDot(pos.x + rotatedX, pos.y + rotatedY, 0, tColor, isUI);
                } else {
                    Engine.drawDot(pos.x + rotatedX, pos.y + rotatedY, 0, color, isUI);
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
        //return mx > pos[0] - sizeX/2 && mx < pos[0] + sizeX/2 && my > pos[1] - sizeY/2 && my < pos[1] + sizeY/2;
        var worldPos = Engine.screenToWorld(mx, my);
        return worldPos[0] > pos[0] - sizeX/2 
            && worldPos[0] < pos[0] + sizeX/2 
            && worldPos[1] > pos[1] - sizeY/2 
            && worldPos[1] < pos[1] + sizeY/2;
    }

    public function checkSelectUI(mx:Float, my:Float):Bool {
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

    public var ghostTexture:Texture;
    public function setGhost(ghost:Bool = true, step:Int = 3) {
        if (ghost && ghostTexture == null && texture != null) {
            ghostTexture = new Texture(sizeX, sizeY);
            standartTexture = new Texture(sizeX, sizeY);

            var limitX = Std.int(Math.min(sizeX, Engine.n));
            var limitY = Std.int(Math.min(sizeY, Engine.n2));

            for (x in 0...limitX) {
                for (y in 0...limitY) {
                    var c = texture.tex[x][y];

                    // сохраняем оригинал
                    standartTexture.tex[x][y] = c;

                    if (c == 0x000000) {
                        ghostTexture.tex[x][y] = 0x000000;
                        continue;
                    }

                    // сетка
                    if (x % step == 0 || y % step == 0) {
                        ghostTexture.tex[x][y] = 0x00FF00; // яркий зелёный
                    } else {
                        ghostTexture.tex[x][y] = 0x001100; // слабая зелень (полупрозрачный эффект)
                    }
                }
            }
        }

        if (ghost) texture = ghostTexture;
        else if (standartTexture != null) texture = standartTexture;
    }

    public function loadTexture(path:String) {
        texture = TextureManager.loadTexture(path, sizeX, sizeY);
    }
}

class Line extends Object {
    public var pos1:Vec3;
    public var pos2:Vec3;

    public function new(_pos1:Vec3, _pos2:Vec3, texturePath:String=null, _color:Int=0xD6D3D3) {
        super();
        setSize(20, 20);
        color = _color;

        pos1 = _pos1;
        pos2 = _pos2;
    }

    public override function draw() {
        if(!show) return;

        var steps = 100; 
        for (i in 0...steps) {
            var t = i / steps;

            var x = pos1[0] + (pos2[0] - pos1[0]) * t;
            var y = pos1[1] + (pos2[1] - pos1[1]) * t;
            var z = pos1[2] + (pos2[2] - pos1[2]) * t;

            Engine.drawDot(x, y, z, color, isUI);
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
        if(!show) return;
        var steps = 100;

        for (i in 0...steps) {
            var angle = (i / steps) * Math.PI * 2;

            var px = pos[0] + Math.cos(angle) * r;
            var py = pos[1] + Math.sin(angle) * r;
            var pz = 0;

            Engine.drawDot(px, py, pz, color, isUI);
        }
    }

    public override function setOutline(outline:Bool=true) {
        if (selected)
            color = 0x4A9E51;
        else 
            color = 0xD6D3D3;
    }
}

class GPUObject {
    public var x:Float;
    public var y:Float;
    public var r:Float;
    public var color:Float; // упакованный цвет
}

class Eight {
    public static var objects:Array<Object> = []; //objects to draw
    public static var currentSelected:Object;

    public var window:sdl.Window;
    public static var screenW = 1600; public static var screenH = 900;

    public function new() {
        FastTrig.init();
        Sdl.init(); Sdl.setGLOptions(4, 6);

        var mode = Sdl.getCurrentDisplayMode(0);
        screenW = mode.width; screenH = mode.height; var x:Int = 0; var y:Int = 0;
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
    public static var fps:Float = 0.0;
    public static var objectsData:hl.Bytes;
    public static var objSize:Int;
    public function runMainLoop() {
        while(Sdl.processEvents(onEvent) && run) {
            var now = haxe.Timer.stamp();
            var dt = now - lastTime;
            lastTime = now;

            /** Engine.vertices = [];
            var i:Int = -1; while(++i < objects.length) objects[i].draw(); **/

            /* var stride = 4 * 4; // 4 float
            var count = objects.length;
            var bytes = new hl.Bytes(count * stride);
            for (i in 0...count) {
                var o = objects[i];
                var base = i * stride;

                bytes.setF32(base + 0, o.pos.x);
                bytes.setF32(base + 4, o.pos.y);
                bytes.setF32(base + 8, o.sizeX * 0.5); // радиус
                bytes.setF32(base + 12, 0.4); // как float
            } */

            // upload
            //GL.bindBuffer(GL.SHADER_STORAGE_BUFFER, Engine.ssbo);
            //GL.bufferData(GL.SHADER_STORAGE_BUFFER, count * stride, bytes, GL.DYNAMIC_DRAW);
            //GL.bindBufferBase(GL.SHADER_STORAGE_BUFFER, 0, Engine.ssbo);
            
            
            update(dt); for(updateCb in updateCallbacks) updateCb(dt);

            //Engine.drawDot(0, 0, 0); // центр экрана
            //Engine.drawCube(0, 0, 0, 0.5);  // куб в центре экрана, размер 0.5

            var frameTime = (haxe.Timer.stamp() - now);
            var sleep = 1/60 - frameTime;
            if (sleep > 0) sdl.Sdl.delay(Std.int(sleep * 1000));
            fps = 1.0 / frameTime;

            if (Engine.fullQuad) Engine.computeShaders();
            else Engine.computeShaders0();
            window.present();

            var j = timerCallbacks.length; while(--j > -1) {
                var timer = timerCallbacks[j];
                if (timer.timeTrigger < lastTime) {
                    timer.callback();
                    timerCallbacks.splice(j, 1);

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
            if (eventCallbacks[i] == callback) {
                trace('Event callbacks: ${eventCallbacks.length - 1}');
                return eventCallbacks.splice(i, 1);
            }
        throw "Event callback not found!!!";
    }

    static var updateCallbacks:Array<Float->Void> = [];
    public static function registerUpdateCallback(callback:Float->Void) {
        updateCallbacks.push(callback);
        trace('Update callbacks: ${updateCallbacks.length}');
    }

    public static function unregisterUpdateCallback(callback:Float->Void) {
        for(i in 0...updateCallbacks.length) 
            if (updateCallbacks[i] == callback) {
                trace('Update callbacks: ${updateCallbacks.length - 1}');
                return updateCallbacks.splice(i, 1);
            }
        throw "Update callback not found!!!";
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
    public static var zoom:Float = 0.8;
    public static var cameraOffset = new Vec3(0, 0, 0);

    public static var fullQuad = true;

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

    static var shaderCompute:sdl.Program;
    static var shaderRender:sdl.Program;
    static var shaderSpace:sdl.Program;
    public static var ssbo:sdl.Buffer;    
    public static function initShaderEngine() {
        ssbo = GL.createBuffer();
        GL.bindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo);

        //shaderSpace = compileShader(GL.createShader(GL.VERTEX_SHADER), vertexSrcQuad, false);
        //shaderSpace = compileShader(GL.createShader(GL.FRAGMENT_SHADER), fragSrcQuadSpace, true, shaderSpace);

        shaderCompute = compileShader(GL.createShader(GL.COMPUTE_SHADER), shaderSource);
        shaderRender = compileShader(GL.createShader(GL.VERTEX_SHADER), fullQuad ? vertexSrcQuad : vertexSrc, false);
        shaderRender = compileShader(GL.createShader(GL.FRAGMENT_SHADER), fullQuad ? fragSrcQuad : fragSrc, true, shaderRender);
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
            //color = max(max(center, up), max(max(down, left), right)); 

            vec4 c = max(max(center, up), max(max(down, left), right));
            if (c.rgb == vec3(0.0))
                discard;
            color = c;
        }
    ";
    /* static var fragSrcQuad = "#version 430
        in vec2 uv;
        out vec4 color;

        layout(std430, binding = 0) buffer Objects {
            vec4 objs[]; 
            // x,y,r,color
        }; 

        uniform int objCount;
        //uniform vec4 resolution;
        //uniform vec4 camera;

        float intersectCircle(vec2 ro, vec2 rd, vec3 c) {
            vec2 oc = ro - c.xy;
            float b = dot(oc, rd);
            float c2 = dot(oc, oc) - c.z * c.z;
            float h = b*b - c2;
            if (h < 0.0) return -1.0;
            return -b - sqrt(h);
        }

        vec3 unpackColor(float c) {
            int ci = int(c);
            float r = float((ci >> 16) & 255) / 255.0;
            float g = float((ci >> 8) & 255) / 255.0;
            float b = float(ci & 255) / 255.0;
            return vec3(r,g,b);
        } 

        void main() {
            vec2 p = uv * 2.0 - 1.0;
            vec2 res = resolution.xy;
            vec2 cam = camera.xy;

            p.x *= res.x / res.y;

            vec2 ro = cam;
            vec2 rd = normalize(p);

            float tMin = 1e9;
            vec3 col = vec3(0.0);

            for (int i = 0; i < objCount; i++) {
                vec4 o = objs[i];
                float t = intersectCircle(ro, rd, vec3(o.x, o.y, o.z));

                if (t > 0.0 && t < tMin) {
                    tMin = t;
                    col = unpackColor(o.w);
                }
            }

            color = vec4(col, 1.0); 

            color = vec4(0, 0, 0, 0);
        }"; */

    static var fragSrcQuadSpace = "#version 430
        in vec2 uv;
        out vec4 color;

        uniform vec4 uTime;
        uniform vec4 uCamera;

        // простая noise
        float noise(vec2 p) {
            return sin(p.x) * cos(p.y);
        }

        // fbm (фрактальный шум)
        float fbm(vec2 p) {
            float v = 0.0;
            float a = 0.5;

            for (int i = 0; i < 5; i++) {
                v += noise(p) * a;
                p *= 2.0;
                a *= 0.5;
            }

            return v;
        }

        void main() {
            // нормализуем координаты (-1..1)
            vec2 p = uv * 2.0 - 1.0;

            // учитываем камеру (движение по миру)
            vec2 cam = uCamera.xy;
            p += cam * 0.002;

            // масштаб космоса
            vec2 q = p * 3.0;

            float time = uTime.x;
            float v = fbm(q + time * 0.1);

            // нормализация
            v = v * 0.5 + 0.5;

            // цвет космоса
            vec3 col = vec3(
                0.05 + v * 0.4,
                0.02 + v * 0.2,
                0.1 + v * 0.8
            );

            // звезды
            float stars = step(0.97, fract(sin(dot(p * 100.0, vec2(12.9898,78.233))) * 43758.5453));
            col += stars * 1.5;

            color = vec4(col, 1.0);
        }";
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
    static var tex:sdl.Texture;
    public static function createRenderTexture() {	
        //COMPUTED SHADER TEXTURE
        tex = GL.createTexture();
        GL.bindTexture(GL.TEXTURE_2D, tex);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA8, n, n2, 0, GL.RGBA, GL.UNSIGNED_BYTE, null);
        GL.bindImageTexture(1, tex, 0, false, 0, GL.WRITE_ONLY, GL.RGBA8);



        GL.activeTexture(GL.TEXTURE0);
        final dataTexture = GL.createTexture(); 
		GL.bindTexture(GL.TEXTURE_2D, dataTexture);

        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);

        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

        //GL.enable(GL.BLEND);
		//GL.blendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);

        if (fullQuad) defineVertices1();
        else defineVertices0();
    }

    public static inline function defineVertices1() {
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
    }

    public static inline function defineVertices0() {
        vbo = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
        GL.bufferData(GL.ARRAY_BUFFER, 0, null, GL.DYNAMIC_DRAW);
        vao = GL.createVertexArray();
        GL.bindVertexArray(vao);
        final posAttrib = GL.getAttribLocation(shaderRender, 'inPos');
        final colAttrib = GL.getAttribLocation(shaderRender, 'inColor');
        GL.enableVertexAttribArray(posAttrib);
        GL.vertexAttribPointer(posAttrib, 3, GL.FLOAT, false, 24, 0);
        GL.enableVertexAttribArray(colAttrib);
        GL.vertexAttribPointer(colAttrib, 3, GL.FLOAT, false, 24, 12);
    }

    public static inline function computeShadersBackground() {
        GL.clear(GL.COLOR_BUFFER_BIT);
        GL.useProgram(shaderSpace);
        var timeLoc = GL.getUniformLocation(shaderRender, "uTime");
        if (timeLoc != null) {
            var tb = new hl.Bytes(16);
            tb.setF32(0, Eight.lastTime);
            GL.uniform4fv(timeLoc, tb, 0, 1);
        }
        var camLoc = GL.getUniformLocation(shaderRender, "uCamera");
        if (camLoc != null) {
            var cb = new hl.Bytes(16);
            cb.setF32(0, cameraOffset.x);
            cb.setF32(4, cameraOffset.y);
            GL.uniform4fv(camLoc, cb, 0, 1);
        } 
        GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4);
    }

    private static inline function shaderUpdateTexelSize() {
        var texelSizeLoc = GL.getUniformLocation(shaderRender, "uTexelSize");
        var b = new hl.Bytes(4*4);
        b.setF32(0, 1 / n / 2.3);
        b.setF32(4, 1 / n2 / 2.3);
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
        /* GL.clear(GL.COLOR_BUFFER_BIT);
        GL.useProgram(shaderCompute);
        GL.bindBufferBase(GL.SHADER_STORAGE_BUFFER, 0, ssbo);
        GL.uniform1i(GL.getUniformLocation(shaderCompute, "objCount"), Eight.objects.length);

        var resLoc = GL.getUniformLocation(shaderCompute, "resolution");
        var b = new hl.Bytes(16);
        b.setF32(0, n);
        b.setF32(4, n2);
        b.setF32(8, 0);
        b.setF32(12, 0);
        GL.uniform4fv(resLoc, b, 0, 1); 

        GL.bindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo);
        GL.bufferData(GL.SHADER_STORAGE_BUFFER, Eight.objSize, Eight.objectsData, GL.DYNAMIC_DRAW);
        GL.bindBufferBase(GL.SHADER_STORAGE_BUFFER, 0, ssbo);

        GL.dispatchCompute(
            Std.int(Math.ceil(n / 8)),
            Std.int(Math.ceil(n2 / 8)),
            1
        );
        GL.memoryBarrier(GL.ALL_BARRIER_BITS);
        GL.memoryBarrier(GL.SHADER_IMAGE_ACCESS_BARRIER_BIT);

        GL.useProgram(shaderRender);
        GL.activeTexture(GL.TEXTURE0);
        GL.bindTexture(GL.TEXTURE_2D, tex);
        GL.uniform1i(GL.getUniformLocation(shaderRender, "uColorMap"), 0);
        GL.bindVertexArray(vao);
        GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4); */

        /** GL.useProgram(shaderRender);
        GL.uniform1i(GL.getUniformLocation(shaderRender, "objCount"), Eight.objects.length);
        
        var res = new hl.Bytes(16); // 4 float
        res.setF32(0, n);
        res.setF32(4, n2);
        res.setF32(8, 0);
        res.setF32(12, 0);

        GL.uniform4fv(GL.getUniformLocation(shaderRender, "resolution"), res, 0, 1);

        var cam = new hl.Bytes(16);
        cam.setF32(0, cameraOffset.x);
        cam.setF32(4, cameraOffset.y);
        cam.setF32(8, 0);
        cam.setF32(12, 0);

        GL.uniform4fv(GL.getUniformLocation(shaderRender, "camera"), cam, 0, 1);

        GL.useProgram(shaderRender);
        GL.bindVertexArray(vao);
        GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4);  **/


     
        GL.activeTexture(GL.TEXTURE0);
        GL.getBufferSubData(GL.SHADER_STORAGE_BUFFER, 0, data, 0, count);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, n, n2, 0, GL.RGBA, GL.UNSIGNED_BYTE, data);
        GL.useProgram(shaderRender);
        shaderUpdateTexelSize();
        //GL.clear(GL.COLOR_BUFFER_BIT);
        GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4); //GL.drawArrays(GL.GL_POINTS, 0, count);
    }

    public static inline function computeShaders0() {
        var b = new hl.Bytes(vertices.length * 4);
        for (i in 0...vertices.length)
            b.setF32(i * 4, vertices[i]);
        GL.bindBuffer(GL.ARRAY_BUFFER, vbo);
        GL.bufferData(GL.ARRAY_BUFFER, vertices.length * 4, b, GL.DYNAMIC_DRAW);
        GL.useProgram(shaderRender);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
        GL.bindVertexArray(vao);
        GL.drawArrays(GL.TRIANGLES, 0, Std.int(vertices.length / 6));
    }

    public static inline function worldToScreen(x:Float, y:Float):Vec3 {
        return new Vec3(
            (x - cameraOffset[0]),
            (y - cameraOffset[1]),
            0
        );
    }

    public static inline function screenToWorld(x:Float, y:Float):Vec3 {
        return new Vec3(
            x + cameraOffset[0],
            y + cameraOffset[1],
            0
        );
    }

    public static inline function drawDot(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0, color:Int = 0xFF79786B, isUI:Bool=false) {
        var xi = cast x;
        var yi = cast y;
        if (!isUI) {
            var screenPos = worldToScreen(x, y);
            xi = Std.int(screenPos[0]);
            yi = Std.int(screenPos[1]);
        }
        
        if (xi < 1 || yi < 1 || xi > n - 1|| yi > n2 - 1) return;

        data.setI32((yi * n + xi) << 2, color); 
    } 

    public static inline function drawPixel(x:Float, y:Float) {
        drawDot(x, y);
    }
    


    public static inline function v(x:Float, y:Float, z:Float, r:Float, g:Float, b:Float) {
        vertices.push(x); vertices.push(y); vertices.push(z); vertices.push(r); vertices.push(g); vertices.push(b);
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
