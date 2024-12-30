tool # 删除了多余的代码，增加了新的协程
extends EditorPlugin

const CHUNK_SIZE = 8 * 1024 * 1024  # 8MB chunks for reading

# UI 节点引用
var tree
var button
var instance
var RefreshBtn
var lineEdit
var resource_manager = ResourceManager.new()
var progressBar

# 允许的文件扩展名
var allowed_extensions = ["tscn", "scn", "gd", "png", "material", "jpg", "wav", "ogg", "tres", "res", "shader", "gdshader"]

func _enter_tree():
	var scene = load("res://addons/PCKExporter/BinaryConversionFilePCK.tscn")
	instance = scene.instance()
	
	add_control_to_dock(DOCK_SLOT_LEFT_UL, instance)
	
	# 获取UI引用
	tree = instance.get_node("Tree")
	button = instance.get_node("Button")
	RefreshBtn = instance.get_node("Refresh")
	lineEdit = instance.get_node("LineEdit")
	progressBar = instance.get_node("ProgressBar")  
	
	button.connect("pressed", self, "_on_button_pressed")
	RefreshBtn.connect("pressed", self, "_on_RefreshBtn_pressed")
	
	_build_file_tree()

func _exit_tree():
	if instance:
		remove_control_from_docks(instance)
		instance.queue_free()

func _build_file_tree():
	progressBar.value = 0
	if tree:
		tree.clear()
		var root = tree.create_item()
		root.set_text(0, "res://")
		_scan_files("res://", root)

func _scan_files(path: String, parent):  
	var dir = Directory.new()  
	if dir.open(path) == OK:  
		dir.list_dir_begin(true, true)  
		var file_name = dir.get_next()  

		while file_name != "":  
			var full_path = path + file_name  

			if dir.current_is_dir():  
				var child = tree.create_item(parent)  
				child.set_text(0, file_name)  
				child.set_metadata(0, full_path)  
				child.set_collapsed(true)  
				yield(get_tree().create_timer(0.01), "timeout")  # Shorter delay  
				_scan_files(full_path + "/", child)  
			else:  
				var extension = file_name.get_extension().to_lower()  
				if allowed_extensions.has(extension):  
					var child = tree.create_item(parent)  
					child.set_text(0, file_name)  
					child.set_metadata(0, full_path)  

			file_name = dir.get_next()  
			yield(get_tree().create_timer(0.01), "timeout")  # Shorter delay  

		dir.list_dir_end()   

func _on_RefreshBtn_pressed():
	_build_file_tree()

func _on_button_pressed():
	var selected_items = []
	_get_selected_items(tree.get_root(), selected_items)
	
	if selected_items.empty():
		print("没有选择任何文件")
		return
	
	if lineEdit.text.empty():
		print("请选择输出路径")
		return
	

	convert_to_pck_async(selected_items)
	

func _get_selected_items(item, selected_items):
	if item.is_selected(0):
		selected_items.append(item)
	
	var child = item.get_children()
	while child:
		_get_selected_items(child, selected_items)
		child = child.get_next()

func _calculate_total_files(selected_items) -> int:  
	var total_files = 0  
	var added_files = []  
	for item in selected_items:  
		var file_path = item.get_metadata(0)  
		if file_path:  
			total_files += _count_dependencies(file_path, added_files)  
	return total_files

func _count_dependencies(file_path: String, added_files: Array) -> int:  
	if file_path in added_files:  
		return 0  

	added_files.append(file_path)  
	var count = 1  # Count the current file  

	if file_path.ends_with(".tscn"):  
		var file = File.new()  
		if file.open(file_path, File.READ) == OK:  
			var content = file.get_as_text()  
			file.close()  
			var regex = RegEx.new()  
			regex.compile("\\[ext_resource path=\"(.*?)\"")  
			var results = regex.search_all(content)  
			for result in results:  
				var path = result.get_string(1)  
				count += _count_dependencies(path, added_files)  

	return count

func _update_progress(increment: int):  
	progressBar.value += increment  


func convert_to_pck_async(selected_items):  
	progressBar.value = 0  
	progressBar.max_value = selected_items.size()  

	var packer = PCKPacker.new()  
	var first_file_path = selected_items[0].get_metadata(0)  
	var base_name = first_file_path.get_file().get_basename()  
	var pck_path = lineEdit.text + "/" + base_name + ".pck"  

	print("\n开始打包PCK文件...")  
	print("PCK输出路径:", pck_path)  

	var err = packer.pck_start(pck_path)  
	if err != OK:  
		print("无法创建PCK文件:", err)  
		return  

	var added_files = []  

	yield(get_tree().create_timer(0.1), "timeout")  # Initial yield  
	for item in selected_items:  
		var file_path = item.get_metadata(0)  
		if file_path:  
			print("\n处理文件:", file_path)  
			if _process_large_file(packer, file_path, added_files):  
				print("成功添加:", file_path)  
			else:  
				print("处理失败:", file_path)  

			progressBar.value += 1  
			yield(get_tree().create_timer(0.1), "timeout")  # Add yield here  

	packer.flush()  
	print("\nPCK文件导出完成:", pck_path)  

func _process_binary_dependencies(packer: PCKPacker, binary_path: String, added_files: Array):  
	# 使用 ResourceLoader 加载二进制文件  
	var resource = ResourceLoader.load(binary_path)  
	if not resource:  
		print("无法加载资源文件:", binary_path)  
		return  

	# 检查资源类型  
	if resource is SpatialMaterial:  
		_process_material_dependencies(packer, resource, added_files)  
	elif resource is ShaderMaterial:  
		_process_shader_material_dependencies(packer, resource, added_files)  
	elif resource is Resource:  
		_process_generic_resource_dependencies(packer, resource, added_files)  

	# 添加当前文件到 PCK  
	var err = packer.add_file(binary_path, binary_path)  
	if err == OK:  
		added_files.append(binary_path)  
		print("添加二进制文件:", binary_path)  
	else:  
		print("添加二进制文件失败:", binary_path, " 错误码:", err)

func _process_material_dependencies(packer: PCKPacker, material: SpatialMaterial, added_files: Array):  
	# 遍历可能的纹理属性  
	var texture_properties = [  
		"albedo_texture",  
		"normal_texture",  
		"roughness_texture",  
		"metallic_texture",  
		"emission_texture",  
		"ao_texture",  
		"clearcoat_texture",  
		"clearcoat_roughness_texture",  
		"depth_texture"  
	]  

	for property in texture_properties:  
		# 使用 get() 获取属性值  
		var texture = material.get(property)  
		if texture and texture is Texture:  
			var texture_path = texture.resource_path  
			if texture_path and not texture_path in added_files:  
				print("处理材质依赖纹理:", texture_path)  
				_process_large_file(packer, texture_path, added_files)  

func _process_shader_material_dependencies(packer: PCKPacker, material: ShaderMaterial, added_files: Array):  
	# 处理着色器文件  
	var shader = material.shader  
	if shader:  
		var shader_path = shader.resource_path  
		if shader_path and not shader_path in added_files:  
			print("处理着色器文件:", shader_path)  
			_process_large_file(packer, shader_path, added_files)  

	# 处理着色器参数中的纹理  
	var param_list = material.get_shader_param_list()  
	for param in param_list:  
		var value = material.get_shader_param(param.name)  
		if value and value is Texture:  
			var texture_path = value.resource_path  
			if texture_path and not texture_path in added_files:  
				print("处理着色器依赖纹理:", texture_path)  
				_process_large_file(packer, texture_path, added_files)


func _process_generic_resource_dependencies(packer: PCKPacker, resource: Resource, added_files: Array):  
	# 遍历资源的所有属性  
	var property_list = resource.get_property_list()  
	for property in property_list:  
		# 获取属性值  
		var value = resource.get(property.name)  

		# 检查属性值是否是资源类型  
		if value and value is Resource:  
			var sub_resource_path = value.resource_path  
			if sub_resource_path and not sub_resource_path in added_files:  
				print("处理通用资源依赖:", sub_resource_path)  
				_process_large_file(packer, sub_resource_path, added_files) 

func _process_large_file(packer: PCKPacker, file_path: String, added_files: Array) -> bool:  
	# 如果文件已经被处理过，直接返回  
	if file_path in added_files:  
		return true  

	var file = File.new()  
	if !file.file_exists(file_path):  
		print("文件不存在:", file_path)  
		return false  
		
	# 如果是 material 或 res 文件，处理其依赖资源  
	if file_path.ends_with(".material") or file_path.ends_with(".res"):  
		_process_binary_dependencies(packer, file_path, added_files)

	# 如果是 .tres 文件，特殊处理  
	if file_path.ends_with(".tres"):  
		_process_tres_dependencies(packer, file_path, added_files)  

	# 如果是 .tscn 文件，处理场景依赖  
	if file_path.ends_with(".tscn"):  
		_process_scene_dependencies(packer, file_path, added_files)  

	# 添加当前文件到 PCK  
	var err = packer.add_file(file_path, file_path)  
	if err != OK:  
		print("添加文件失败:", file_path, " 错误码:", err)  
		return false  
	else:  
		print("已经添加的文件：", file_path)  

	# 将当前文件路径加入已处理列表  
	added_files.append(file_path)  

	# 如果是图片资源，处理其 .import 文件  
	if file_path.ends_with(".png") or file_path.ends_with(".jpg"):  
		_add_imported_resource(packer, file_path, added_files)  

	# 添加延时，避免阻塞主线程  
	yield(get_tree().create_timer(0.1), "timeout")  
	return true   
	

func _process_tres_dependencies(packer: PCKPacker, tres_path: String, added_files: Array):  
	var file = File.new()  
	if file.open(tres_path, File.READ) != OK:  
		print("无法打开 .tres 文件:", tres_path)  
		return  

	var content = file.get_as_text()  
	file.close()  

	# 使用正则表达式提取 ext_resource 引用  
	var regex_ext = RegEx.new()  
	regex_ext.compile("\\[ext_resource path=\"(.*?)\"")  
	var ext_results = regex_ext.search_all(content)  

	for result in ext_results:  
		var ext_path = result.get_string(1)  
		if !ext_path in added_files and File.new().file_exists(ext_path):  
			print("处理 .tres 文件中的外部资源:", ext_path)  
			_process_large_file(packer, ext_path, added_files)  

	print("完成 .tres 文件依赖解析:", tres_path)  


func _process_scene_dependencies(packer: PCKPacker, scene_path: String, added_files: Array):  
	var file = File.new()  
	if file.open(scene_path, File.READ) != OK:  
		return  

	var content = ""  
	while !file.eof_reached():  
		content += file.get_line() + "\n"  
		if content.length() > CHUNK_SIZE:  
			_process_content_dependencies(packer, content, added_files)  
			content = ""  
			yield(get_tree().create_timer(0.01), "timeout")  # Shorter delay  

	if content.length() > 0:  
		_process_content_dependencies(packer, content, added_files)  

	file.close()  

func _process_content_dependencies(packer: PCKPacker, content: String, added_files: Array):  
	var regex = RegEx.new()  
	regex.compile("\\[ext_resource path=\"(.*?)\"")  
	var results = regex.search_all(content)  
	  
	for result in results:  
		var path = result.get_string(1)  
		if not path in added_files:  
			_process_large_file(packer, path, added_files)

func _add_imported_resource(packer: PCKPacker, original_path: String, added_files: Array):  
	var import_file = original_path + ".import"  
	if not import_file in added_files:  
		if File.new().file_exists(import_file):  
			var err = packer.add_file(import_file, import_file)  
			if err == OK:  
				added_files.append(import_file)  
				print("添加.import文件: ", import_file)  
	  
	# 读取 .import 文件  
	var file = File.new()  
	if file.open(import_file, File.READ) == OK:  
		var content = file.get_as_text()  
		file.close()  
		  
		# 查找 dest_files 部分  
		var dest_start = content.find("dest_files=[ ") + 13  # 跳过 "dest_files=[ "  
		var dest_end = content.find(" ]", dest_start)  
		if dest_start != -1 and dest_end != -1:  
			# 获取目标文件列表  
			var dest_files_str = content.substr(dest_start, dest_end - dest_start)  
			# 分割多个文件路径  
			var dest_files = dest_files_str.split(",")  
			  
			# 处理每个目标文件  
			for dest_file in dest_files:  
				# 清理引号和空格  
				dest_file = dest_file.strip_edges()  
				dest_file = dest_file.trim_prefix("\"").trim_suffix("\"")  
				  
				print("处理目标文件: ", dest_file)  
				  
				# 添加实际的资源文件  
				if not dest_file in added_files and File.new().file_exists(dest_file):  
					var err = packer.add_file(dest_file, dest_file)  
					if err == OK:  
						added_files.append(dest_file)  
						print("添加处理后的资源: ", dest_file)   

class ResourceManager:
	var _resource_registry = {}
	
	func is_resource_exists(file_path: String) -> bool:
		var file_hash = _calculate_file_hash(file_path)
		return _resource_registry.has(file_hash)
	
	func register_resource(file_path: String) -> void:
		var file_hash = _calculate_file_hash(file_path)
		_resource_registry[file_hash] = file_path
	
	func _calculate_file_hash(file_path: String) -> String:
		var file = File.new()
		if file.open(file_path, File.READ) != OK:
			return ""
		
		var hashf = HashingContext.new()
		hashf.start(HashingContext.HASH_MD5)
		
		var bytes_read = 0
		while !file.eof_reached() and bytes_read < CHUNK_SIZE:
			var chunk = file.get_buffer(min(65536, CHUNK_SIZE - bytes_read))
			hashf.update(chunk)
			bytes_read += chunk.size()
		
		file.close()
		return hashf.finish().hex_encode()
