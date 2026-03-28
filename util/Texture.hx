package util;
import haxe.ds.StringMap;
import haxe.io.BytesInput;
import sys.io.File;
import hl.Format;
import Eight;
import objects.Objects;

class Texture {
    public var tex:Array<Array<Int>> = [];

    public function new(sizeX:Int, sizeY:Int) {
        tex = [for (x in 0...sizeX) [for (y in 0...sizeY) 0]];
    }
}

class Button extends GameObject {
    public var word:String;
    public var clicked:Void->Void;

    public function new(_word:String, x:Int=0, y:Int=0, background:String='button.png') {
        super(100, 18, background);
        selectable = true;
        word = _word;
        pos[0] = x; pos[1] = y;
        isUI = true;
    }

    public override function select(isSelected:Bool) {
        selected = isSelected;
        if(isSelected && clicked != null) {
            trace('Clicked button "${word}"');
            clicked();
        }
    }

    public override function draw() {
        super.draw();
        var i:Int = word.length;
        while(i-- > 0) {
            var index:Int = FontManager.letters.indexOf(word.charAt(i));
            if (index == -1) continue;

            FontManager.drawKey(word.charAt(i), pos[0]-sizeX/2+i*22*FontManager.sZ, pos[1]-9);
        }
    }
}

class FontManager {
    public static var font:Texture;
    public static var letters:String;
    public static var keyTex:StringMap<Texture> = new StringMap();
    public static var size:Int = 512;
    public static var sZ:Float = 0.5;//0.363636364;

    public static function initialize() {
        font = TextureManager.loadTexture('font.png', Std.int(size*sZ), Std.int(size*sZ));
        letters = "Q WERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghklzxcvbnm[]{};:\"'|,.<>?!@#$%^&*()-=_=1234567890";

        loadLetterTextures();
    }

    public static function loadLetterTextures() {
        for (index in 0...letters.length) {
            var xi = ((index % 22) * Std.int(22*sZ)) + Std.int(8*sZ);
            var yi = Std.int(size*sZ-1-(Std.int(index / 22) * 38*sZ) - 8*sZ);

            keyTex.set('key'+letters.charAt(index), makeTexture(xi, yi));
        }
    }

    public static function drawText(word:String, x:Int, y:Int, background:Int=0) {
        var i:Int = word.length;
        while(i-- > 0) {
            var index = FontManager.letters.indexOf(word.charAt(i));
            if (index == -1) continue;

            FontManager.drawKey(word.charAt(i), x+i*Std.int(22*FontManager.sZ), y, background);
        }
    }

    public static function drawKey(key:String, x:Float, y:Float, background:Int=0) {
        var texture = keyTex.get('key'+key);
        var i:Int = Std.int(22*sZ);
        while(i-- > 0) {
            var j:Int = Std.int(38*sZ);
            while(j-- > 0) {
                var color = texture.tex[i][j];
                if(color != 0) {
                    Engine.drawDot(x+i, y+j, 0, color, true);
                } 
            }
        }
    }

    public static function makeTexture(xi:Int, yi:Int):Texture {
        var texture = new Texture(Std.int(22*sZ), Std.int(38*sZ));

        for(y in yi-Std.int(30*sZ)...yi+Std.int(8*sZ)) {
            for(x in xi...xi+Std.int(22*sZ)) {
                var color = font.tex[x][y];
                texture.tex[x-xi][y-yi+Std.int(30*sZ)] = color;
                /* if(color != 0) {
                    Engine.drawVector(x, y, 0, 0xffffff);
                } else {
                    Engine.drawVector(x, y, 0, 0xc21616);
                } */
            }
        }

        return texture;
    }
}

class TextureManager {
    public static var textures:StringMap<Texture> = new StringMap();

    public static function loadTexture(path:String, width:Int=61, height:Int=61):Texture {
        path = "textures/"+path;

        var result:Texture = textures.get(path);
        if (result != null) return result;

        var png = getPng(path);
        trace(path, png.width, png.height);

		var rawPngData = png.bytes; // File.getBytes(path);
		var pixelsData = haxe.io.Bytes.alloc(png.width * png.height * 4);
		if (!Format.decodePNG(hl.Bytes.fromBytes(rawPngData), rawPngData.length, pixelsData, png.width, png.height, 0, PixelFormat.RGBA, 0))
			throw 'Failed to decode PNG data';

        pixelsData = blurGaussian(pixelsData, png.width, png.height, 2);
        //pixelsData = resizeLanczos(pixelsData, png.width, png.height, width, height, 1);
        pixelsData = resizeBilinear(pixelsData, png.width, png.height, width, height);
        //pixelsData = blurGaussian(pixelsData, width, height, 1);
        

        var texture = new Texture(width, height); var i = 0;
        trace('Texture', width, height);
        for (y in 0...height) {
            for (x in 0...width) {
                var r = pixelsData.get(i);
                var g = pixelsData.get(i + 1);
                var b = pixelsData.get(i + 2);
                var a = pixelsData.get(i + 3);
                i += 4;

                if (a < 32) continue; // пропускаем прозрачные

                //var color = (r << 16) | (g << 8) | b;
                //var color = (a << 24) | (r << 16) | (g << 8) | b;
                var color = (b << 16) | (g << 8) | r;

                //texture.tex[height-1-y][x] = color;
                texture.tex[x][height-1-y] = color;
            }
        } 

        textures.set(path, texture);
        return texture;
    }

    static function getPng(path:String):{bytes:haxe.io.Bytes, width:Int, height:Int} {
        var bytes = File.getBytes(path);
        var input = new BytesInput(bytes);

        input.read(8);
        input.readInt32();

        var name = input.readString(4);
        if (name != "IHDR") throw "Invalid PNG: missing IHDR";

        return { bytes: bytes, width: readInt32BE(input), height: readInt32BE(input) };
    }

    static function readInt32BE(input:BytesInput):Int {
        var b1 = input.readByte();
        var b2 = input.readByte();
        var b3 = input.readByte();
        var b4 = input.readByte();
        return (b1 << 24) | (b2 << 16) | (b3 << 8) | b4;
    }

    static function resize(data:haxe.io.Bytes, w:Int, h:Int, newW:Int, newH:Int):haxe.io.Bytes {
        var result = haxe.io.Bytes.alloc(newW * newH * 4);
        for (y in 0...newH)
            for (x in 0...newW) {
                var srcX = Std.int(x * w / newW);
                var srcY = Std.int(y * h / newH);
                var srcIdx = (srcY * w + srcX) * 4;
                var dstIdx = (y * newW + x) * 4;
                for (i in 0...4)
                    result.set(dstIdx + i, data.get(srcIdx + i));
            }
        return result;
    }

    static function resizeBilinear(data:haxe.io.Bytes, w:Int, h:Int, newW:Int, newH:Int):haxe.io.Bytes {
        var result = haxe.io.Bytes.alloc(newW * newH * 4);

        for (y in 0...newH) {
            var gy = (y + 0.5) * (h / newH) - 0.5;
            var y0 = Std.int(Math.floor(gy));
            var y1 = y0 + 1;
            var dy = gy - y0;
            if (y1 >= h) y1 = h - 1;

            for (x in 0...newW) {
                var gx = (x + 0.5) * (w / newW) - 0.5;
                var x0 = Std.int(Math.floor(gx));
                var x1 = x0 + 1;
                var dx = gx - x0;
                if (x1 >= w) x1 = w - 1;

                var dstIdx = (y * newW + x) * 4;

                for (c in 0...4) {
                    var c00 = data.get((y0 * w + x0) * 4 + c);
                    var c10 = data.get((y0 * w + x1) * 4 + c);
                    var c01 = data.get((y1 * w + x0) * 4 + c);
                    var c11 = data.get((y1 * w + x1) * 4 + c);

                    var c0 = c00 + (c10 - c00) * dx;
                    var c1 = c01 + (c11 - c01) * dx;
                    var value = c0 + (c1 - c0) * dy;

                    result.set(dstIdx + c, Std.int(value));
                }
            }
        }
        return result;
    }

    static function resizeBicubic(data:haxe.io.Bytes, w:Int, h:Int, newW:Int, newH:Int):haxe.io.Bytes {
        inline function clamp(v:Float, min:Float, max:Float):Float
            return v < min ? min : (v > max ? max : v);

        inline function getPixel(x:Int, y:Int, c:Int):Float {
            if (x < 0) x = 0;
            if (x >= w) x = w - 1;
            if (y < 0) y = 0;
            if (y >= h) y = h - 1;
            return data.get((y * w + x) * 4 + c);
        }

        inline function cubicWeight(t:Float):Float {
            var a = -0.5;
            var absT = Math.abs(t);
            if (absT <= 1)
                return (a + 2) * absT * absT * absT - (a + 3) * absT * absT + 1;
            else if (absT < 2)
                return a * absT * absT * absT - 5 * a * absT * absT + 8 * a * absT - 4 * a;
            else
                return 0;
        }

        var result = haxe.io.Bytes.alloc(newW * newH * 4);
        var scaleX = w / newW;
        var scaleY = h / newH;

        for (y in 0...newH) {
            var gy = (y + 0.5) * scaleY - 0.5;
            var yInt = Std.int(Math.floor(gy));

            for (x in 0...newW) {
                var gx = (x + 0.5) * scaleX - 0.5;
                var xInt = Std.int(Math.floor(gx));

                var dstIdx = (y * newW + x) * 4;

                for (c in 0...4) {
                    var sum = 0.0;
                    var weightSum = 0.0;

                    for (m in -1...3) {
                        var wy = cubicWeight(m - (gy - yInt));
                        var yy = yInt + m;
                        for (n in -1...3) {
                            var wx = cubicWeight((gx - xInt) - n);
                            var xx = xInt + n;

                            var wght = wx * wy;
                            sum += getPixel(xx, yy, c) * wght;
                            weightSum += wght;
                        }
                    }

                    var value = clamp(sum / weightSum, 0, 255);
                    result.set(dstIdx + c, Std.int(value));
                }
            }
        }

        return result;
    }

    static function resizeLanczos(data:haxe.io.Bytes, w:Int, h:Int, newW:Int, newH:Int, a:Int = 3):haxe.io.Bytes {
        var result = haxe.io.Bytes.alloc(newW * newH * 4);

        inline function sinc(x:Float):Float {
            if (x == 0) return 1;
            var px = Math.PI * x;
            return Math.sin(px) / px;
        }

        inline function lanczosWeight(x:Float):Float {
            if (x < -a || x > a) return 0;
            return sinc(x) * sinc(x / a);
        }

        var scaleX = w / newW;
        var scaleY = h / newH;

        for (y in 0...newH) {
            var gy = (y + 0.5) * scaleY - 0.5;
            var yInt = Std.int(Math.floor(gy));
            for (x in 0...newW) {
                var gx = (x + 0.5) * scaleX - 0.5;
                var xInt = Std.int(Math.floor(gx));

                var sumR = 0.0, sumG = 0.0, sumB = 0.0, sumA = 0.0;
                var sumW = 0.0;

                for (iy in -a + 1...a) {
                    var sy = yInt + iy;
                    if (sy < 0) sy = 0;
                    if (sy >= h) sy = h - 1;

                    var wy = lanczosWeight((gy - sy));

                    for (ix in -a + 1...a) {
                        var sx = xInt + ix;
                        if (sx < 0) sx = 0;
                        if (sx >= w) sx = w - 1;

                        var wx = lanczosWeight((gx - sx));
                        var wv = wx * wy;

                        var idx = (sy * w + sx) * 4;
                        sumR += data.get(idx) * wv;
                        sumG += data.get(idx + 1) * wv;
                        sumB += data.get(idx + 2) * wv;
                        sumA += data.get(idx + 3) * wv;
                        sumW += wv;
                    }
                }

                var dstIdx = (y * newW + x) * 4;
                if (sumW != 0) {
                    result.set(dstIdx, Std.int(sumR / sumW));
                    result.set(dstIdx + 1, Std.int(sumG / sumW));
                    result.set(dstIdx + 2, Std.int(sumB / sumW));
                    result.set(dstIdx + 3, Std.int(sumA / sumW));
                }
            }
        }

        return result;
    }

    static function blurGaussian(data:haxe.io.Bytes, w:Int, h:Int, radius:Int):haxe.io.Bytes {
        var result = haxe.io.Bytes.alloc(w * h * 4);
        var temp = haxe.io.Bytes.alloc(w * h * 4);

        // создаем ядро гаусса
        var sigma = radius / 2;
        var kernel = [];
        var sum = 0.0;
        for (i in -radius...radius + 1) {
            var val = Math.exp(-(i * i) / (2 * sigma * sigma));
            kernel.push(val);
            sum += val;
        }
        // нормализуем ядро
        for (i in 0...kernel.length)
            kernel[i] /= sum;

        // --- горизонтальное размытие ---
        for (y in 0...h) {
            for (x in 0...w) {
                var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
                for (k in -radius...radius + 1) {
                    var sx = x + k;
                    if (sx < 0) sx = 0;
                    if (sx >= w) sx = w - 1;
                    var idx = (y * w + sx) * 4;
                    var wv = kernel[k + radius];
                    r += data.get(idx) * wv;
                    g += data.get(idx + 1) * wv;
                    b += data.get(idx + 2) * wv;
                    a += data.get(idx + 3) * wv;
                }
                var dstIdx = (y * w + x) * 4;
                temp.set(dstIdx, Std.int(r));
                temp.set(dstIdx + 1, Std.int(g));
                temp.set(dstIdx + 2, Std.int(b));
                temp.set(dstIdx + 3, Std.int(a));
            }
        }

        // --- вертикальное размытие ---
        for (y in 0...h) {
            for (x in 0...w) {
                var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
                for (k in -radius...radius + 1) {
                    var sy = y + k;
                    if (sy < 0) sy = 0;
                    if (sy >= h) sy = h - 1;
                    var idx = (sy * w + x) * 4;
                    var wv = kernel[k + radius];
                    r += temp.get(idx) * wv;
                    g += temp.get(idx + 1) * wv;
                    b += temp.get(idx + 2) * wv;
                    a += temp.get(idx + 3) * wv;
                }
                var dstIdx = (y * w + x) * 4;
                result.set(dstIdx, Std.int(r));
                result.set(dstIdx + 1, Std.int(g));
                result.set(dstIdx + 2, Std.int(b));
                result.set(dstIdx + 3, Std.int(a));
            }
        }

        return result;
    }

    static function buildMipmaps(data:haxe.io.Bytes, w:Int, h:Int, levels:Int):Array<haxe.io.Bytes> {
        var mipmaps = [data];
        var cur = data;
        var curW = w;
        var curH = h;

        for (i in 1...levels) {
            var newW = Std.int(Math.max(1, curW >> 1));
            var newH = Std.int(Math.max(1, curH >> 1));
            var next = haxe.io.Bytes.alloc(newW * newH * 4);

            for (y in 0...newH) {
                for (x in 0...newW) {
                    var r = 0.0, g = 0.0, b = 0.0, a = 0.0;
                    for (dy in 0...2)
                        for (dx in 0...2) {
                            var sx = Std.int(Math.min(curW - 1, x * 2 + dx));
                            var sy = Std.int(Math.min(curH - 1, y * 2 + dy));
                            var idx = (sy * curW + sx) * 4;
                            r += cur.get(idx);
                            g += cur.get(idx + 1);
                            b += cur.get(idx + 2);
                            a += cur.get(idx + 3);
                        }
                    var dst = (y * newW + x) * 4;
                    next.set(dst, Std.int(r / 4));
                    next.set(dst + 1, Std.int(g / 4));
                    next.set(dst + 2, Std.int(b / 4));
                    next.set(dst + 3, Std.int(a / 4));
                }
            }

            mipmaps.push(next);
            cur = next;
            curW = newW;
            curH = newH;
        }

        return mipmaps;
    }

}