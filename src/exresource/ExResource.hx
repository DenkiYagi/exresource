package exresource;

#if macro
import extype.Nullable;
import haxe.io.Eof;
import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;
using StringTools;
#end

class ExResource {
    #if macro
    static inline final SPACE = 0x20;
    static inline final HTAB = 0x09;
    static inline final LF = 0x0A;
    static inline final CR = 0x0D;
    static inline final EQUAL = "=".code;
    static inline final BACK_SLASH = "\\".code;

    public static function load(path:String = ".resource"):Void {
        final scanner = new Scanner(path);

        function skipWhiteSpace():Void {
            scanner.skipWhile(isWhiteSpace);
        }

        function skipBlank():Void {
            scanner.skipWhile(isBlank);
        }

        function readComment():Nullable<String> {
            return if (scanner.peekIf(char -> char == "#".code).nonEmpty()) {
                final chars = scanner.peekWhile(char -> char != CR && char != LF);
                scanner.skipIf(char -> char == CR);
                scanner.skipIf(char -> char == LF);
                toString(chars);
            } else {
                Nullable.empty();
            }
        }

        function readKey():String {
            final from = scanner.offset;
            final chars = scanner.peekWhile(char -> !isWhiteSpace(char) && char != EQUAL);
            final to = scanner.offset;

            if (chars.length <= 0) {
                return Context.error("Invalid key", Context.makePosition({file: path, min: from, max: to}));
            }

            return toString(chars);
        }

        function existEqual():Void {
            final from = scanner.offset;
            final char = scanner.peekIf(char -> char == EQUAL);
            final to = scanner.offset;

            if (char.isEmpty()) {
                Context.error("Invalid line", Context.makePosition({file: path, min: from, max: to}));
            }
        }

        function readValue():String {
            final buff = [];
            while (true) {
                final char = scanner.peek();
                if (char.isEmpty()) break;

                final c = char.getUnsafe();
                switch (c) {
                    case BACK_SLASH:
                        final nextChar = scanner.peek();
                        if (nextChar.isEmpty()) {
                            buff.push(BACK_SLASH);
                            break;
                        }
                        final nc = nextChar.getUnsafe();
                        switch (nc) {
                            case BACK_SLASH:
                                buff.push(BACK_SLASH);
                            case CR:
                                scanner.skipIf(x -> x == LF);
                                if (buff.length > 0) buff.push(LF);
                            case LF:
                                if (buff.length > 0) buff.push(LF);
                            case _:
                                buff.push(BACK_SLASH);
                                buff.push(nc);
                        }
                    case CR:
                        scanner.skipIf(nextChar -> nextChar == LF);
                        break;
                    case LF:
                        break;
                    case _:
                        buff.push(c);
                }
            }
            return toString(buff);
        }

        while (true) {
            skipWhiteSpace();
            if (scanner.isEnd()) break;

            final comment = readComment();
            if (comment.nonEmpty()) {
                continue;
            }

            final key = readKey();
            skipBlank();
            existEqual();
            skipBlank();
            final value = readValue();

            Context.addResource(key, Bytes.ofString(value));
        }
    }

    inline static function isWhiteSpace(char:Int):Bool {
        return isBlank(char) || isNewLine(char);
    }

    inline static function isBlank(char:Int):Bool {
        return char == SPACE
            || char == HTAB;
    }

    inline static function isNewLine(char:Int):Bool {
        return char == LF
            || char == CR;
    }

    inline static function toString(chars:Array<Int>):String {
        return chars.map(String.fromCharCode).join("");
    }
    #end
}

#if macro
@:access(StringTools)
private class Scanner {
    final input:String;
    final length:Int;

    public var offset(default, null):Int;

    public function new(path:String) {
        input = File.getContent(path);
        length = input.length;
        offset = 0;
    }

    public inline function isEnd():Bool {
        return offset >= length;
    }

    public inline function nonEnd():Bool {
        return offset < length;
    }

    public inline function peek():Nullable<Int> {
        if (offset >= length) return Nullable.empty();

        #if utf16
        final c = StringTools.utf16CodePointAt(input, offset++);
        if (c >= StringTools.MIN_SURROGATE_CODE_POINT) {
            offset++;
        }
        return c;
        #else
        return StringTools.fastCodeAt(input, offset++);
        #end
    }

    public inline function peekIf(fn:(char:Int) -> Bool):Nullable<Int> {
        final prev = offset;
        final char = peek();
        return if (char.nonEmpty() && fn(char.getUnsafe())) {
            char;
        } else {
            offset = prev;
            Nullable.empty();
        }
    }

    public inline function peekWhile(fn:(char:Int) -> Bool):Array<Int> {
        final buff = [];
        while (true) {
            final char = peekIf(fn);
            if (char.nonEmpty()) {
                buff.push(char.getUnsafe());
            } else {
                break;
            }
        }
        return buff;
    }

    public inline function skip():Void {
        peek();
    }

    public inline function skipIf(fn:(char:Int) -> Bool):Void {
        final prev = offset;
        final char = peek();
        if (char.nonEmpty() && !fn(char.getUnsafe())) {
            offset = prev;
        }
    }

    public inline function skipWhile(fn:(char:Int) -> Bool):Void {
        while (peekIf(fn).nonEmpty()) { }
    }
}
#end