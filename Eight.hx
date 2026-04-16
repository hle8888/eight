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
    public var zlayer:Int = 0;

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

    public inline function setPosV3(_pos:Vec3) {
        pos = _pos;
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

    public function update(dt:Float) { }

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

    public function setOutline(outline:Bool=true, color:Int=0x2CA52C) {
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
                        outlineTexture.tex[x][y] = color;
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

    public override function setOutline(outline:Bool=true, color:Int=0x2CA52C) {
        if (selected)
            this.color = color;
        else 
            color = 0xD6D3D3;
    }
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

        Engine.allocBuffers();
        Engine.initShaderEngine();
        Engine.createRenderTexture();
        FontManager.initialize();
    }

    public static var lastTime = haxe.Timer.stamp();
    public static var run:Bool = true;
    public static var fps:Float = 0.0;
    public static var objectsData:hl.Bytes;
    public static var objSize:Int;

    public static var bytes:hl.Bytes; 
    public static var distBytes:hl.Bytes;
    public static var voxelCount:Int;
    public static var gridW = 256; public static var gridH = 256; public static var gridD = 256;

    public static var camPos = new Vec3(128, 128, 200);
    public static var target = new Vec3(128, 128, 128);
    public function runMainLoop() {
        var first = true;
        while(Sdl.processEvents(onEvent) && run) {
            var now = haxe.Timer.stamp();
            var dt = now - lastTime;
            lastTime = now;

            //Engine.vertices = [];
            //camPos[0] -= 1 * dt;
            if (first) {
                voxelCount = gridW * gridH * gridD;
                bytes = new hl.Bytes(voxelCount * 4);
                distBytes = new hl.Bytes(voxelCount * 4);
                for (z in 0...gridD)
                for (y in 0...gridH)
                for (x in 0...gridW) {
                    var i = z * gridW * gridH + y * gridW + x;

                    var dx = x - gridW/2;
                    var dy = y - gridH/2;
                    var dz = z - gridD/2;

                    var cx = Std.int(gridW / 2);
                    var cy = Std.int(gridH / 2);
                    var cz = Std.int(gridD / 2);

                    // рисуем только в одном слое (вид сверху)
                    /* if (z == cz) {
                        // ось X (горизонтальная линия)
                        if (y == cy) {
                            bytes.setI32(i * 4, 0xFF0000); // красная
                        }
                        // ось Y (вертикальная линия)
                        else if (x == cx) {
                            bytes.setI32(i * 4, 0x00FF00); // зелёная
                        }
                        else {
                            bytes.setI32(i * 4, 0x000000);
                        }
                    } else {
                        bytes.setI32(i * 4, 0x000000);
                    } */


                    /* if (dx*dx + dy*dy + dz*dz < 30 * 30)
                        bytes.setI32(i * 4, 0xFF0000);
                    else
                        bytes.setI32(i * 4, 0x000000); */

                    var half = 15;
                    var inside =
                        Math.abs(dx) <= half &&
                        Math.abs(dy) <= half &&
                        Math.abs(dz) <= half;
                    var border =
                        Math.abs(dx) == half - 1 ||
                        Math.abs(dy) == half - 1 ||
                        Math.abs(dz) == half - 1;
                    if (inside && border) {
                        bytes.setI32(i * 4, 0xFF0000);
                    } else if (inside)
                        bytes.setI32(i * 4, 0x00FF2A);
                    else
                        bytes.setI32(i * 4, 0x000000);
                    
                } 

                distBytes = buildDistanceField(bytes, gridW, gridH, gridD);

                GL.bindBuffer(GL.SHADER_STORAGE_BUFFER, Engine.ssbo);
                GL.bufferData(GL.SHADER_STORAGE_BUFFER, voxelCount * 4, bytes, GL.DYNAMIC_DRAW);
                GL.bindBufferBase(GL.SHADER_STORAGE_BUFFER, 0, Engine.ssbo); 

                GL.bindBuffer(GL.SHADER_STORAGE_BUFFER, Engine.distSsbo);
                GL.bufferData(GL.SHADER_STORAGE_BUFFER, voxelCount * 4, distBytes, GL.DYNAMIC_DRAW);
                GL.bindBufferBase(GL.SHADER_STORAGE_BUFFER, 1, Engine.distSsbo); 

                first = false;
            }

            var i:Int = -1; while(++i < objects.length) objects[i].draw(); 
            update(dt); for(updateCb in updateCallbacks) updateCb(dt);

            distBytes = buildDistanceField(bytes, gridW, gridH, gridD);

            GL.bindBuffer(GL.SHADER_STORAGE_BUFFER, Engine.ssbo);
            GL.bufferData(GL.SHADER_STORAGE_BUFFER, voxelCount * 4, bytes, GL.DYNAMIC_DRAW);
            GL.bindBufferBase(GL.SHADER_STORAGE_BUFFER, 0, Engine.ssbo); 

            GL.bindBuffer(GL.SHADER_STORAGE_BUFFER, Engine.distSsbo);
            GL.bufferData(GL.SHADER_STORAGE_BUFFER, voxelCount * 4, distBytes, GL.DYNAMIC_DRAW);
            GL.bindBufferBase(GL.SHADER_STORAGE_BUFFER, 1, Engine.distSsbo); 

            //Engine.drawDot(0, 0, 0); // центр экрана
            //Engine.drawCube(0, 0, 0, 0.5);  // куб в центре экрана, размер 0.5

            var frameTime = (haxe.Timer.stamp() - now);
            var sleep = 1/24 - frameTime;
            if (sleep > 0) sdl.Sdl.delay(Std.int(sleep * 1000));
            fps = 1.0 / frameTime;

            Engine.computeShaders();
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

    static inline function voxelIndex(x:Int, y:Int, z:Int, gridW:Int, gridH:Int):Int {
        return z * gridW * gridH + y * gridW + x;
    }

    static function buildDistancePass(src:hl.Bytes, gridW:Int, gridH:Int, gridD:Int, targetFilled:Bool):hl.Bytes {
        var size = gridW * gridH * gridD;
        var dist = new hl.Bytes(size * 4);
        var inf = 1 << 28;

        inline function relax(x:Int, y:Int, z:Int, nx:Int, ny:Int, nz:Int, weight:Int, current:Int):Int {
            if (nx < 0 || ny < 0 || nz < 0 || nx >= gridW || ny >= gridH || nz >= gridD) return current;

            var candidate = dist.getI32(voxelIndex(nx, ny, nz, gridW, gridH) * 4);
            if (candidate >= inf - weight) return current;

            candidate += weight;
            return candidate < current ? candidate : current;
        }

        for (z in 0...gridD)
        for (y in 0...gridH)
        for (x in 0...gridW) {
            var i = voxelIndex(x, y, z, gridW, gridH);
            var filled = src.getI32(i * 4) != 0;
            dist.setI32(i * 4, filled == targetFilled ? 0 : inf);
        }

        for (z in 0...gridD)
        for (y in 0...gridH)
        for (x in 0...gridW) {
            var i = voxelIndex(x, y, z, gridW, gridH);
            var d = dist.getI32(i * 4);

            d = relax(x, y, z, x - 1, y, z, 3, d);
            d = relax(x, y, z, x, y - 1, z, 3, d);
            d = relax(x, y, z, x, y, z - 1, 3, d);

            d = relax(x, y, z, x - 1, y - 1, z, 4, d);
            d = relax(x, y, z, x + 1, y - 1, z, 4, d);
            d = relax(x, y, z, x - 1, y, z - 1, 4, d);
            d = relax(x, y, z, x + 1, y, z - 1, 4, d);
            d = relax(x, y, z, x, y - 1, z - 1, 4, d);
            d = relax(x, y, z, x, y + 1, z - 1, 4, d);

            d = relax(x, y, z, x - 1, y - 1, z - 1, 5, d);
            d = relax(x, y, z, x + 1, y - 1, z - 1, 5, d);
            d = relax(x, y, z, x - 1, y + 1, z - 1, 5, d);
            d = relax(x, y, z, x + 1, y + 1, z - 1, 5, d);

            dist.setI32(i * 4, d);
        }

        for (z in 0...gridD) {
            var zz = gridD - 1 - z;
            for (y in 0...gridH) {
                var yy = gridH - 1 - y;
                for (x in 0...gridW) {
                    var xx = gridW - 1 - x;
                    var i = voxelIndex(xx, yy, zz, gridW, gridH);
                    var d = dist.getI32(i * 4);

                    d = relax(xx, yy, zz, xx + 1, yy, zz, 3, d);
                    d = relax(xx, yy, zz, xx, yy + 1, zz, 3, d);
                    d = relax(xx, yy, zz, xx, yy, zz + 1, 3, d);

                    d = relax(xx, yy, zz, xx + 1, yy + 1, zz, 4, d);
                    d = relax(xx, yy, zz, xx - 1, yy + 1, zz, 4, d);
                    d = relax(xx, yy, zz, xx + 1, yy, zz + 1, 4, d);
                    d = relax(xx, yy, zz, xx - 1, yy, zz + 1, 4, d);
                    d = relax(xx, yy, zz, xx, yy + 1, zz + 1, 4, d);
                    d = relax(xx, yy, zz, xx, yy - 1, zz + 1, 4, d);

                    d = relax(xx, yy, zz, xx + 1, yy + 1, zz + 1, 5, d);
                    d = relax(xx, yy, zz, xx - 1, yy + 1, zz + 1, 5, d);
                    d = relax(xx, yy, zz, xx + 1, yy - 1, zz + 1, 5, d);
                    d = relax(xx, yy, zz, xx - 1, yy - 1, zz + 1, 5, d);

                    dist.setI32(i * 4, d);
                }
            }
        }

        return dist;
    }

    static function buildDistanceField(src:hl.Bytes, gridW:Int, gridH:Int, gridD:Int):hl.Bytes {
        var outside = buildDistancePass(src, gridW, gridH, gridD, true);
        var inside = buildDistancePass(src, gridW, gridH, gridD, false);
        var size = gridW * gridH * gridD;
        var sdf = new hl.Bytes(size * 4);

        for (i in 0...size) {
            sdf.setI32(i * 4, outside.getI32(i * 4) - inside.getI32(i * 4));
        }

        return sdf;
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

    public static inline function distance(pos1:Vec3, pos2:Vec3):Float {
        var dx = pos1[0] - pos2[0];
        var dy = pos1[1] - pos2[1];
        return Math.sqrt(dx*dx + dy*dy);
    }

    public function update(dt:Float) { }
}

class Engine {
    public static var zoom:Float = 1;
    public static var cameraOffset = new Vec3(0, 0, 0);

    static var data:hl.Bytes; 
    static var result:hl.Bytes;
    
    public static var n:Int; 
    public static var n2:Int; 
    static var l = 4;
    
    static var stride:Int; 
    static var count:Int;
    public static function allocBuffers(zoom:Float = 1.5) {
        n = Std.int(888 / zoom); n2 = Std.int(500 / zoom);
        trace(n, n2);

        stride = Std.int(n*l); count = Std.int(n*n2*4);
        data = hl.Bytes.fromBytes(haxe.io.Bytes.alloc(count));
    }

    static var shaderCompute:sdl.Program;
    static var shaderRender:sdl.Program;
    static var shaderSpace:sdl.Program;
    public static var ssbo:sdl.Buffer;   
    public static var distSsbo:sdl.Buffer;
    public static function initShaderEngine() {
        ssbo = GL.createBuffer();
        GL.bindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo);
        distSsbo = GL.createBuffer();

        //shaderSpace = compileShader(GL.createShader(GL.VERTEX_SHADER), vertexSrcQuad, false);
        //shaderSpace = compileShader(GL.createShader(GL.FRAGMENT_SHADER), fragSrcQuadSpace, true, shaderSpace);

        shaderCompute = compileShader(GL.createShader(GL.COMPUTE_SHADER), shaderSource);
        shaderRender = compileShader(GL.createShader(GL.VERTEX_SHADER), vertexSrcQuad, false);
        shaderRender = compileShader(GL.createShader(GL.FRAGMENT_SHADER), fragSrcQuad, true, shaderRender);
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
        in vec2 uv;                   
        uniform sampler2D uTexture;  
        uniform sampler2D uColorMap;  
        uniform vec4 camPos;
        uniform vec4 camForward;
        uniform vec4 camRight;
        uniform vec4 camUp;

        out vec4 color;               // выходной цвет

        layout(std430, binding = 0) buffer Voxels { int voxels[]; };
        layout(std430, binding = 1) buffer DistanceField { int sdf[]; };

        vec3 unpackColor(int c) {
            return vec3(
                float((c >> 16) & 255),
                float((c >> 8) & 255),
                float(c & 255)
            ) * 0.00392156862; // 1/255
        }
        
        ivec3 gridSize() {
            return ivec3(256,256,256);
        }

        int voxelIndex(ivec3 ip, ivec3 grid) {
            return ip.z * grid.x * grid.y + ip.y * grid.x + ip.x;
        }

        float map(vec3 p) {
            ivec3 grid = gridSize();
            ivec3 ip = ivec3(floor(p));

            //if (abs(p.z) > 0.5) return 1000.0; //gridD == 1
            if (ip.x < 0 || ip.y < 0 || ip.z < 0 ||
                ip.x >= grid.x || ip.y >= grid.y || ip.z >= grid.z)
                return 1000.0;

            return float(sdf[voxelIndex(ip, grid)]) / 3.0;
        }

        int sampleVoxelColor(vec3 p) {
            ivec3 grid = gridSize();
            ivec3 ip = ivec3(floor(p));

            for (int z = -1; z <= 1; z++) {
                for (int y = -1; y <= 1; y++) {
                    for (int x = -1; x <= 1; x++) {
                        ivec3 sp = ip + ivec3(x, y, z);
                        if (sp.x < 0 || sp.y < 0 || sp.z < 0 ||
                            sp.x >= grid.x || sp.y >= grid.y || sp.z >= grid.z)
                            continue;

                        int c = voxels[voxelIndex(sp, grid)];
                        if (c != 0) return c;
                    }
                }
            }

            return 0;
        }

        vec3 raymarch(vec3 ro, vec3 rd) {
            float t = 0.0;

            for (int i = 0; i < 256; i++) {
                vec3 p = ro + rd * t;

                float d = map(p);

                if (d < 0.5) {
                    int v = sampleVoxelColor(p);
                    return unpackColor(v);
                }

                t += max(d, 0.5); 

                if (t > 300.0) break;
            }

            return vec3(0.0);
        }

        vec3 getNormal(vec3 p) {
            float e = 1.0;

            float dx = map(p + vec3(e,0,0)) - map(p - vec3(e,0,0));
            float dy = map(p + vec3(0,e,0)) - map(p - vec3(0,e,0));
            float dz = map(p + vec3(0,0,e)) - map(p - vec3(0,0,e));

            return normalize(vec3(dx,dy,dz));
        }

        void main() {
            ivec2 pix = ivec2(gl_FragCoord.xy);
            if (((pix.x ^ pix.y) & 1) == 1) {
                color = vec4(0.0);
                return;
            }


            vec2 res = vec2(888, 500);

            vec2 p = uv * 2.0 - 1.0;
            p.x *= res.x / res.y;

            vec3 ro = camPos.xyz;
            vec3 rd = normalize(
                camForward.xyz +
                p.x * camRight.xyz +
                p.y * camUp.xyz
            );

            vec3 col = vec3(0.0);
            float t = 0.0;

            for (int i = 0; i < 256; i++) {
                vec3 pos = ro + rd * t;
                float d = map(pos);

                if (d < 0.5) {
                    int v = sampleVoxelColor(pos);

                    vec3 n = getNormal(pos);

                    float light = dot(n, normalize(vec3(0.5,1.0,0.3))) * 0.5 + 0.5;

                    col = unpackColor(v) * light;
                    break;
                }

                t += max(d, 0.5);

                if (t > 300.0) break;
            }

            color = vec4(col, 1.0);
        }";

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
     
        GL.activeTexture(GL.TEXTURE0);
        GL.bindBuffer(GL.SHADER_STORAGE_BUFFER, ssbo);
        GL.getBufferSubData(GL.SHADER_STORAGE_BUFFER, 0, data, 0, count);
        GL.texImage2D(GL.TEXTURE_2D, 0, GL.RGBA, n, n2, 0, GL.RGBA, GL.UNSIGNED_BYTE, data);
        GL.useProgram(shaderRender);        
        var b = new hl.Bytes(4*4); b.setF32(0, Eight.camPos[0]); b.setF32(4, Eight.camPos[1]); b.setF32(8, Eight.camPos[2]); b.setF32(12, 0.0); 
        GL.uniform4fv(GL.getUniformLocation(shaderRender, "camPos"), b, 0, 1);

        var ro = Eight.camPos;
        var target = Eight.target; //var target = new Vec3(256, 256, 64);
        var forward = target.sub(ro).normalize();
        b = new hl.Bytes(4*4); b.setF32(0, forward[0]); b.setF32(4, forward[1]); b.setF32(8, forward[2]); b.setF32(12, 0.0); 
        GL.uniform4fv(GL.getUniformLocation(shaderRender, "camForward"), b, 0, 1);

        var upBase = new Vec3(0, 1, 0);
        var right = forward.cross(upBase).normalize();
        b = new hl.Bytes(4*4); b.setF32(0, right[0]); b.setF32(4, right[1]); b.setF32(8, right[2]); b.setF32(12, 0.0); 
        GL.uniform4fv(GL.getUniformLocation(shaderRender, "camRight"), b, 0, 1);
        var up = right.cross(forward);
        b = new hl.Bytes(4*4); b.setF32(0, up[0]); b.setF32(4, up[1]); b.setF32(8, up[2]); b.setF32(12, 0.0); 
        GL.uniform4fv(GL.getUniformLocation(shaderRender, "camUp"), b, 0, 1);

        //GL.uniform4fv(GL.getUniformLocation(shaderRender, "resolution"), res, 0, 1);
        //GL.uniform4fv(GL.getUniformLocation(shaderRender, "camera"), cam, 0, 1);
        //shaderUpdateTexelSize();
        //GL.clear(GL.COLOR_BUFFER_BIT);
        GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4); //GL.drawArrays(GL.GL_POINTS, 0, count);
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

    public static inline function drawDot2(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0, color:Int = 0xFF79786B, isUI:Bool=false) {
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


    static var callOnce = true;
    public static inline function drawDot(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0, color:Int = 0xFF79786B, isUI:Bool=false) {
        //if (!callOnce) return;
        if (isUI) return;
        
        var screenX:Float = x;
        var screenY:Float = y;
        if (!isUI) {
            var screenPos = worldToScreen(x, y);
            screenX = screenPos[0];
            screenY = screenPos[1];
        }
        
        if (screenX < 0 || screenY < 0 || screenX >= n || screenY >= n2) return;

        var xi = Std.int(screenX / n * Eight.gridW);
        var yi = Std.int(screenY / n2 * Eight.gridH);

        if (xi < 0 || yi < 0 || xi >= Eight.gridW || yi >= Eight.gridH) return;

        var i:Int = Std.int(Eight.gridD/2) * Eight.gridW * Eight.gridH + yi * Eight.gridW + xi;        
        Eight.bytes.setI32(i * 4, color); 

        callOnce = false; 
    } 
}
