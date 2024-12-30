
/**
* 由生成工具自动生成,请勿在此源码上进行修改以免造成代码丢失;
*/
using Godot;
using Gaea;
using Gaea.Scene;
using Gaea.Export;
using GaeaDisplay;
public class World_Proxy : World
{
    internal readonly Godot.Directory DIRECTORY = new Godot.Directory();
    public override void _Ready()
    {
        GD.Print($"当前引擎版本: [{GetVersion()}]");
        base._Ready();

        // var tool  = new DrawCircularTool();
        // tool.DeleteElementOnDispose = false;

        // DrawDoubleArrowTool drawDoubleArrowTool = new DrawDoubleArrowTool();
        // World.Instance.AddChild(drawDoubleArrowTool);
        // drawDoubleArrowTool.OverDraw += () =>
        // {

        // };

        // var code = ExportApiManager.Instance.Export(Language.JavaScript);
        // var path = "res://exports/html5";
        // if (!DIRECTORY.DirExists(path))
        //     DIRECTORY.MakeDirRecursive(path);
        // using (var f = new File())
        // {
        //     f.Open($"{path}/index.js", File.ModeFlags.Write);
        //     f.StoreString(code);
        // }

        var s = new ColorRect();
        

    }

}
