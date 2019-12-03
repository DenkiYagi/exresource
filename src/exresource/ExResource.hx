package exresource;

#if macro
import haxe.io.Eof;
import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
using StringTools;
#end

class ExResource {
    #if macro
    public static function load(path:String = ".resource"):Void {
        final fin = sys.io.File.read(path, false);
        var lineNo = 0;
        try {
            while (true) {
                final text = fin.readLine().trim();
                lineNo++;

                // ignore empty line
                if (text.length <= 0) continue;
                // ignore comment line
                if (text.charAt(0) == "#") continue;

                final index = text.indexOf("=");
                if (index <= 0) {
                    trace('WARING: Ignored invalid line at $path:$lineNo');
                    continue;
                }
                
                final key = text.substring(0, index);
                final value = text.substring(index + 1);
                Context.addResource(key, Bytes.ofString(value));
            }
        } catch (_:Eof) {
        }
        fin.close();
    }
    #end
}