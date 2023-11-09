class_name ThreadPool2
extends Node
# A thread pool designed to perform your tasks efficiently


export var use_signals: bool = true

var __tasks: Array = []
var __task_waits: Array = []
var read := 0
var write := 0

var max_len = OS.get_processor_count()
#var max_len:= 1
var __started = false
var __finished = false
var __tasks_lock: Mutex = Mutex.new()
var __tasks_wait_lock: Mutex = Mutex.new()
#var __tasks_wait: Semaphore = Semaphore.new()
var __pool
onready var lst:ItemList
func _ready():
#	if OS.has_feature("web"):
#		max_len = 8
#	else:
#		max_len = OS.get_processor_count()
	__pool = __create_pool()
	
	for c in range(max_len):
		var result = Future.new(self, "do_nothing", null, c, true, false, self)
		__tasks.push_back(result)
		__task_waits.push_back(Semaphore.new())
	__start()

func do_nothing() :
	pass
func _do_json_parser(json: String) ->JSONParseResult:
	return JSON.parse(json)
# 材质加载
func _do_texture_worker(path:String,buffer:PoolByteArray):
	var err
	var img = Image.new()
	var ext = path.get_extension().to_lower()
	match ext:
		"jpg":
			err = img.load_jpg_from_buffer(buffer)
		"jpeg":
			err = img.load_jpg_from_buffer(buffer)
		"png":
			err = img.load_png_from_buffer(buffer)
		"bmp":
			err = img.load_bmp_from_buffer(buffer)
		"tga":
			err = img.load_tga_from_buffer(buffer)
		"webp":
			err = img.load_webp_from_buffer(buffer)
		_:
			return null	
	if err != OK || !is_instance_valid(img):
		return null
	else:
		if OS.has_feature("web"):
			if img.get_format() == img.FORMAT_RGB8 ||img.get_format() == img.FORMAT_RGBA8:
				img.srgb_to_linear()
#		var texture = ImageTexture.new()
#		texture.create_from_image(img, Texture.FLAG_FILTER)
		var tex = VisualServer.texture_create_from_image(img,Texture.FLAG_FILTER)
		return tex

# 读取Gltf模型任务
func _do_gltf_worker(buffer:PoolByteArray,uselight:bool):
	var _doc = GLTFDocument.new()
	var _state = GLTFState.new()
	_state.use_in_3dtile = true
	_state.use_light = uselight
	var err = _doc.append_from_buffer(buffer, "", _state, 0)
	if err != OK:
		return null
	return _state

# 读取文件任务
func _do_io_read(path:String):
	var f = File.new()
	var err =  f.open(path,File.READ)
	if err != OK:
		f.close()
		return null
	var result = f.get_buffer(f.get_len())
	f.close()
	return result
	
# 写入文件任务
func _do_io_write(path:String,buffer:PoolByteArray):
	var f = File.new()
	var err =  f.open(path,File.WRITE)
	if err != OK:
		f.close()
		return false
	f.store_buffer(buffer)
	f.close()
	return true

func get_worker():
	var current = get_free_woker(1)
	return current
	
func start(method: String, parameter = null):
	var current = get_free_woker()
	if current != null:
		current.target_instance = self
		current.target_method = method
		current.finished = false
		current.completed = false
		current.cancelled = false
		current.result = null
		current.target_argument = parameter 
		current.__no_argument = false
		current.__array_argument = true
		current.__read_write_flag = 1
#		print(current.tag,"开始",current.__read_write_flag)
		#__tasks_wait_lock.lock()
		__task_waits[current.tag].post()
		#__tasks_wait_lock.unlock()
		return current
		
	return null
	
func get_free_woker(flag = 0)->Future:
	for current in __tasks:
		var item = current
		var cflag = item.__read_write_flag
		if cflag  == flag:
			return item
	return null

func __create_pool():
	var result = []
	for c in range(max_len):
		result.append(Thread.new())
	return result
	
func __start() -> void:
	if not __started:
		var i = 0
		for t in __pool:
			(t as Thread).start(self, "__execute_tasks", i)
			i+=1
		__started = true

func __execute_tasks(arg_thread) -> void:
	while not __finished:				
		if __finished:
			return
		#print("task id:",arg_thread)
		__task_waits[arg_thread].wait()
		
		__tasks_lock.lock()
		var task: Future = __tasks[arg_thread]
		if task.__read_write_flag != 1:
			return
		__tasks_lock.unlock()
		
		if task!= null:
			__tasks_lock.lock()
			task.__read_write_flag = 2
#			print("正在运行:",task.tag,":",task.__read_write_flag)
			__tasks_lock.unlock()
			
			__execute_this_task(task)
			
func __execute_this_task(task: Future) -> void:
	if task.cancelled:
		return
		
	task.__execute_task()
	task.completed = true
	task.call_deferred("emit_signal","on_complate",task.result)
#	print("运行结束:",task.tag,":",task.__read_write_flag)

class Future:
	signal on_complate
	var __read_write_flag:int
	var target_instance: Object
	var target_method: String
	var target_argument
	var result
	var tag
	var cancelled: bool # true if was requested for this future to avoid being executed
	var completed: bool # true if this future executed completely
	var finished: bool # true if this future is considered finished and no further processing will take place
	var __no_argument: bool
	var __array_argument: bool
	var __lock: Mutex
	var __wait: Semaphore
	var __pool: ThreadPool2

	func _init(instance: Object, method: String, parameter, task_tag, no_argument: bool, array_argument: bool, pool: ThreadPool2):
		target_instance = instance
		target_method = method
		target_argument = parameter
		result = null
		tag = task_tag
		__no_argument = no_argument
		__array_argument = array_argument
		cancelled = false
		completed = false
		finished = false
		__lock = Mutex.new()
		__wait = Semaphore.new()
		__pool = pool
		__read_write_flag = 0


	func cancel() -> void:
		cancelled = true


	func wait_for_result() -> void:
		if not finished:
			__verify_task_execution()


	func get_result():
		wait_for_result()
		return result


	func __execute_task() -> void:
		if __no_argument:
			result = target_instance.call("do_nothing")
		elif __array_argument:
			result = target_instance.callv(target_method, target_argument)
		else:
			result = target_instance.call(target_method, target_argument)
		__wait.post()


	func __verify_task_execution() -> void:
		__lock.lock()
		if not finished:
			var task: Future = null
			if __pool != null:
				task = __pool.__drain_this_task(self)
			if task != null:
				__pool.__execute_this_task(task)
			else:
				__wait.wait()
		__lock.unlock()


	func _finish():
#		result = null
		finished = true
		__pool = null
		__read_write_flag = 0
#		print("释放:",tag,":",__read_write_flag)
