using Godot;
using System;
using System.Linq;

public class WorldTest : World_Proxy
{
    void _on_Button_button_down()
    {
        var tool = new DigTool();
        World.Instance.SetCurrentTool(tool);

        // World.Instance.UseSplit = true;
        // var d = GaeaResourceLoader.Instance.LoadLoaclResource("res://assets/tscn/SplitTool.tscn");
        // var scene = (d as PackedScene).Instance();
        // // console.log(node);
        // World.Instance.AddChild(scene, false);

        // //加载庆阳正射影像
        // var WMTSserver = new string[] { "高德地图", "天地图" };
        // var host = $"{EngineConfig.Instance.ServerHost}/gaeaExplorerServer/htc/service/wmts";
        // var capabilities = WMTSImageStore.GetWMTSCapabilities(host);
        // if (capabilities.Length > 0)
        // {
        //     var WMTSLayers = capabilities.ToDictionary(i => i.Title);
        //     int flag = 1;
        //     foreach (var layer in WMTSserver)
        //     {
        //         var cap = WMTSLayers[layer];
        //         // console.log("获取:", cap);
        //         var WMTSstore = new WMTSImageStore();
        //         WMTSstore.ImageExtension = ImageExtensionEnum.PNG;
        //         WMTSstore.CurrentCapabilitie = cap;
        //         WMTSstore.SplitDirection = flag;
        //         // WMTSstore.levelRange = new Vector2(0, 21); 
        //         World.Instance.DefaultPyramidTileSet.AddImageStore(WMTSstore);
        //         flag += 1;
        //     }
        // }
    }
}
