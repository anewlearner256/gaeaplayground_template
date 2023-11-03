using Gaea.Plugin;
using Godot;
using Gaea.Utils;

#if TOOLS
namespace Gaea.Commons
{
    public class MainPlugin : SubPlugin
    {
        public static class Settings
        {
            public static MainPlugin Plugin { get; private set; }

            public static bool GenerateVersionPreprocessorDefines => Plugin.GetSetting<bool>(nameof(GenerateVersionPreprocessorDefines));

            public static void Init(MainPlugin plugin)
            {
                Plugin = plugin;
                Plugin.AddSetting(nameof(GenerateVersionPreprocessorDefines), Variant.Type.Bool, false);
            }
        }

        public override string PluginName => "Main";

        public override void Load()
        {
            Settings.Init(this);

            if (Settings.GenerateVersionPreprocessorDefines)
                EngineUtils.GenerateVersionPreprocessorDefines();
        }
    }
}
#endif