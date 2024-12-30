using Godot;
using System;
using System.Linq;
using System.Collections.Generic;
using GaeaDisplay;
using GaeaGeoDataBase;

public class WorldTest : World_Proxy
{
  void _on_Button_button_down()
  {

    var element = new GaeaDisplay.GLTFElement();
    element.ResourceName = "办公楼.gltf";
    element.Name = "办公楼";
    element.OnModelInit(() =>
    {
      // element.LocalRotation = new Vector3(0, 0, 0); //模型旋转
      element.UseAbsoluteHeight = true;
      element.Scale = new Vector3(200, 200, 200);  //模型放大
      var elv = World.Instance.DefaultTerrainAccessor.GetElevationAt(30.31439208984375, 112.2308349609375, 20); //根据经纬度获取高程
      var pos = new Vector3(30.31439208984375, 112.2308349609375, elv); //模型位置
      element.GeographyPosition = pos;
      element.EnablePick = true;
    });

    World.Instance.RenderableObjectList.AddLast(element);
    World.Instance.DefaultCamera.SetPosition(30.31439208984375, 112.2308349609375, 0, 150, 0, 0);


    // var tool = new DigTool();
    // World.Instance.SetCurrentTool(tool);

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
  CutAnalysisTool tool = new CutAnalysisTool();

  void _on_Button_pressed()
  {

    tool.CreateCutPlaneData("办公楼");
    tool.CutAnalysisMode = CutModeEnum.Axis;
    tool.CutAnalysisAxis = CutAxisEnum.XAxis;
    // tool.CutAnalysisAxis = CutAnalysisTool.CutAxis.ZAxis;
    World.Instance.SetCurrentTool(tool);
  }

  void _on_Button2_pressed()
  {
    tool.CutAnalysisAxis = CutAxisEnum.YAxis;

    
  }

  void test()
  {
    var Position = new List<Vector3>(){
        // new Vector3(27.23807152, 120.40976354, 3000),
        // new Vector3(27.23804433, 120.40986354, 3000),
        // new Vector3(27.23804433, 120.40996354, 3000),
        // new Vector3(27.23804433, 120.41006354, 3000),
        // new Vector3(27.23804433, 120.41016354, 3000),
        // new Vector3(27.23804433, 120.41026354, 3000),
        // new Vector3(27.23804433, 120.41036354, 3000),
        // new Vector3(27.23807152, 120.41046354, 3000)
        
        new Vector3(21, 121, 3000),
        new Vector3(22, 122, 3000),
        new Vector3(23, 123, 3000),
        new Vector3(24, 124, 3000),
        new Vector3(25, 125, 3000),
        new Vector3(26, 126, 3000),
        new Vector3(27, 127, 3000),
        new Vector3(28, 128, 3000)
        };

    var pointdata = new List<Vector3>(){
        //     new Vector3(27.23804433, 120.40996354, 3000),
        // new Vector3(27.23804433, 120.41006354, 3000),
        // new Vector3(27.23804433, 120.41016354, 3000),
        // new Vector3(27.23804433, 120.41026354, 3000)
        new Vector3(23, 123, 3000),
        new Vector3(24, 124, 3000),
        new Vector3(25, 125, 3000),
        new Vector3(26, 126, 3000),
        };

    var LineGeometry = Gaea.Geometry.Geometry.Create(Gaea.Geometry.GeometryType.Polyline, Position);
    // 插值生成几何对象，参数（被插值的几何形状，插值类型（默认为1），需要插值的顶点数据，插值点数量，插值公差）
    var geometry = Gaea.Geometry.Geometry.GeometryInterpolate(LineGeometry, Gaea.Geometry.GeometryGenerater.CurveMode.Line, pointdata.ToArray(), 10, 0.5);
    var polygonElement = new LineGeometryElement();

    polygonElement.Shape = geometry;
    polygonElement.EnableEdit = true;
    polygonElement.EnablePick = true;
    World.Instance.RenderableObjectList.AddLast(polygonElement);

  }

  public void Animation()
  {
    var element = new GLTFElement()
    {
      Name = "航标船",
      ResourceName = "航标船.gltf",
      GeographyPosition = new Vector3(22.589854518665, 115.367789905067, 1000),
      EnablePick = true
    };

    element.OnModelInit(() =>
    {
      var element2 = new GLTFElement()
      {
        Name = "雷达波",
        ResourceName = "雷达波.gltf",
        Visible = true,
        Scale = new Vector3(1, 1, 1)
      };
      element.Root.AddChild(element2, false); //把第二个模型的父节点设置为第一个模型
                                              // element2.OnModelInit(() =>
                                              // {

      // 	//element.Root.GetChild<MeshInstance>(0) .MaterialOverride = xxx
      // 	//      Godot.Animation animation1 = new Godot.Animation();
      // 	// animation1.AddTrack(Godot.Animation.TrackType.Method);
      // 	// animation1.TrackSetPath(0, element2.GetPath()); // 将动画轨道0与模型绑定, /root/World/model为场景中名称model的模型的路径
      // 	var ins = element2.GetMeshInstanceByName("Cylinder001");//获取模型表面贴图
      // 	var n = ins.Mesh.GetAabb().Size.Length();
      // 	var uu = World.Instance.GetNode<MeshInstance>("MeshInstance").GetActiveMaterial(0);
      // 	ins.MaterialOverride = World.Instance.GetNode<MeshInstance>("MeshInstance").GetActiveMaterial(0);
      // 	// animation1.TrackInsertKey(0, 0, Godot.FuncRef);
      // 	// animation1.TrackInsertKey(0, 0.1f, nameof(uuu));
      // 	// animation1.TrackInsertKey(0, 0.2f, nameof(uuu));
      // 	// animation1.TrackInsertKey(0, 0.3f, nameof(uuu));
      // 	// animation1.TrackInsertKey(0, 0.4f, nameof(uuu));
      // 	// animation1.TrackInsertKey(0, 0.5f, nameof(uuu));
      // 	// animation1.TrackInsertKey(0, 0.6f, nameof(uuu));
      // 	// animation1.Loop =true;
      // 	// var animationPlayer1 = new AnimationPlayer(); // 新建动画播放器
      // 	// animationPlayer1.AddAnimation("test2", animation1); // 向播放器中添加刚刚创建的动画
      // 	// World.Instance.AddChild(animationPlayer1, false); // 将播放器添加到场景
      // 	// World.Instance.PlayAnimation(animationPlayer1, "test2"); // 播放动画
      // });


      // element2.OnModelInit(() =>
      // {

      //     var ins = element2.GetMeshInstanceByName("Cylinder001");//获取模型表面贴图
      //     element2.Scale = new Vector3(1000000, 1000000, 1000000);
      //     var mtl = ins.Mesh.SurfaceGetMaterial(0) as SpatialMaterial;//贴图转换材质
      //     mtl.Uv1Offset = new Vector3(0, -1, 0);
      // });

      // World.Instance.RenderableObjectList.AddLast(element2);
    });
    World.Instance.RenderableObjectList.AddLast(element);
    World.Instance.DefaultCamera.SetPosition(22.589854518665, 115.367789905067, 0, 1500, 0, 0);

    var line = new List<Vector3>{
				//路径上的控制点
						new Vector3(115.367789905067f, 22.589854518665f,0),
            new Vector3(115.367889905067f, 22.589855518665f,0),
            new Vector3(115.367989905067f, 22.589856518665f,0),
            new Vector3(115.368089905067f, 22.589857518665f,0),
            new Vector3(115.368189905067f, 22.589858518665f,0),
      };
    var Curve = new UniformCubicSpline(); //B样条曲线
    for (var i = 0; i < line.Count; i++)
    {
      var r = World.Instance.DefaultTerrainAccessor.GetElevationAt(
        //获取控制点的高程
        line[i].y,
        line[i].x,
        20
      );
      var control = GaeaMath.SphericalToCartesianDeg(
        //控制点的笛卡尔坐标
        line[i].y, //经度
        line[i].x, //纬度
        1000 //到地表距离
      );
      Curve.AddValue(i, control); //添加控制点
    }
    Curve.Step = 1000; //设置插值点的个数
    Curve.Interpolate(true); // 对控制点进行插值，保存每个插值点的坐标，旋转和时间
    Curve.CalculateLengthAfterInterpolation(); //计算插值后的路径长度，并记录每个插值点到到起点的距离

    // 生成动画
    var animation = Curve.ToAnimationByTime(
      "test1", // 动画名称，可自定义
      true, // true,关键帧的时刻由插值点到起点的路程占曲线总长的比例和给定的动画时长确定； fasle,关键帧的时刻采用插值点的时刻, 此时给定的动画时长不起作用
      5, // 动画时长, 单位秒
      new Vector3(100, 100, 100) // 模型的缩放倍数
    );

    animation.Loop = true; // 循环播放

    var mesh = World.Instance.RenderableObjectList.GetByName("航标船") as GLTFElement;

    var path = mesh.GetPath();
    animation.TrackSetPath(0, path); // 将动画轨道0与模型绑定, /root/World/model为场景中名称model的模型的路径
    var animationPlayer = new AnimationPlayer(); // 新建动画播放器
    animationPlayer.AddAnimation("test1", animation); // 向播放器中添加刚刚创建的动画
    World.Instance.AddChild(animationPlayer, false); // 将播放器添加到场景
    World.Instance.PlayAnimation(animationPlayer, "test1"); // 播放动画


  }

  public void add3dtiles()
  {
    //请求地址
    var url = "https://192.168.3.144/gaeaExplorerServer/model/webqxsy/未来科技城/tileset.json";
    //保存文件名
    var name = "未来科技城";
    //创建3DTiles对象
    var currentTile = new Gaea3DTileset();
    //对象名
    currentTile.Name = name;
    //地址
    currentTile.TilesetUrl = url;
    //重新计算法线
    currentTile.RecalculateNormals = false;
    //光照
    currentTile.UseLight = false;
    //能否点击
    currentTile.EnablePick = true;
    // currentTile.BaseUrl = url.slice(0, url.lastIndexOf("/") + 1);
    //初始化
    currentTile.InitTileSet(name, url);
    currentTile.MaximumMemoryUsage = 512;
    //高度偏移，Vector3的x,y,z表示在三个方向的偏移值
    currentTile.LocalOffset = new Vector3(0, 50.0, 0);
    //添加到世界节点
    World.Instance.RenderableObjectList.AddLast(currentTile);
  }
  void Button3()
  {
    // var PointTextSymbol = new TextMarkSymbol(); //创建字体符号
    // var PointIconSymbol = new IconMarkSymbol();//创建图标
    // var Symbol = new CompositeSymbol();
    // PointTextSymbol.MarkSize = 20; //设置大小
    // PointTextSymbol.FontColor = new Color(1, 1, 1, 1); //设置颜色
    // PointTextSymbol.Field = "name";//显示字段名
    // PointTextSymbol.HeightOffset = 10; //设置高度偏移
    // PointTextSymbol.Anchor = AnchorType.Up;//字体停靠方向
    // PointTextSymbol.Fontgap = 0.5f;//字体间距
    // Symbol.AddSymbol(PointTextSymbol);



    // PointIconSymbol.HeightOffset = 10;
    // PointIconSymbol.Icon = GD.Load<Texture>("res://assets/images/point.png");
    // PointIconSymbol.MarkSize = 20;
    // Symbol.AddSymbol(PointIconSymbol);

    // var points = new List<Vector3>{
    //         new Vector3(34.5694745790576, 105.962108201382, 100), //社棠镇
    //         new Vector3(34.708176474057, 105.396793259202, 100),  //六峰镇
    //         new Vector3(34.8066648907865, 105.454541877039, 100),  //金山乡
    //         new Vector3(34.589829786221, 105.207673919421,100),
    //         new Vector3(34.6822687130929, 105.31284238242, 100)
    //     };

    // var names = new List<string>{
    //         "社棠镇",
    //         "六峰镇",
    //         "金山乡",
    //         "古坡乡",
    //         "白家湾乡"
    //     };
    // for (var i = 0; i < points.Count; i++)
    // {
    //   var element = new Element();

    //   var pos = new List<Vector3> { points[i] };
    //   var Shape = Gaea.Geometry.Geometry.Create(Gaea.Geometry.GeometryType.Point, pos);
    //   var Feature = new GaeaGeoDataBase.Feature();
    //   var fields = new Fields();
    //   var field = new Field();
    //   field.Name = "name";
    //   fields.AddField(field);
    //   Feature.SetFields(fields);
    //   Feature.SetStringValue("name", names[i]);
    //   Feature.SetShape(Shape);
    //   var element1 = new PointGeometryElement
    //   {
    //     Feature = Feature,
    //     Symbol = Symbol
    //   };
    //   World.Instance.RenderableObjectList.AddLast(element1);

    // }
  }

  void Button4()
  {
    // var abspath = @"C:\Users\Administrator\Desktop\色带.png";

    // Image img = new Image();
    // img.Load(abspath);
    // var symbol = new BuildingSymbol()
    // {
    //   ExtrudeDir = new Vector3(0, 1, 0),
    //   // IsNeedNormal = true,
    //   HeightOffset = 3000,
    //   UvScale = new Vector2(1, 1),
    //   RandomHeight = false,
    //   // HeightField = "height"
    //   ExtrudeHeight = 3000,
    //   // SymbolColor = new Color(1, 0, 0)
    // };

    // var data_json = @"E:\数据\test.geojson";

    // var fieldrange = new string[] {
    //   "C",
    //   "C1",
    //   "C2" ,
    //   "C26",
    //   "C3",
    //   "C4",
    //   "C5",
    //   "C6",
    //   "C9",
    //   "CR",
    //   "D",
    //   "E1",
    //   "E2",
    //   "E4",
    //   "G1",
    //   "G2",
    //   "M1",
    //   "M2",
    //   "M3",
    //   "P",
    //   "R1",
    //   "R2",
    //   "R22",
    //   "S2",
    //   "S3",
    //   "SY",
    //   "T1",
    //   "T2",
    //   "T5",
    //   "U",
    //   "W",
    //   "W2",
    //   };
    // var colorrange = new Color[] {
    //   new Color(240/255f,0f,70/255f,1),
    //   new Color(240/255f,0f,70/255f,1),
    //   new Color(254/255f,0f,0f,1),
    //   new Color(220/255f,55/255f,1/255f,1),//"C26"
		// 	new Color(222/255f,110/255f,0f,1),
    //   new Color(240/255f,0f,70/255f,1),
    //   new Color(184/255f,0f,184/255f,1),
    //   new Color(255/255f,0f,254/255f,1),//"C6"
		// 	new Color(255/255f,127/255f,126/255f,1),//"C9"
		// 	new Color(254/255f,127/255f,127/255f,1),//"CR"
		// 	new Color(255/255f,167/255f,127/255f,1),  //"D"  
		// 	new Color(1/255f,190/255f,254/255f,1),//"E1"
		// 	new Color(191/255f,228/255f,88/255f,1),//"E2"
		// 	new Color(46/255f,184/255f,0f,1),
    //   new Color(64/255f,255/255f,1/255f,1),//"G1"
		// 	new Color(46/255f,184/255f,0f,1), //"G2"
		// 	new Color(204/255f,152/255f,102/255f,1),
    //   new Color(150/255f,112/255f,75/255f,1),
    //   new Color(80/255f,60/255f,50/255f,1),
    //   new Color(183/255f,183/255f,183/255f,1),
    //   new Color(255/255f,255/255f,129/255f,1),
    //   new Color(255/255f,255/255f,1/255f,1),
    //   new Color(221/255f,221/255f,0f,1),
    //   new Color(153/255f,153/255f,153/255f,1),
    //   new Color(219/255f,219/255f,219/255f,1),
    //   new Color(1/255f,190/255f,254/255f,1),
    //   new Color(221/255f,221/255f,221/255f,1),
    //   new Color(178/255f,178/255f,178/255f,1),
    //   new Color(221/255f,221/255f,221/255f,1),
    //   new Color(0f,138/255f,184/255f,1),
    //   new Color(159/255f,126/255f,255/255f,1),
    //   new Color(159/255f,84/255f,255/255f,1),
    //   };
    // var layer = new GaeaDisplay.FeatureLayer();
    // var render = new GaeaDisplay.UniqueValueRenderer();

    // render.ColorRange = colorrange;
    // render.SetColorByUser = true;
    // // UsePictureAsColor = true,
    // // ImageTexture = img,
    // render.UniqueField = "Text";
    // render.FieldStringRange = fieldrange;
    // render.Symbol = symbol;
    // var fclass = GaeaGeoDataBase.WorkspaceFactory.OpenFromFile(data_json).OpenFeatureClass(true, false);
    // layer.FeatureClass = fclass;
    // layer.FeatureRenderer = render;
    // layer.VisibleRange = new Vector2(0, 1000000000000);
    // World.Instance.RenderableObjectList.AddLast(layer);
    // World.Instance.DefaultCamera.SetPosition(29.80589217356748, 115.76029227525923, 0, 1500, 0);
  }

  void Button5()
  {
    World.Instance.FullScreenQuad.Visible = true;
    World.Instance.FullScreenQuad.NeedAtmosphere = false;
    var skyline = new SkyLine();
    skyline.LineWidth = 5;
    skyline.LineColor = new Color(1, 0, 0, 1); // 设置颜色和透明度，这里设置为红色
    World.Instance.AddChild(skyline, false);
  }

  VolumeRenderer volumeRenderer;
  //体渲染
  void _on_Button6_button_down()
  {
    if (volumeRenderer != null)
    {
      World.Instance.RemoveChild(volumeRenderer);
      volumeRenderer.Dispose();
      volumeRenderer = null;
      return;
    }

    var _colorControlPoints = new List<Vector2>();
		var _opacityControlPoints = new List<Vector2>();

		_colorControlPoints.Add(new Vector2(0, -65536));//x:色带长度:0-2550 ,y:颜色RGBA:
		_colorControlPoints.Add(new Vector2(228, -7680));
		_colorControlPoints.Add(new Vector2(420, -16711936));
		_colorControlPoints.Add(new Vector2(594, -16711707));
		_colorControlPoints.Add(new Vector2(950, -16711707));
		_colorControlPoints.Add(new Vector2(1380, -16776961));
		_colorControlPoints.Add(new Vector2(1873, -16181));



		_opacityControlPoints.Add(new Vector2(0, 0));//X:色带长度:0-2550 ,y:透明度:0-255
		_opacityControlPoints.Add(new Vector2(548, 12));
		_opacityControlPoints.Add(new Vector2(950, 0));
		_opacityControlPoints.Add(new Vector2(1206, 8));
		_opacityControlPoints.Add(new Vector2(1434, 15));
		_opacityControlPoints.Add(new Vector2(1782, 0));
		_opacityControlPoints.Add(new Vector2(1873, 12));

    // MeteoVisualModel.MathUitilities.AddColorScheme(@"E:\微信文件\WeChat Files\wxid_8biktneuq6wp12\FileStorage\File\2024-07\result\天兴洲大桥2号3号桥墩三维流场数据.xml",
    // ref _colorControlPoints, ref _opacityControlPoints);

    string path = @"C:\Users\lenovo\Desktop\result(2)\result\result.xml";
    path = @"E:\微信文件\WeChat Files\wxid_8biktneuq6wp12\FileStorage\File\2024-07\result\天兴洲大桥2号3号桥墩三维流场数据.xml";
    var _mdProvider = new MeteoVisualModel.MeteorDataProvider();
    _mdProvider.Initialize(path);

    volumeRenderer = new VolumeRenderer();
    //this.AddChild(volumeRenderer);
    volumeRenderer.SetBlockSize(5, 5);


    volumeRenderer.Initialize("UVW", _mdProvider, 1000, 2000);
    //volumeRenderer.DoRender();
    volumeRenderer.SetBitmap(_colorControlPoints.ToArray(), _opacityControlPoints.ToArray());
    volumeRenderer.RefreshData("UVW", @"E:\微信文件\WeChat Files\wxid_8biktneuq6wp12\FileStorage\File\2024-07\result\UVW\天兴洲大桥2号3号桥墩三维流场数据.dat"
    , @"E:\微信文件\WeChat Files\wxid_8biktneuq6wp12\FileStorage\File\2024-07\result\UVW\天兴洲大桥2号3号桥墩三维流场数据.dat");
    volumeRenderer.RefreshTime(0);
    volumeRenderer.RefreshStep(100);
    //volumeRenderer.DVRDriver.RefreshCull(true, 100, 100);//裁剪行列

    volumeRenderer.AutoRender = false;
    World.Instance.AddChild(volumeRenderer, false);

    volumeRenderer.AutoRender = true;

    // volumeRenderer.DVRDriver.CullX = 1000;
    // volumeRenderer.DVRDriver.CullY = 0;
    // volumeRenderer.DVRDriver.CullDirty = false;
  }

  void _on_Button7_button_down()
  {
    var colorBar = new ColorBarGradient(); // 色带条类
        colorBar.ColorBarType = ColorBarEnum.Constant; // 选择类型 [Constant(确定),Line(渐变)]
        colorBar.AddValue("-32", new Color(1, 0, 0, 1)); // 唯一值对应的颜色设置
        colorBar.AddValue("-22", new Color(0, 1, 0, 1));
        colorBar.AddValue("2", new Color(1, 1, 0, 1));
        colorBar.AddValue("4", new Color(0, 0, 1, 1));
        colorBar.AddValue("6", new Color(1, 0, 1, 1));
        colorBar.AddValue("8", new Color(0, 1, 1, 1));
        colorBar.AddValue("default", new Color(1, 1, 1, 1));

        var lineSymbol = new LineSymbol();
        lineSymbol.HeightOffset = 100;//设置边框线颜色
        lineSymbol.LineWidth = 2;//设置边框线宽度
        var path = @"E:\数据\等值线2020.geojson";
        var ws = GaeaGeoDataBase.WorkspaceFactory.OpenFromFile(path); //打开文件
        var fclass = ws.OpenFeatureClass(true, false); //读取文件，构建FeatureClass
        var flayer = new FeatureLayer(); //创建一个FeatureLayer图层
        var FeatureRenderer = new UniqueValueRenderer(); //创建一个渲染器
        FeatureRenderer.UniqueField = "CONTOUR";
        // FeatureRenderer.StartColor = new Color(1, 0, 0, 1); // 当前版本被弃用
        // FeatureRenderer.EndColor = new Color(0, 0, 1, 1); // 当前版本被弃用
        FeatureRenderer.ColorBarGradient = colorBar; // 传入色带类
        FeatureRenderer.Symbol = lineSymbol; //设置渲染器的符号
        flayer.VisibleRange = new Vector2(0, 1000000); //设置可见高度范围
        flayer.FeatureClass = fclass; //设置图层中的数据，即fclass
        flayer.FeatureRenderer = FeatureRenderer; //设置图层中的渲染器， 即FeatureRenderer
        World.Instance.RenderableObjectList.AddLast(flayer);
  }

  void decal2()
  {
    var item = new DecalItem();
    var item2 = new DecalItem();
    //高度模式，分为绝对高程和相对高程
    DecalManager.Instance.PixelToHeightMode = PixelToHeightModeEnum.Absolute;
    //地形插值系数
    DecalManager.Instance.TerrainMapInterpolationValue = 1;
    //地形夸张系数
    // World.Instance.VerticalExaggeration = 1;

    //贴图范围，（Maxlat,Minlat,Minlon,Maxlon）
    item.ChangeRange(
 30.32735097990059,
 30.236096498693207,
 112.1851803258381,
 112.29406240693721
);

    //色带
    item.BaseMapPath = "user://resources/色带.png";
    //地形图
    item.TerrainMapPath = "user://resources/dixing/溃坝000.png";
    //地形最大最小值
    item.TerrainMinMaxValue = new Vector2(0, 232);
    //地形无效值
    item.TerrainInvalidValue = 0;
    //1为图片，2为色带
    item.BaseMapType = BaseMapTypeEnum.ColorRamp;
    DecalManager.Instance.AddItem(item);
    item2.ChangeRange(
     30.32735097990059,
     30.236096498693207,
     112.1851803258381,
     112.29406240693721
    );
    item2.TerrainMapPath = "user://resources/溃坝001.png";
    item2.TerrainMinMaxValue = new Vector2(0.06f, 47);
    item2.TerrainInvalidValue = 0;
    item2.BaseMapType = BaseMapTypeEnum.ColorRamp;
    DecalManager.Instance.AddItem(item2);
  }

 
}
