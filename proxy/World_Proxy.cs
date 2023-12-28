
/**
* 由生成工具自动生成,请勿在此源码上进行修改以免造成代码丢失;
*/
using Godot;
using Gaea;
using Gaea.Scene;
public class World_Proxy : World
{
    public override void _Ready()
    {
        GD.Print($"当前引擎版本: [{GetVersion()}]");
        base._Ready();
    }

}
