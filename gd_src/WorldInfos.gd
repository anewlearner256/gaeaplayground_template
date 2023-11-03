extends Label


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	var memoryuse = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0;
	var vertexuse = Performance.get_monitor(Performance.RENDER_VERTEX_MEM_USED) / 1024.0 / 1024.0;
	var textureuse = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1024.0 / 1024.0;
	#PyramidTile:{1}\nGaea3dtilesMeshs:{2}\nPyramidTileRequests:{3}\nGaea3dtileRequests:{4}\nTerrainRequests:{5}\n
	text = "FPS:{0}\nMemory:{1}MB\nVertex:{2}MB\nTexture:{3}MB\n".format(
		{
			"0":str(Engine.get_frames_per_second()),
			"1":str(memoryuse),
			"2":str(vertexuse),
			"3":str(textureuse),
#			"1":str(get_node("PyramidTileMeshs").get_child_count()),
#			"2":str(get_node("Gaea3dtilesMeshs").get_child_count()),
#			"3":str(get_node("PyramidTileRequests").get_child_count()),
#			"4":str(get_node("Gaea3dtileRequests").get_child_count()),
#			"5":str(get_node("TerrainRequests").get_child_count()),
		})
