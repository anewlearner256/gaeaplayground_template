#### 0.1.5 (2023-08-29)

##### Other Changes

*  锁定模型的坐标换成GlobalTransform' (#18) from dev0827 into master (c2805222)
*  RenderableObject变更为空间节点,以及子类对象对应的修改' (#17) from dev0827 into master (993d6aeb)
*  修复锁定模型后会有一个小跳动的问题' (#16) from dev0823-dannyjones into master (29fef123)
*  修复相机锁定模型功能存在定位不准的问题' (#12) from dev0823-dannyjones into master (385e35a2)
*  修复相机飞行时的朝向问题' (#10) from dev0822-ning into master (5fc16470)
*  测量工具场景' (#7) from 8-17-11-43-Hush into master (60b2d13e)
*  命名更改' (#6) from 8-17-11-43-Hush into master (a2e52aed)
*  更新版本号' (!387) from dev0808 into master (21653f4e)
* 3000/root/gaea-explorer into dev0808 (930652bb)
*  3dtiles 新增缓存控制,可以有效的减少更新闪烁的问题,但是会增加内存的使用' (!383) from 20230804 into master (9cc6cfbe)
*  修改组合符号支持不同渲染器' (!381) from dev-0731h into master (3923dea5)
*  添加纹理重复' (!382) from dev0804 into master (fcda7b91)
*  增加Element更新控制、SymbolColor设置' (!377) from Hush2023 into master (57165e42)
*  新增屏幕点转模型点的功能,以及工具默认会在模型上取点' (!376) from 20230803 into master (174a086c)
*  LineGeometryElement允许更换符号以及管线符号的默认值' (!374) from 20230803 into master (959565f0)
*  wasmrequest 请求完成后同时移除回调函数的存储..避免泄漏' (!372) from 20230728 into master (da9d0e4d)
*  支持标注使用html作为ui' (!367) from 20230726 into master (eced647d)
*  更新版本' (!366) from 20230721 into master (528ef0c4)

##### 回滚

*  将影像的VND模式单独拆分出来,不影响其他的请求 (b1ca3a65)

##### 新特性

*  RenderableObject变更为空间节点,以及子类对象对应的修改 (c7c0bbbb)
*  新增Process6FrameUpdateMaterial来专门更新ExpandMaterial (dfdaf626)
*  新增画直线工具 (74bdfdbc)
*  新增画圆工具 (6ced50f9)
*  测量工具场景 (90cc64e2)
*  允许设置GUI可视范围 (6e22652d)
*  金字塔瓦片的分裂参数调整为3.5/2.9 (47cf9418)
*  增加色带采样覆盖模式 (6c90eff2)
*  线符号新增自发光变量可控制发光强度 (4bca19fc)
*  房屋符号材质改为空间材质 (03bdd6cf)
*  组符号新增分组的回调函数 (59777514)
*  3dtiles 新增缓存控制,可以有效的减少更新闪烁的问题,但是会增加内存的使用 (a7b1cb1a)
*  开放纹理重复次数属性，以及规范命名 (eb6c31a5)
*  新增屏幕点转模型点的功能,以及工具默认会在模型上取点 (c3af3eaa)
*  LineGeometryElement允许更换符号以及管线符号的默认值 (66834790)
*  添加模板影像store (16e7bddf)
*  更友好的错误提示 (0394a560)
*  3dtiles增加是否裁剪属性 (187c97e4)
*  管线剖面分析以及倾斜挖方补面 (bab1649e)
*  向前端暴露河道材质的albedoDepth和transparencyRefraction属性 (b19a63ef)
*  更友好的报错提示 (8716894c)
*  VisibleRange移动到基类作为默认属性,以及标注支持使用html作为ui (212e6812)

##### Bug修复

*  修复多个Geometry编辑冲突问题,同时仅能激活一个可编辑对象 (750e84c1)
*  Element对象改为节点的一些逻辑调整 (f933c0d1)
*  去掉fxaa避免纹理中的字体变模糊 (9c6852d3)
*  修复二维地理对象对于visibleRange的判断 (294881f0)
*  锁定模型的坐标换成GlobalTransform (63812ea8)
*  属性首字母改大写 (828cfd4b)
*  反转瓦片顶点索引，使其正面的法线垂直地表向上 (d5e1cc03)
*  修复由于底层函数改变导致的挤压方向发生改变的问题 (77ea9355)
*  使shaderItem能够在网页中使用 (b31fdbe5)
*  修改点工具操作 (c3fdaf81)
*  修复空间测量无辅助线问题 (cd05556b)
*  修复GUI的Visible和VisibleRange不能同时起作用问题 (3ade19fb)
*  修复锁定模型后会有一个小跳动的问题 (be7ac0a9)
*  限定相机观察距离 (33562eda)
*  色彩空间不转换成线性 (f1b03d5a)
*  修复相机锁定模型功能存在定位不准的问题 (e1316673)
*  修复设置BuildingSymbol透明度无效的问题 (1808603f)
*  修复顺时针挖方无法裁剪倾斜的问题 (cd8855ed)
*  修复相机飞行时的朝向问题 (1a69b4fc)
*  修复点击误差 (c71dda6d)
*  纠正代码命名 (44d65ecc)
*  命名更改 (bcf0f98d)
*  删除冗余代码 (bd324545)
*  修复GUI在Camera后依旧可见问题 (e5ca9e76)
*  去除DrawLine3D绘制、更改GUI挂载父类 (2e9667e8)
*  修复在模型上测量问题、更改GUI挂载父类 (b249efc6)
*  采用三角剖分计算面积、更改GUI挂载父类 (43e009c6)
*  父节点被清除时，清除挂载的子节点 (3cebb672)
*  将线和面的顶点挂载在自身Element (3525160c)
*  剖分时添加填充面顶点去重判断 (4e8fc6bc)
*  更改插值点数量，从固定数量到按距离计算点 (76c4b553)
*  更改取点方法 (0fa07dc9)
*  模型从及时几何改为Element (c24ae60f)
*  更改绘制工具，使用Element显示 (5855614e)
*  将_Parent变为RenderableObjectList类型 (e02d5b73)
*  设置Symbol接口 (80074113)
*  允许点线面工具在3DTiles、管线上操作 (5fa7d317)
*  开放射线图标接口 (5f44ea89)
*  开放HoleItem接口 (70415a90)
*  Destroy的时候不做SurfaceSetMaterial为空的操作,避免某些时候报错 (7a289097)
*  延迟_finish的时机避免Disconnect信号的时候报错 (1e5efb49)
*  反转地形的法线,并开放出地形的光照计算 (c41a5043)
*  修复地形某些清空出现洞的BUG (940afd1f)
*  修改管线计算uv的方式 (6db4e19b)
*  修复一些可能会影响函数的正常执行的类型检查, (9b083703)
*  修复透明色不等于0的问题 (27a9bc67)
*  拾取层改为3层 (26fa0e57)
*  修复隐藏范围为0的时候不显示的问题 (46e1f77d)
*  添加纹理重复 (56a2a381)
*  修改组合符号支持不同渲染器 (8cf2397f)
*  增加图片格式过滤条件以免转换出错 (fee6e61e)
*  使色带支持透明色 (953b05da)
*  修复element不可见的问题 (50052bae)
*  修复裁剪3dtiles的闪烁问题 (d3b401b1)
*  修复剖面分析时画的正方形形变的问题 (21faecce)
*  更友好的错误提示 (a8649b0e)
*  修复取地形问题，规范命名 (6c83c4cb)
*  编译宏 (3365fe79)
*  CurrentCapabilitie为空的时候返回空字符串 (316cd162)
*  wasmrequest 请求完成后同时移除回调函数的存储..避免泄漏 (976fd68e)
*  避免yield return对逻辑的影响,以及geometric error默认值更新为32 (ee0169a7)
*  更友好的报错提示 (29ba116b)
*  修复色带采样时uv计算错误 (f2eaf43c)
*  修复裁剪管线时无法裁掉附属物的问题 (a76a4f52)
*  divid为空的时候不进行计算 (4b8095a6)
*  srgb_to_linear的时候对图片类型进行判断避免转换失败 (df827ede)

##### 文档

*  改用空间材质 (12603fac)
*  更改挂载在Element上的子节点的Visible逻辑，以Element为主 (eb02f43a)
*  取消光线和深度对线的影响 (828e117d)
*  添加Element的回调事件 (57fd9686)
*  放出SymbolMesh，可获得三角剖分 (f4e5e028)

##### 其他

*  示例以及编辑器设置 (64e49a0a)
*  更新版本号 (e0ca322f)
*  避免每次更新版本都需要修改两句代码才能运行... (cb366b3f)
*  新增一堆资产方便开发测试(不要打包进项目) (9f4f254d)
*  更新版本 (8eb3420f)
*  更新版本 (02ae2039)

##### 性能优化

*  满足可见性的前提才允许初始化 (ff9646d4)
*  增加Element更新控制、SymbolColor设置 (7ad75215)
*  为工具添加绘制与清除Element控制 (060c164a)
*  将工具绘制的图形转化为Element (f5f30892)
*  将点、线、面Geometry中的部分函数替换为引擎的内置函数 (5180e880)

#### 0.1.4 (2023-08-07)

##### Other Changes

*  3dtiles 新增缓存控制,可以有效的减少更新闪烁的问题,但是会增加内存的使用' (!383) from 20230804 into master (9cc6cfbe)
*  修改组合符号支持不同渲染器' (!381) from dev-0731h into master (3923dea5)
*  添加纹理重复' (!382) from dev0804 into master (fcda7b91)
*  增加Element更新控制、SymbolColor设置' (!377) from Hush2023 into master (57165e42)
*  新增屏幕点转模型点的功能,以及工具默认会在模型上取点' (!376) from 20230803 into master (174a086c)
*  LineGeometryElement允许更换符号以及管线符号的默认值' (!374) from 20230803 into master (959565f0)
*  wasmrequest 请求完成后同时移除回调函数的存储..避免泄漏' (!372) from 20230728 into master (da9d0e4d)
*  支持标注使用html作为ui' (!367) from 20230726 into master (eced647d)
*  更新版本' (!366) from 20230721 into master (528ef0c4)

##### 新特性

*  线符号新增自发光变量可控制发光强度 (4bca19fc)
*  房屋符号材质改为空间材质 (03bdd6cf)
*  组符号新增分组的回调函数 (59777514)
*  3dtiles 新增缓存控制,可以有效的减少更新闪烁的问题,但是会增加内存的使用 (a7b1cb1a)
*  开放纹理重复次数属性，以及规范命名 (eb6c31a5)
*  新增屏幕点转模型点的功能,以及工具默认会在模型上取点 (c3af3eaa)
*  LineGeometryElement允许更换符号以及管线符号的默认值 (66834790)
*  添加模板影像store (16e7bddf)
*  更友好的错误提示 (0394a560)
*  3dtiles增加是否裁剪属性 (187c97e4)
*  管线剖面分析以及倾斜挖方补面 (bab1649e)
*  向前端暴露河道材质的albedoDepth和transparencyRefraction属性 (b19a63ef)
*  更友好的报错提示 (8716894c)
*  VisibleRange移动到基类作为默认属性,以及标注支持使用html作为ui (212e6812)

##### Bug修复

*  修复隐藏范围为0的时候不显示的问题 (46e1f77d)
*  添加纹理重复 (56a2a381)
*  修改组合符号支持不同渲染器 (8cf2397f)
*  增加图片格式过滤条件以免转换出错 (fee6e61e)
*  使色带支持透明色 (953b05da)
*  修复element不可见的问题 (50052bae)
*  修复裁剪3dtiles的闪烁问题 (d3b401b1)
*  修复剖面分析时画的正方形形变的问题 (21faecce)
*  更友好的错误提示 (a8649b0e)
*  修复取地形问题，规范命名 (6c83c4cb)
*  编译宏 (3365fe79)
*  CurrentCapabilitie为空的时候返回空字符串 (316cd162)
*  wasmrequest 请求完成后同时移除回调函数的存储..避免泄漏 (976fd68e)
*  避免yield return对逻辑的影响,以及geometric error默认值更新为32 (ee0169a7)
*  更友好的报错提示 (29ba116b)
*  修复色带采样时uv计算错误 (f2eaf43c)
*  修复裁剪管线时无法裁掉附属物的问题 (a76a4f52)
*  divid为空的时候不进行计算 (4b8095a6)
*  srgb_to_linear的时候对图片类型进行判断避免转换失败 (df827ede)

##### 其他

*  避免每次更新版本都需要修改两句代码才能运行... (cb366b3f)
*  新增一堆资产方便开发测试(不要打包进项目) (9f4f254d)
*  更新版本 (8eb3420f)
*  更新版本 (02ae2039)

##### 性能优化

*  增加Element更新控制、SymbolColor设置 (7ad75215)
*  为工具添加绘制与清除Element控制 (060c164a)
*  将工具绘制的图形转化为Element (f5f30892)
*  将点、线、面Geometry中的部分函数替换为引擎的内置函数 (5180e880)

#### 0.1.3 (2023-07-28)

##### Other Changes

*  支持标注使用html作为ui' (!367) from 20230726 into master (eced647d)
*  更新版本' (!366) from 20230721 into master (528ef0c4)

##### 新特性

*  更友好的报错提示 (8716894c)
*  VisibleRange移动到基类作为默认属性,以及标注支持使用html作为ui (212e6812)

##### Bug修复

*  divid为空的时候不进行计算 (4b8095a6)
*  srgb_to_linear的时候对图片类型进行判断避免转换失败 (df827ede)

##### 其他

*  更新版本 (02ae2039)

##### 性能优化

*  将工具绘制的图形转化为Element (f5f30892)
*  将点、线、面Geometry中的部分函数替换为引擎的内置函数 (5180e880)

#### 0.1.2 (2023-07-21)

##### Other Changes

*  新增点线面要素的分级和唯一值渲染, 统一Color类型' (!359) from dev-symbol0718 into master (d8a77b3f)
*  新增ScreenGUIElement等' (!357) from 20230712 into master (c0e180a8)
*  影像金字塔递归条件判断,优化分裂个数' (!355) from 20230707 into master (e477d4e5)
*  点、线、面编辑操作' (!350) from Hush2023 into master (1c385e05)
*  暂时关闭3dtiles的内存缓存以及减少TileDrawDistance的默认值' (!352) from 0625 into master (fef73bf8)
*  添加新FeatureRenderer,修改GaeaGeoDataBase继承关系' (!351) from release0616 into master (cd586b66)
*  3dtiles优化超出范围后的请求裁剪,以及isOnScreenLongEnough检测' (!343) from 0615 into master (3517be12)

##### 回滚

*  暂时关闭3dtiles的内存缓存以及减少TileDrawDistance的默认值 (9e982a5c)
*  相机Fov默认为60 (3a2aac99)

##### 新特性

*  新增点线面要素的分级和唯一值渲染, 统一Color类型 (f75f720a)
*  开放水材质的TransparencyClarity属性 (be5f9fa4)
*  导出GeometryElement及其子类，polygon不可编辑时不响应鼠标事件 (52159de0)
*  增加图层加载完成时的回调函数 (a40fd949)
*  新增ScreenGUIElement (cbc168ea)
*  开放碰撞开关,悬浮颜色和点击颜色以及图标整体高度偏移,图标高度取地形 (0797f80b)
*  GaeaDisplay.Element支持点击 (fc1fe76a)
*  WASM版本请求更新 (1f28df65)
*  新增对影像混合模式服务的支持。若配置中使用了默认服务可能会影响旧版本 (faaad45d)
*  将颜色属性改为Color类型,并开放buildingSymbol的高度接口 (4dd1dda2)
*  可选择是否显示工具的操作提示 (e5ca5df5)
*  射线检测过程移到c++底层,提高效率 (7f7832af)
*  支持点击GltfElement的子模型，可自定义击中时回调事件 (e9a9ee72)
*  web端解析纹理时额外执行线性转换 (956a7a5c)
*  增加射线切割线 (5d6fe692)
*  增加点、线、面的编辑操作 (ebd171c8)
*  影像/3dtiles缓存控制的实现 (65492647)
*  新增对影像/3dtiles缓存的控制，以及调试信息 (553da109)
*  添加新FeatureRenderer,修改GaeaGeoDataBase继承关系 (307f756a)
*  鼠标滚轮速率调整以及影像缓存设置 (9ac63b95)
*  系统数组的拓展 (a68ad4ff)
*  开放协程并发量属性 (f9d93a21)
*  去掉GUI.tscn依赖的脚本，提供设置viewport的大小的方法 (f6f7bbce)
*  在没有加载出云层与概图图片时，cloud与earthinside默认关闭 (54d0d760)
*  导出WorldCamera，可去掉设置相机位置时的动画 (c78d8f79)

##### Bug修复

*  加载模型的时候自动禁用倾斜的加载避免报错 (9090e15c)
*  允许存在只存在一张TerrainMap (4a651d64)
*  修改_FillColor类型为Color (cc2901dc)
*  修复无法点击到最近的3dtiles的模型的问题 (9a1e1474)
*  过滤掉没有地理坐标的数据 (23f99806)
*  贴花类型默认值 (81233d3d)
*  修复更新请求后地形需要自行获取流 (7d3701ef)
*  网页加载图片资源时进行颜色转换,解决网页纹理图片颜色很浅的问题 (471dafe9)
*  修复网页端瓦片贴图的颜色泛白的问题 (75579545)
*  修复带碰撞icon的贴图方向不对 (f71a99b0)
*  wasm版请求不再为每个对象创建独立的回调函数 (2faffa96)
*  解决使用wasm请求模式的内存释放问题 (a45206c0)

##### 其他

*  默认环境 (732ae0c3)

##### 性能优化

*  影像金字塔递归条件判断,优化分裂个数 (8f8c541d)
*  3dtiles LRU缓存 (aaec42b5)
*  协程排队等待机制 (2961a724)
*  3dtiles优化超出范围后的请求裁剪,以及isOnScreenLongEnough检测 (fd6d32a5)

#### 0.1.1 (2023-06-07)

##### Other Changes

*  计算瓦片法线' (!340) from nx-project0520 into master (5ee758f0)
*  解决网页端无法使用Poly2Tri的问题' (!339) from nx-project0520 into master (cb5e42df)
*  开挖和影像贴花回归' (!337) from 0525 into master (7d0eca35)
* 3000/root/gaea-explorer into project_export (a91f5b60)

##### 回滚

*  撤销对PlayAnimation的移除,有项目任在使用 (fc7ddfb8)
*  回退到使用模型的X轴正方向作为模型的朝向 (b4e87fb9)
*  开挖和影像贴花回归 (1490d029)
*  重新开放协程IO (408e65c4)
*  去掉一些无用代码 (3edef2cc)
*  去掉TileMatrixSetLink的导出 (1c51faff)
*  暂时去掉对象池 (9ffa16b9)

##### 新特性

*  影像贴花支持色带采样 (8d3d8f48)
*  实现将控件放到三维空间的功能，并新增Button等类型的导出 (0c26178f)
*  添加了一个可供前端使用的GaeaButton类 (db702ba0)
*  导出任务管理器的配置项 (3538ab7e)
*  协程调试开关 (0262e84e)
*  模型的绝对高度 (41159d82)
*  添加以YZX欧拉角形式表示的相对旋转属性 (5a7d9763)
*  相机最大高度接口MaximumAltitudeForSphere (0c48cc52)
*  开放反转相机视角，并默认为false (e1fb8152)
*  新增一个浏览器端专用的请求 (34d02e0f)
*  添加反转相机旋转操作的接口 (9497842f)
*  开放相机变焦速度接口CameraZoomAcceleration (b9ed7ee4)
*  新增接口，设置相机位置时无插值动画 (f12fa1e8)
*  拓展AnimationPlayer，使其支持能在前端当动画播放开始与结束时执行自定义函数 (56aa5ca8)

##### Bug修复

*  反转UseAbsoluteHeight属性，重载SphericalToGlobeTransform函数 (c196e8cd)
*  修复加载gltf模型时旋转不正确的问题 (c066bf03)
*  修复模型被意外点击到的问题和无法点中子模型的问题 (1a68e02f)
*  计算瓦片法线 (7357bf6a)
*  解决网页端无法使用Poly2Tri的问题 (b8293e17)
*  3dtiles默认不使用缓存 (d41fb07c)
*  修复模型的点击以及地理位置旋转 (e3269998)
*  修复重置请求的时候,请求还未开始的问题 (5df8446f)
*  modelElement回调执行错误 (39e6a033)
*  修复在非跳层模式加载3dtiles下无法加载到精细层级的问题 (75b1e444)
*  修改模型点击查询的逻辑 (325c7f0b)
*  修改ModelElement的属性设置方式，开放父节点属性 (4bdb7cec)
*  将太阳直射光的父节点的Transform重置，以避免光线方向出错 (19acf8ca)
*  修复同时设置或更改ModelElement位置与旋转时出现的bug (733a057a)
*  重设Transform的同时也要重设旋转 (29b0653a)
*  变更了一下旋转与缩放的顺序，以免出现问题 (772bd961)
*  修复当修改ModelElement的GeographyPosition与LocalRotation属性时，其大小也会随之变动的问题 (63cf8683)
*  基本解决3dtiles的内存泄漏 (132abc48)
*  修复CalculateRotationByTime无法平行于地表插值的问题 (c9c423dc)
*  修复相机无法锁定视图的问题 (909d0369)
*  避免ImgStoreStatusList更新时向MeshRenders中重复添加store (ba6f090f)

##### 其他

*  暂时加入一个hdr贴图让pbr材质渲染得更好看 (6f1ea83f)

##### 未完成的功能

*  金字塔瓦片释放过程,暂时去掉cancel机制保证稳定性 (c602fb87)
*  worker/coroutine 修复 (b71542b1)

##### 性能优化

*  资源加载使用通用的请求优化网页端的请求效率 (eb62ac5f)

#### 0.1.0 (2023-04-14)

##### Other Changes

*  给相机的LockToEntity模式添加可选视图属性； (426ef305)
*  标注点增加VisibleRange功能' (!316) from 23-3-30 into master (fe25b833)

##### 新特性

*  比较两个四元数是否近似相等 (24d0ebf2)
*  标注点增加VisibleRange功能 (af0df8a7)

##### Bug修复

*  地形某些情况为无效值的情况以及材质的非空判断 (5ad2db52)

##### 性能优化

*  协程优先级排序更新 (a66053d8)

#### 0.0.9 (2023-04-07)

##### Other Changes

*  水面纹理改为仅读取rg值模拟法线贴图' (#314) from river into master (16903453)
*  完善相机的LockToEntity模式' (#313) from project_export into master (38b90013)

##### Bug修复

*  水面纹理改为仅读取rg值模拟法线贴图 (14bb8957)

##### 性能优化

*  完善相机的LockToEntity模式 (3a847065)

#### 0.0.8 (2023-04-06)

##### Other Changes

* 3000/root/gaea-explorer into project_export (640026f7)
*  新增ModelElement' (#307) from dannyjones into master (b619d8dc)
*  修复中英字体间距过大' (#306) from 2023-3-22 into master (7f887c0e)

##### 新特性

*  添加一个GLTFElement的ModelPop接口 (1d3fa23a)

##### Bug修复

*  修复文字的上下左右显示位置 (279e438b)
*  修复中英字体间距过大 (5c0d0623)
*  修复移除挖方时未将对应材质的pointInface归零的bug (1addee1b)

##### 其他

*  更新版本号 (b1a3990f)

##### 性能优化

*  ToAnimationBySpeed和ToAnimationByTime增加缩放参数，以保持插值时的缩放与原来相同 (b03ad478)
*  将插值后的结果设置为只读 (795b0881)
*  包装AnimationPlayer.Play函数，以解决直接在网页调用没有反应的问题 (1a61f195)
*  增加导出AnimationPlayer和Animation (4935708a)

#### 0.0.7 (2023-03-27)

##### 新特性

*  新增ModelElement (e31b02fc)
*  完善Curve类型，以生成飞行动画 (1250802b)

##### Bug修复

*  修复河流建模 (1953c029)
*  修复光照属性的默认值为false (fcd3109c)

##### 性能优化

*  将插值后的结果设置为只读 (795b0881)
*  包装AnimationPlayer.Play函数，以解决直接在网页调用没有反应的问题 (1a61f195)
*  增加导出AnimationPlayer和Animation (4935708a)

#### 0.0.6 (2023-03-21)

##### Other Changes

*  修复创建MultiPolygonGeometry时polygons未初始化的bug' (#302) from project_export into master (fcb704e2)
*  更新版本号' (#300) from coroutine into master (f0af628c)

##### 新特性

*  新增导出QuadMesh，Mathf (3d4604b7)

##### Bug修复

*  修复worker执行完毕后对类型的判断 (2ae22f9a)
*  修复GetDownloadUrl的时候对Capabilitie的非空判断 (8c19f9b7)
*  修复创建MultiPolygonGeometry时polygons未初始化的bug (dbae7c18)
*  回收执行完毕的协程 (32f8d24b)
*  修复地形无效值判断统一使用InvalidValueDef作为唯一无效值依据 (08cd75c4)
*  markSymbol Shader修复中英文混排 (23d06207)

##### 其他

*  更新版本号 (f23058ea)
*  更新版本号 (618e3c3f)

##### 未完成的功能

*  修复GltfElement物理体结构，以及新增导出StaticBody (14fa6c37)
*  3dtiles新增cmpt和i3dm两种类型的content的解析 (d175cb7b)
*  新增GltfElement以及示例 (b4c81e39)

#### 0.0.5 (2023-03-17)

##### Other Changes

*  更新版本号' (#300) from coroutine into master (f0af628c)

##### 新特性

*  新增导出QuadMesh，Mathf (3d4604b7)

##### Bug修复

*  回收执行完毕的协程 (32f8d24b)
*  修复地形无效值判断统一使用InvalidValueDef作为唯一无效值依据 (08cd75c4)
*  markSymbol Shader修复中英文混排 (23d06207)

##### 其他

*  更新版本号 (618e3c3f)

##### 未完成的功能

*  新增GltfElement以及示例 (b4c81e39)

#### 0.0.4 (2023-03-14)

##### 新特性

*  TextMark符号增加颜色和边框颜色配置的属性 (56a0b5cf)
*  图层管理中新增插入以及图层的隐藏功能 (8efe8cfc)
*  默认光照白平衡.（地形暂时去掉光照影响） (12770423)

##### Bug修复

*  修复要素图层删除没效果的BUG (42817c18)
*  增加地形数据长度是否符合规范判断 (52080966)
*  修改3dtiles的默认图层 (ef3634eb)
*  修复BaseUrl在网页端不能初始化的bug (cc4f99ed)

##### 其他

*  移至三方库文件夹 (406713c6)

##### 性能优化

*  协程效率优化 (911b6d44)

#### 0.0.3 (2023-03-01)

##### 新特性

*  水文断面数据建模 (6046276d)

##### Bug修复

*  修复太阳位置的计算方式 (46e9134d)
*  修复更新偏移时忘记计算RTC_Center (8f9277f7)
*  修复水文截面建模时模型构建错误问题 (5ba67f39)
*  修复网页使用水文截面图片问题 (8d67d15a)
*  椭球笛卡尔转圆球笛卡尔..（未来会将球改为椭球） (508f5fe9)

#### 0.0.2 (2023-03-01)

##### Other Changes

* 3000/root/gaea-explorer into GaeaExplorer4.0.0.2 (40c8c24b)
* 3000/root/gaea-explorer into thread_nx (66f7f38f)

##### 回滚

*  删除未使用的代码 (b3a2a571)
*  协程间隔调整,待测试 (5a08a906)

##### 新特性

*  3dtiles跳层模式最新优化版本 (f740eb2d)
*  效率优化!!! 注意判断文件是否存在使用World的中的静态变量等等细节. (a05f7a3b)
*  相机动画分成鼠标操作和飞行两种模式 (64865992)
*  多线程优化 (edb358d8)
*  3dtiles的IO部分改为多线程 (5229e351)
*  相机区分pan和飞行,分别用不同的速度来控制 (483a9683)
*  示例 (5b7b4bfa)
*  影像IO以及纹理加载部分改为多线程 (7d0c5e74)
*  协程读取地形高程 (544e0542)
*  新版多线程模型 (9ae7dab9)

##### Bug修复

*  重新启用3dtiles的LocalOffset属性 (1d4bb0ec)
*  重新启用3dtiles的LocalOffset属性 (f5521471)
*  移除NewtonsoftJson和不需要的类以及3DTiles内存释放优化 (444a6978)
*  天地图ReadElevationDataCo改为IO异步任务 (84322891)

##### 其他

*  修改示例默认图标 (c1cf8c86)
*  示例 (0ce63f6f)

##### 性能优化

*  着色器修改 (4a8d1a91)
*  使用协程和多线程解析geojson,提高流畅度 (592f6b43)
*  完善了矢量的加载逻辑 (c8077c0a)
*  修改了线的着色器 (6099d2dc)
*  矢量高程的获取层级由固定层级改为对应的瓦片层级 (6e3bec62)
*  优化了解析featureclass的效率 (40e87e8b)
*  完善符号 (41dfce53)
