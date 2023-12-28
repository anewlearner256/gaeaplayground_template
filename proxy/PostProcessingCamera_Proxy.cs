
/**
* 由生成工具自动生成,请勿在此源码上进行修改以免造成代码丢失;
*/
using Godot;
using Gaea;
using Gaea.Scene;
public class PostProcessingCamera_Proxy : PostProcessingCamera
{
    Camera camera;
    WeatherManager weatherManager;
    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {

    }
    public override void _Process(float delta)
    {
        if (camera == null || weatherManager == null)
        {
            camera = World.Instance.DefaultCamera;
            weatherManager = World.Instance.FullScreenQuad;
        }
        else
        {
            Transform = camera.Transform;
            Fov = camera.Fov;
            Near = camera.Near;
            Far = camera.Far;
            var screenTexture = GetViewport().GetTexture();
            weatherManager.WeatherShader?.SetShaderParam("cam_pos", World.Instance.DefaultCamera.Translation);
            weatherManager.WeatherShader?.SetShaderParam("sun_dir", World.Instance.Sun.Translation.Normalized());
            weatherManager.WeatherShader?.SetShaderParam("screen_texture", screenTexture);
        }
    }
}
