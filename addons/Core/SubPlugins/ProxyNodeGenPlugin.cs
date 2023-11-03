#if TOOLS
using System;
using System.Linq;
using System.Reflection;
using Gaea.Plugin;
using Godot;

namespace Gaea.Commons
{
    public class ProxyNodeGenPlugin : SubPlugin
    {
        public override string PluginName => "代理节点生成插件";

        public override void Load()
        {
            var assemblys = Assembly.Load("Gaea Explorer")
                .GetTypes()
                .Where(t => t.GetCustomAttribute<GaeaProxyNodeAttribute>() != null);
            using (var dir = new Directory())
            {
                var dirName = "res://proxy";
                if (!dir.DirExists(dirName))
                    dir.MakeDirRecursive(dirName);

                using (var f = new File())
                {
                    foreach (var item in assemblys)
                    {
                        var fname = $"{dirName}/{item.Name}_Proxy.cs";
                        GD.Print($"{item.Name}:{(item.BaseType != null ? item.BaseType.Name : "")}");
                        if (f.FileExists(fname)) continue;
                        var err = f.Open(fname, File.ModeFlags.WriteRead);
                        if (Error.Ok != err) continue;
                        f.StoreString($@"
/**
* 由生成工具自动生成,请勿在此源码上进行修改以免造成代码丢失;
*/
using Godot;
using Gaea;
using Gaea.Scene;
public class {item.Name}_Proxy : {item.Name} {{ }}
");
                    }
                }
            }
        }
    }
}
#endif