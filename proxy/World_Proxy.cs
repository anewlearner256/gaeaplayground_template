
/**
* 由生成工具自动生成,请勿在此源码上进行修改以免造成代码丢失;
*/
using Godot;
using Gaea;
using Gaea.Scene;
using Gaea.Export;
public class World_Proxy : World
{
#if GODOT_PC
    public static Directory DIRECTORY = new Directory();
    public override void _Ready()
    {
        base._Ready();
        var code = ExportApiManager.Instance.Export(Language.JavaScript);
        var path = "res://exports/html5";
        if (!DIRECTORY.DirExists(path))
            DIRECTORY.MakeDirRecursive(path);
        using (var f = new File())
        {
            f.Open($"{path}/index.js", File.ModeFlags.Write);
            f.StoreString(code);
        }
    }
#endif
}
