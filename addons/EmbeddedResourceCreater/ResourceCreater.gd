tool
extends Panel

var import_path;
# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("VBoxContainer/ButtonLoad").connect("pressed", self, "load_pressed")
	get_node("VBoxContainer/ButtonSave").connect("pressed", self, "save_pressed")
	get_node("SaveFileDialog").connect("file_selected", self, "save_file_selected")
	get_node("LoadFileDialog").connect("file_selected", self, "load_file_selected")
	get_node("VBoxContainer/LineEdit").connect("focus_entered", self, "change_editable");
	get_node("VBoxContainer/LineEdit").connect("focus_exited", self, "change_editable");
	pass # Replace with function body.
	current_res = load("res://assets/material/soil/soil.material")

func save_pressed():
	get_node("SaveFileDialog").popup_centered()
func load_pressed():
	get_node("LoadFileDialog").popup_centered()
	
#onready var current_res:Resource
onready var current_res
func save_file_selected(path):
	if !current_res:
		return
	if(current_res is Node):
		recursion_convert_scene(current_res)
	else:
		recursion_convert_streamtexture(current_res)
		
	var err = ResourceSaver.save(path, current_res, 
		ResourceSaver.FLAG_BUNDLE_RESOURCES 
		| ResourceSaver.FLAG_COMPRESS
	)
	print(err)
	
func load_file_selected(path):
	print(path);
	var filename;
	var extension;
	if(path.is_abs_path() || path.is_rel_path):
		filename = path.get_file().split(".")[0]
		extension = path.get_extension();
	if extension == "gif":
		var image_helper_script = load("res://addons/EmbeddedResourceCreater/ImageHelper.cs")
		var image_helper = image_helper_script.new();
		var file = File.new();
		file.open(path, File.READ);
		print(file.get_len());
		var gifstream = file.get_buffer(file.get_len());
		file.close();
		
		var tex = image_helper.ConvertGifToAnimatedTexture(gifstream);
		import_path = get_node("VBoxContainer/LineEdit").text;
		var resultPath = import_path + "/" + filename + ".res";
		print("导入结果路径：", resultPath)
		if ResourceSaver.save(resultPath, tex, ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS) == OK:
			print("保存成功");
		else:
			print("保存失败");
	else:
		var gltf:PackedSceneGLTF =  PackedSceneGLTF.new();
		gltf.pack_gltf(path);
		current_res = gltf.instance();
	#current_res = load(path) as PackedSceneGLTF
	#current_res = current_res.instance() as Spatial
	#$VBoxContainer/Label.text = path
	
func recursion_convert_streamtexture(res:Resource):
	for i in res.get_property_list():
			var prop = res.get(i.name)
			if prop is Resource:
				if prop is StreamTexture:
					print(i.name)
					var tex = prop as Texture
					var img = tex.get_data()
					var img_tex = ImageTexture.new()
					img_tex.create_from_image(img)
					res.set(i.name,img_tex)
				else:
					recursion_convert_streamtexture(prop)	

func recursion_convert_scene(res:Node):
	for scene in res.get_children():
		if scene is MeshInstance:
			for i in scene.mesh.get_surface_count():
				var mtl = scene.get_active_material(i)
				recursion_convert_streamtexture(mtl)
				scene.mesh.surface_set_material(i,mtl)

func change_editable():
	get_node("VBoxContainer/LineEdit").editable = !get_node("VBoxContainer/LineEdit").editable
		
