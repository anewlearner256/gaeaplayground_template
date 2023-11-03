#if TOOLS
using Godot;
using Gaea.Commons;

namespace Gaea.Plugin
{
    [Tool]
    public class Core : ExtendedPlugin
    {
        public override string PluginName => "Gaea Explorer Core Plugin";

        protected override void Load()
        {
            AddSubPlugin(new MainPlugin());
            AddSubPlugin(new ProxyNodeGenPlugin());
            AddSubPlugin(new CSharpResourceRegistryPlugin());
            AddSubPlugin(new EditorUtilsPlugin());
            AddSubPlugin(new CustomEditorPropertiesPlugin());
        }
    }
}

#endif