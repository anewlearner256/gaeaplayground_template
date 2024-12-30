tool  
extends EditorPlugin  

var tree  
var button  
var instance  
var RefreshBtn  
var lineEdit  

# 定义允许显示的文件扩展名  
var allowed_extensions = ["tscn", "scn", "gd", "png", "jpg", "wav", "ogg", "tres", "res"]  

func _enter_tree():  
	# 加载插件界面  
	var scene = load("res://addons/BinaryConversionFile/BinaryConversionFileRES.tscn")  
	instance = scene.instance()  

	# 添加到编辑器左侧的 Dock 面板  
	add_control_to_dock(DOCK_SLOT_LEFT_UL, instance)  

	# 获取界面中的节点  
	tree = instance.get_node("Tree")  
	button = instance.get_node("Button")  
	RefreshBtn = instance.get_node("Refresh")  
	lineEdit = instance.get_node("LineEdit")  

	# 连接按钮信号  
	button.connect("pressed", self, "_on_button_pressed")  
	RefreshBtn.connect("pressed", self, "_on_RefreshBtn_pressed")  

	# 构建文件树  
	_build_file_tree()  

func _exit_tree():  
	# 移除插件界面  
	add_control_to_dock(DOCK_SLOT_LEFT_UL, instance)  

func _add_files_to_tree(parent_item, path):  
	var dir = Directory.new()  
	if dir.open(path) == OK:  
		dir.list_dir_begin()  
		var file_name = dir.get_next()  
		while file_name != "":  
			if file_name != "." and file_name != "..":  
				var item = tree.create_item(parent_item)  
				item.set_text(0, file_name)  
				item.set_collapsed(true)  
				var full_path = path.plus_file(file_name)  
				if dir.current_is_dir():  
					_add_files_to_tree(item, full_path)  
				else:  
					# 使用字符串切割来获取文件扩展名  
					var extension = file_name.get_extension()  
					if extension in allowed_extensions:  
						item.set_metadata(0, full_path)  
			file_name = dir.get_next()  
		dir.list_dir_end()  

func _on_RefreshBtn_pressed():  
	# 刷新文件树  
	_build_file_tree()  

func _build_file_tree():  
	# 清空当前文件树并重新构建  
	tree.clear()  
	var root = tree.create_item()  
	_add_files_to_tree(root, "res://")  

func _on_button_pressed():  
	# 获取选中的文件并处理  
	var selected_items = _get_selected_items()  
	if not selected_items or selected_items.empty():  
		print("没有选中任何文件")  
		return  # 如果没有选中任何文件，直接返回  

	for item in selected_items:  
		var file_path = item.get_metadata(0)  
		if file_path:  
			if _validate_file(file_path):  
				_process_scene_for_flipbook(file_path)  # 新增处理逻辑  
				_convert_to_resource(file_path)  
			else:  
				print("插件没问题，就是你小子文件有问题:", file_path) 


func _process_scene_for_flipbook(file_path):  
	# 加载场景文件  
	var resource = ResourceLoader.load(file_path)  
	if resource and resource is PackedScene:  
		var root = resource.instance()  # 实例化场景根节点  
		if root:  
			# 检查主场景节点是否为 MeshInstance  
			if root is MeshInstance:  
				_process_mesh_instance_flipbook(root)  
			else:  
				print("主场景节点不是 MeshInstance:", root.name)  
	else:  
		print("无法加载场景文件:", file_path)  


func _process_mesh_instance_flipbook(mesh_instance):  
	# 获取 MeshInstance 的材质  
	var material = mesh_instance.get_surface_material(0)  # 获取第一个材质  
	if material and material is ShaderMaterial:  
		# 尝试获取 flipbook 参数  
		print("获取到了ShaderMaterial")
		if material.get_shader_param("flipbook") != null:  
			var flipbook_texture = material.get_shader_param("flipbook")  
			if flipbook_texture and flipbook_texture is Texture:  
				print("检测到主场景 MeshInstance 的 flipbook 参数:", flipbook_texture)  
				# 唯一化 flipbook 参数的纹理  
				material.set_shader_param("flipbook", _make_resource_local(flipbook_texture))  
			else:  
				print("flipbook 参数不存在或不是纹理:", flipbook_texture)  
		else:  
			print("ShaderMaterial 中没有定义 flipbook 参数")  
	else:  
		print("主场景 MeshInstance 没有有效的 ShaderMaterial") 



func _get_selected_items():  
	# 获取文件树中选中的项目  
	var selected_items = []  
	var item = tree.get_next_selected(null)  # 第一次调用传入 null  
	while item:  
		selected_items.append(item)  
		item = tree.get_next_selected(item)  # 传入上一个选中的项目  
	return selected_items  

func _validate_file(file_path):  
	# 验证文件是否有效  
	var extension = file_path.get_extension()  
	return extension in allowed_extensions  

func _convert_to_resource(file_path):  
	# 加载资源  
	var resource = ResourceLoader.load(file_path)  
	if resource:  
		if resource is PackedScene:  
			_convert_scene_to_res(file_path, resource)  
		else:  
			_convert_to_resource_tres(file_path, resource)  
	else:  
		print("无法加载文件:", file_path)  

func _convert_scene_to_res(file_path, scene):  
	# 处理场景文件并转换为 .res  
	var root = scene.instance()  
	
	# 确保所有外部依赖资源被唯一化  
	_ensure_dependencies(root)  
	
	var packed_scene = PackedScene.new()  
	var err = packed_scene.pack(root)  
	if err != OK:  
		print("打包场景失败:", file_path)  
		return  

	var save_path = _get_save_path(file_path)  
	# 使用 FLAG_BUNDLE_RESOURCES 以确保嵌入资源被正确打包  
	var error = ResourceSaver.save(save_path, packed_scene, ResourceSaver.FLAG_BUNDLE_RESOURCES)  
	if error == OK:  
		print("成功导出带所有资源的.res文件:", save_path)  
	else:  
		print("保存场景文件失败:", save_path)  

func _convert_to_resource_tres(file_path, resource):  
	# 处理普通资源文件并转换为 .res  
	var save_path = _get_save_path(file_path)  
	# 使用 FLAG_BUNDLE_RESOURCES 以确保嵌入资源被正确打包  
	var error = ResourceSaver.save(save_path, resource, ResourceSaver.FLAG_BUNDLE_RESOURCES)  
	if error == OK:  
		print("成功导出资源文件:", save_path)  
	else:  
		print("保存资源文件失败:", save_path) 

func _get_save_path(file_path):  
	# 生成保存路径  
	var output_dir = lineEdit.text.strip_edges()  
	if output_dir == "":  
		output_dir = "res://exported_res"  
	if not Directory.new().dir_exists(output_dir):  
		Directory.new().make_dir(output_dir)  
	return output_dir + "/" + file_path.get_file().get_basename() + ".res"  

func _ensure_dependencies(node):  
	# 遍历子节点  
	for child in node.get_children():  
		if child is Particles:  
			_process_particles_draw_passes(child)  
			# 获取 Particles 的 Process Material  
			var process_material = child.get("process_material")  
			if process_material and process_material is Material:  
				print("检测到 Particles 的 Process Material:", process_material)  
				# 唯一化 Process Material  
				child.set("process_material", _make_resource_local(process_material))  

				# 递归处理 Process Material 中的依赖资源  
				_ensure_material_dependencies(process_material)  

			# 唯一化 Color Ramp 的 GradientTexture（如果存在）  
			var gradient_texture = process_material.get("color_ramp") if process_material else null  
			if gradient_texture and gradient_texture is GradientTexture:  
				gradient_texture.set_path("")  # 清除外部路径  
				gradient_texture.resource_local_to_scene = true  # 设置为场景本地资源  
				print("唯一化 GradientTexture 成功:", gradient_texture)  

				# 唯一化 GradientTexture 内部的 Gradient  
				var gradient = gradient_texture.get("gradient")  
				if gradient and gradient is Gradient:  
					gradient.set_path("")  # 清除外部路径  
					gradient.resource_local_to_scene = true  # 设置为场景本地资源  
					print("唯一化 Gradient 成功:", gradient)  
	# 递归处理子节点  
	for child in node.get_children():  
		_ensure_dependencies(child)  

# 处理 Particles 节点的 Draw Passes  
func _process_particles_draw_passes(particles_node):  
	# 遍历 Draw Passes  
	var draw_pass_count = particles_node.get("draw_passes")  # 获取 draw_passes 的数量  
	print("draw_pass_count: ", draw_pass_count)
	if draw_pass_count > 0:  
		for i in range(draw_pass_count):  
			var draw_pass_material = particles_node.get("draw_pass_" + str(i + 1))  # 获取 draw_passes_1, draw_passes_2 等  
			print("draw_pass_material: ", draw_pass_material)
			if draw_pass_material and draw_pass_material is QuadMesh:  
				print("检测到 Particles 的 Draw Passes 材质:", i + 1, "在节点:", particles_node.name)  
				_ensure_material_dependencies(draw_pass_material)  

# 处理材质中的依赖资源  
func _ensure_material_dependencies(material):  
	var material_properties = material.get_property_list()  
	for property in material_properties:  
		var property_name = property.name  
		var property_value = material.get(property_name)  

		# 如果材质属性是纹理类型，唯一化它  
		if property_value and property_value is Texture:  
			print("检测到材质中的纹理属性:", property_name, "在材质:", material)  
			material.set(property_name, _make_resource_local(property_value))  

		# 如果材质属性是嵌套的材质，递归处理  
		if property_value and property_value is Material:  
			print("检测到嵌套材质:", property_name, "在材质:", material)  
			_ensure_material_dependencies(property_value)
	
# 将资源唯一化并设置为场景本地资源  
func _make_resource_local(resource):  
	if resource:  
		# 如果资源是 StreamTexture，尝试转换为 ImageTexture  
		if resource is StreamTexture:  
			print("检测到 StreamTexture 资源:", resource.get_path())  
			print("StreamTexture 尺寸:", resource.get_size())  
			var image = resource.get_data()  # 获取纹理数据  
			if image:  
				var image_texture = ImageTexture.new()  
				image_texture.create_from_image(image)  # 从图像数据创建新的纹理  
				image_texture.resource_local_to_scene = true  # 设置为场景本地资源  
				print("成功将 StreamTexture 转换为 ImageTexture")  
				return image_texture  
			else:  
				print("StreamTexture 数据为空，无法转换")  
				return null  

		# 对于其他资源，直接唯一化  
		resource.set_path("")  # 清除外部路径  
		resource.resource_local_to_scene = true  # 设置为场景本地资源  
		print("成功唯一化其他资源:", resource)  
		return resource  
	return null 
